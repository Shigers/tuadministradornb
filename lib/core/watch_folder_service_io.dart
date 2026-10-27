import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../data/models.dart';
import 'extension_categories.dart';
import 'utils.dart';
import 'watch_folder_types.dart';

/// Tamaño máximo por archivo que se organiza (100 MB), igual que la importación.
const int _maxFileBytes = 100 * 1024 * 1024;

/// Solo se procesan archivos cuya última modificación tenga al menos este tiempo,
/// para no tocar archivos que todavía se están escribiendo (copias en curso).
const Duration _settleTime = Duration(seconds: 2);

WatchFolderController createWatchFolderController({
  required String sourceDir,
  required String destDir,
  required bool importToApp,
  AppImporter? importer,
}) {
  return _IoWatchFolderController(
    sourceDir: sourceDir,
    destDir: destDir,
    importToApp: importToApp,
    importer: importer,
  );
}

/// Organiza en una sola pasada los archivos de `sourceDir` dentro de `destDir`,
/// agrupados por categoría de extensión. Copia (nunca mueve ni borra el
/// original). Evita duplicados por SHA-256 usando `seenHashes`, que se actualiza.
///
/// Es una función independiente para poder probarla con carpetas temporales.
Future<OrganizeResult> organizeFolderOnce({
  required String sourceDir,
  required String destDir,
  required Set<String> seenHashes,
  bool respectSettleTime = true,
}) async {
  final result = OrganizeResult();
  final source = Directory(sourceDir);
  if (!await source.exists()) {
    result.errors++;
    result.messages.add('La carpeta de entrada no existe: $sourceDir');
    return result;
  }

  final dest = Directory(destDir);
  await dest.create(recursive: true);
  final destCanonical = p.canonicalize(dest.path);
  final usedNames = <String>{};
  final now = DateTime.now();

  final entities = await source
      .list(recursive: true, followLinks: false)
      .toList();

  for (final entity in entities) {
    if (entity is! File) continue;
    final path = entity.path;

    // No reorganizar lo que ya está dentro del destino (evita bucles).
    if (p.isWithin(destCanonical, p.canonicalize(path)) ||
        p.canonicalize(path) == destCanonical) {
      continue;
    }

    final name = p.basename(path);
    if (_shouldSkipName(name)) continue;

    try {
      final stat = await entity.stat();
      if (respectSettleTime &&
          now.difference(stat.modified) < _settleTime) {
        // Todavía podría estar escribiéndose: se procesará en la próxima pasada.
        continue;
      }
      if (stat.size > _maxFileBytes) {
        result.errors++;
        result.messages.add('$name: supera los 100 MB, se omite');
        continue;
      }

      final bytes = await entity.readAsBytes();
      if (bytes.isEmpty) continue;

      final hash = sha256Of(bytes);
      if (seenHashes.contains(hash)) {
        result.duplicates++;
        continue;
      }

      final category = categoryForExtension(extensionOf(name));
      final categoryDir = Directory(p.join(dest.path, category));
      await categoryDir.create(recursive: true);

      final targetPath = _uniqueFilePath(
        usedNames,
        categoryDir.path,
        name,
      );
      await entity.copy(targetPath);

      seenHashes.add(hash);
      result.organized++;
      result.importable.add(
        IncomingFile(
          name: name,
          originPath: p.relative(path, from: sourceDir).replaceAll('\\', '/'),
          filePath: targetPath,
        ),
      );
    } catch (error) {
      // Un archivo bloqueado o ilegible no detiene al resto; se reintenta luego.
      result.errors++;
      result.messages.add('$name: $error');
    }
  }

  return result;
}

bool _shouldSkipName(String name) {
  if (name.startsWith('~\$') || name.startsWith('.')) return true;
  const ignored = {'Thumbs.db', 'desktop.ini', '.DS_Store'};
  return ignored.contains(name);
}

/// Ruta destino única dentro de `dirPath`, versionando si ya existe en disco o
/// en esta pasada (`archivo.pdf`, `archivo__v2.pdf`, …).
String _uniqueFilePath(Set<String> used, String dirPath, String fileName) {
  final ext = extensionOf(fileName);
  final base = ext.isEmpty
      ? fileName
      : fileName.substring(0, fileName.length - ext.length - 1);
  var candidate = fileName;
  var version = 2;
  while (used.contains(p.join(dirPath, candidate).toLowerCase()) ||
      File(p.join(dirPath, candidate)).existsSync()) {
    candidate = ext.isEmpty ? '${base}__v$version' : '${base}__v$version.$ext';
    version++;
  }
  final full = p.join(dirPath, candidate);
  used.add(full.toLowerCase());
  return full;
}

class _IoWatchFolderController extends WatchFolderController {
  _IoWatchFolderController({
    required this.sourceDir,
    required this.destDir,
    required this.importToApp,
    this.importer,
  });

  final String sourceDir;
  final String destDir;
  final bool importToApp;
  final AppImporter? importer;

  final Set<String> _seenHashes = {};
  final List<WatchLogEntry> _log = [];

  StreamSubscription<FileSystemEvent>? _watchSub;
  Timer? _rescanTimer;
  bool _running = false;
  bool _processing = false;
  bool _pending = false;

  int _organized = 0;
  int _duplicates = 0;
  int _errors = 0;

  @override
  bool get supported => true;
  @override
  bool get running => _running;
  @override
  int get organizedCount => _organized;
  @override
  int get duplicateCount => _duplicates;
  @override
  int get errorCount => _errors;
  @override
  List<WatchLogEntry> get log => List.unmodifiable(_log.reversed);

  @override
  Future<void> start() async {
    if (_running) return;
    final source = Directory(sourceDir);
    if (!await source.exists()) {
      _addLog('La carpeta de entrada no existe.', isError: true);
      notifyListeners();
      return;
    }
    _running = true;
    _addLog('Vigilando «$sourceDir». Los archivos se organizan en «$destDir».');
    notifyListeners();

    // Semilla: no reprocesar lo que ya está en el destino.
    await _seedFromDestination();

    // Vigilancia por eventos del sistema de archivos…
    try {
      _watchSub = source
          .watch(recursive: true)
          .listen((_) => _scheduleProcess());
    } catch (_) {
      // Algunas plataformas no soportan watch recursivo: el temporizador cubre.
    }
    // …más un reescaneo periódico de respaldo (por si se pierde algún evento).
    _rescanTimer = Timer.periodic(
      const Duration(seconds: 6),
      (_) => _scheduleProcess(),
    );

    // Primera pasada con lo que ya hubiera en la carpeta.
    await _process();
  }

  @override
  Future<void> stop() async {
    _running = false;
    await _watchSub?.cancel();
    _watchSub = null;
    _rescanTimer?.cancel();
    _rescanTimer = null;
    _addLog('Vigilancia detenida.');
    notifyListeners();
  }

  Future<void> _seedFromDestination() async {
    final dest = Directory(destDir);
    if (!await dest.exists()) return;
    try {
      await for (final entity in dest.list(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        try {
          final bytes = await entity.readAsBytes();
          _seenHashes.add(sha256Of(bytes));
        } catch (_) {
          // Ignorar archivos ilegibles de la semilla.
        }
      }
    } catch (_) {
      // Si no se puede leer el destino, se empieza sin semilla.
    }
  }

  void _scheduleProcess() {
    if (!_running) return;
    if (_processing) {
      _pending = true;
      return;
    }
    _process();
  }

  Future<void> _process() async {
    if (!_running || _processing) return;
    _processing = true;
    try {
      final result = await organizeFolderOnce(
        sourceDir: sourceDir,
        destDir: destDir,
        seenHashes: _seenHashes,
      );
      _organized += result.organized;
      _duplicates += result.duplicates;
      _errors += result.errors;

      if (result.organized > 0) {
        _addLog('Organizados ${result.organized} archivo(s) por tipo.');
      }
      if (result.duplicates > 0) {
        _addLog('${result.duplicates} duplicado(s) omitido(s).');
      }
      for (final message in result.messages) {
        _addLog(message, isError: true);
      }

      if (importToApp && importer != null && result.importable.isNotEmpty) {
        try {
          await importer!(result.importable);
          _addLog('${result.importable.length} añadido(s) también a la app.');
        } catch (error) {
          _addLog('No se pudieron añadir a la app: $error', isError: true);
        }
      }
      notifyListeners();
    } finally {
      _processing = false;
      if (_pending && _running) {
        _pending = false;
        unawaited(_process());
      }
    }
  }

  void _addLog(String message, {bool isError = false}) {
    _log.add(WatchLogEntry(message, isError: isError));
    if (_log.length > 200) _log.removeAt(0);
  }

  @override
  void dispose() {
    _watchSub?.cancel();
    _rescanTimer?.cancel();
    super.dispose();
  }
}

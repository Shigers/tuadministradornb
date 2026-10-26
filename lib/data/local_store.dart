import 'dart:typed_data';

import 'package:hive_ce_flutter/hive_flutter.dart';

import 'models.dart';

/// Contrato de persistencia que usa la aplicación. Permite probar el
/// controlador con un almacén en memoria sin tocar Hive.
abstract class WorkspaceStore {
  /// Prepara el almacén. `namespace` aísla los datos por usuario: cada cuenta
  /// usa su propio espacio y no ve el de las demás en el mismo dispositivo.
  Future<void> init([String? namespace]);
  AppSettings readSettings();
  Future<void> saveSettings(AppSettings settings);
  List<DocumentRecord> readDocuments();
  Future<void> saveDocument(DocumentRecord document);
  Future<void> saveFile(String id, Uint8List bytes);
  Uint8List? readFile(String id);
  List<FolderNode> readFolders();
  Future<void> saveFolder(FolderNode folder);
  Future<void> deleteFolder(String id);
  Future<void> deleteDocumentPermanently(String id);
  int get storedBytes;
  Future<void> clearAll();

  /// Cierra el espacio abierto (p. ej. al cerrar sesión) sin borrar los datos.
  Future<void> close();
}

/// Persistencia local. En escritorio se guarda en la carpeta de datos de la
/// aplicación; en web, en IndexedDB. No requiere servidor, pero los datos se
/// guardan en cajas con el id del usuario para que cada cuenta tenga su propio
/// archivo aislado en el mismo dispositivo.
class LocalStore implements WorkspaceStore {
  static bool _hiveReady = false;

  String? _suffix;
  Box<dynamic>? _settings;
  Box<dynamic>? _documents;
  Box<dynamic>? _folders;
  Box<dynamic>? _files;

  bool get _open => _settings != null;

  @override
  Future<void> init([String? namespace]) async {
    if (!_hiveReady) {
      await Hive.initFlutter('tu_administrador_nb');
      _hiveReady = true;
    }
    final suffix = _suffixFor(namespace);
    // Ya está abierto el espacio de este usuario: no hacer nada.
    if (_open && _suffix == suffix) return;
    // Cambiar de usuario: cerrar el espacio anterior antes de abrir el nuevo.
    await close();
    _suffix = suffix;
    _settings = await Hive.openBox<dynamic>('settings$suffix');
    _documents = await Hive.openBox<dynamic>('documents$suffix');
    _folders = await Hive.openBox<dynamic>('folders$suffix');
    _files = await Hive.openBox<dynamic>('files$suffix');
  }

  /// Convierte el id de usuario en un sufijo seguro para un nombre de caja
  /// (solo letras y números). Sin usuario, usa el espacio por defecto.
  String _suffixFor(String? namespace) {
    if (namespace == null) return '';
    final clean = namespace.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    return clean.isEmpty ? '' : '_$clean';
  }

  @override
  AppSettings readSettings() {
    final raw = _settings?.get('workspace');
    if (raw is Map) return AppSettings.fromMap(raw);
    return AppSettings.empty;
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    await _settings?.put('workspace', settings.toMap());
  }

  @override
  List<DocumentRecord> readDocuments() {
    final result = <DocumentRecord>[];
    for (final value in _documents?.values ?? const []) {
      if (value is Map) {
        try {
          result.add(DocumentRecord.fromMap(value));
        } catch (_) {
          // Un registro corrupto no debe impedir abrir el archivo.
        }
      }
    }
    return result;
  }

  @override
  Future<void> saveDocument(DocumentRecord document) async {
    await _documents?.put(document.id, document.toMap());
  }

  @override
  Future<void> saveFile(String id, Uint8List bytes) async {
    await _files?.put(id, bytes);
  }

  @override
  Uint8List? readFile(String id) {
    final raw = _files?.get(id);
    if (raw is Uint8List) return raw;
    if (raw is List<int>) return Uint8List.fromList(raw);
    if (raw is List) {
      try {
        return Uint8List.fromList(raw.cast<int>());
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  List<FolderNode> readFolders() {
    final result = <FolderNode>[];
    for (final value in _folders?.values ?? const []) {
      if (value is Map) {
        try {
          result.add(FolderNode.fromMap(value));
        } catch (_) {
          // Ignorar carpetas corruptas.
        }
      }
    }
    return result;
  }

  @override
  Future<void> saveFolder(FolderNode folder) async {
    await _folders?.put(folder.id, folder.toMap());
  }

  @override
  Future<void> deleteFolder(String id) async {
    await _folders?.delete(id);
  }

  @override
  Future<void> deleteDocumentPermanently(String id) async {
    await _documents?.delete(id);
    await _files?.delete(id);
  }

  @override
  int get storedBytes {
    var total = 0;
    for (final value in _files?.values ?? const []) {
      if (value is Uint8List) total += value.length;
      if (value is List) total += value.length;
    }
    return total;
  }

  @override
  Future<void> clearAll() async {
    await _settings?.clear();
    await _documents?.clear();
    await _folders?.clear();
    await _files?.clear();
  }

  @override
  Future<void> close() async {
    await _settings?.close();
    await _documents?.close();
    await _folders?.close();
    await _files?.close();
    _settings = null;
    _documents = null;
    _folders = null;
    _files = null;
    _suffix = null;
  }
}

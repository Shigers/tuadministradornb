import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';

import '../core/classifier.dart';
import '../core/import_service.dart';
import '../core/utils.dart';
import 'local_store.dart';
import 'models.dart';

typedef UploadProgressCallback = void Function(
  int completed,
  int total,
  String currentName,
);

class AppController extends ChangeNotifier {
  AppController(this._store);

  final WorkspaceStore _store;
  final Uuid _uuid = const Uuid();

  AppSettings _settings = AppSettings.empty;
  final List<DocumentRecord> _documents = [];
  final List<FolderNode> _folders = [];
  bool _ready = false;
  String? _currentUserId;

  AppSettings get settings => _settings;
  bool get ready => _ready;
  bool get hasWorkspace => _settings.onboardingComplete;

  /// Id del usuario cuyo espacio está cargado, o `null` si no hay sesión.
  String? get currentUserId => _currentUserId;

  List<DocumentRecord> get documents {
    final list = _documents.where((doc) => !doc.deleted).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }

  List<DocumentRecord> get pendingDocuments {
    final list = documents.where((doc) => doc.isPending).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<DocumentRecord> get filedDocuments =>
      documents.where((doc) => doc.status == DocStatus.filed).toList();

  List<DocumentRecord> get recentDocuments => documents.take(6).toList();

  List<FolderNode> get folders {
    final list = [..._folders];
    list.sort((a, b) {
      final order = a.sortOrder.compareTo(b.sortOrder);
      return order != 0 ? order : a.name.compareTo(b.name);
    });
    return List.unmodifiable(list);
  }

  int get totalDocuments => documents.length;
  int get pendingCount => pendingDocuments.length;
  int get filedCount => filedDocuments.length;
  int get totalBytes => _store.storedBytes;

  FolderNode? folderById(String id) {
    for (final folder in _folders) {
      if (folder.id == id) return folder;
    }
    return null;
  }

  String folderPath(String id) => folderById(id)?.path ?? '99 Sin clasificar';

  List<FolderNode> childrenOf(String? parentId) {
    final list = _folders
        .where((folder) => folder.parentId == parentId)
        .toList();
    list.sort((a, b) {
      final order = a.sortOrder.compareTo(b.sortOrder);
      return order != 0 ? order : a.name.compareTo(b.name);
    });
    return list;
  }

  List<FolderNode> get rootFolders => childrenOf(null);

  DocumentRecord? documentById(String id) {
    for (final doc in _documents) {
      if (doc.id == id) return doc;
    }
    return null;
  }

  Uint8List? fileBytes(String id) => _store.readFile(id);

  /// Abre el espacio del usuario indicado y carga sus datos. Cada cuenta tiene
  /// su propio archivo aislado en el dispositivo.
  Future<void> loadForUser(String userId) async {
    _currentUserId = userId;
    await _store.init(userId);
    await load();
  }

  /// Cierra la sesión: vacía la memoria y cierra el espacio sin borrar los
  /// datos, que quedan disponibles para el próximo inicio de sesión.
  Future<void> endSession() async {
    await _store.close();
    _currentUserId = null;
    _documents.clear();
    _folders.clear();
    _settings = AppSettings.empty;
    _ready = false;
    notifyListeners();
  }

  Future<void> load() async {
    _settings = _store.readSettings();
    _documents
      ..clear()
      ..addAll(_store.readDocuments());
    _folders
      ..clear()
      ..addAll(_store.readFolders());
    if (_folders.isEmpty) {
      await _seedFolders();
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> completeOnboarding({
    required String companyName,
    required String ownerName,
  }) async {
    _settings = _settings.copyWith(
      companyName: companyName.trim(),
      ownerName: ownerName.trim(),
      onboardingComplete: true,
      createdAt: _settings.createdAt ?? DateTime.now(),
    );
    await _store.saveSettings(_settings);
    if (_folders.isEmpty) await _seedFolders();
    notifyListeners();
  }

  Future<void> updateSettings({
    String? companyName,
    String? ownerName,
    String? taxId,
    String? currency,
  }) async {
    _settings = _settings.copyWith(
      companyName: companyName?.trim(),
      ownerName: ownerName?.trim(),
      taxId: taxId?.trim(),
      currency: currency,
    );
    await _store.saveSettings(_settings);
    notifyListeners();
  }

  Future<UploadSummary> importFiles(
    List<IncomingFile> files, {
    UploadProgressCallback? onProgress,
  }) async {
    var added = 0;
    var duplicates = 0;
    var errors = 0;
    final messages = <String>[];
    final knownHashes = <String, String>{
      for (final doc in _documents.where((doc) => !doc.deleted))
        doc.sha256: doc.originalName,
    };

    for (var index = 0; index < files.length; index++) {
      final file = files[index];
      onProgress?.call(index, files.length, file.name);
      try {
        final bytes = await ImportService.readBytes(file);
        if (bytes.isEmpty) {
          errors++;
          messages.add('${file.name}: está vacío');
          continue;
        }
        if (bytes.length > 100 * 1024 * 1024) {
          errors++;
          messages.add('${file.name}: supera los 100 MB');
          continue;
        }

        final hash = sha256Of(bytes);
        if (knownHashes.containsKey(hash)) {
          duplicates++;
          continue;
        }

        final extension = extensionOf(file.name);
        final mime =
            lookupMimeType(file.name, headerBytes: bytes.take(16).toList()) ??
            'application/octet-stream';
        final suggestion = Classifier.suggest(
          fileName: file.name,
          mimeType: mime,
          originPath: file.originPath,
        );
        final now = DateTime.now();
        final doc = DocumentRecord(
          id: _uuid.v4(),
          originalName: file.name,
          extension: extension,
          mimeType: mime,
          sizeBytes: bytes.length,
          sha256: hash,
          originPath: file.originPath,
          folderId: suggestion.folderId,
          docType: suggestion.docType,
          status: suggestion.confidence >= 0.55
              ? DocStatus.review
              : DocStatus.pending,
          documentDate: Classifier.extractDate(file.name),
          amount: Classifier.extractAmount(file.name),
          currency: _settings.currency,
          confidence: suggestion.confidence,
          createdAt: now,
          updatedAt: now,
        );
        await _store.saveFile(doc.id, bytes);
        await _store.saveDocument(doc);
        _documents.add(doc);
        knownHashes[hash] = doc.originalName;
        added++;
      } catch (error) {
        errors++;
        messages.add('${file.name}: $error');
      }

      if (index % 5 == 0) notifyListeners();
      await Future<void>.delayed(Duration.zero);
    }

    onProgress?.call(files.length, files.length, '');
    notifyListeners();
    return UploadSummary(
      added: added,
      duplicates: duplicates,
      errors: errors,
      messages: messages,
    );
  }

  Future<void> updateDocument(DocumentRecord document) async {
    final index = _documents.indexWhere((doc) => doc.id == document.id);
    if (index < 0) return;
    _documents[index] = document.copyWith(updatedAt: DateTime.now());
    await _store.saveDocument(_documents[index]);
    notifyListeners();
  }

  Future<void> classifyDocument(
    String id, {
    required DocType docType,
    required String folderId,
    String? supplier,
    DateTime? documentDate,
    double? amount,
    bool archive = true,
  }) async {
    final doc = documentById(id);
    if (doc == null) return;
    final updated = DocumentRecord(
      id: doc.id,
      originalName: doc.originalName,
      extension: doc.extension,
      mimeType: doc.mimeType,
      sizeBytes: doc.sizeBytes,
      sha256: doc.sha256,
      originPath: doc.originPath,
      folderId: folderId,
      docType: docType,
      status: archive ? DocStatus.filed : DocStatus.review,
      supplier: (supplier ?? '').trim().isEmpty ? null : supplier!.trim(),
      documentDate: documentDate,
      amount: amount,
      currency: doc.currency,
      confidence: 1,
      notes: doc.notes,
      createdAt: doc.createdAt,
      updatedAt: DateTime.now(),
    );
    await updateDocument(updated);
  }

  Future<void> fileDocument(String id) async {
    final doc = documentById(id);
    if (doc == null) return;
    await updateDocument(doc.copyWith(status: DocStatus.filed, confidence: 1));
  }

  Future<void> deleteDocument(String id) async {
    final doc = documentById(id);
    if (doc == null) return;
    await updateDocument(doc.copyWith(deleted: true));
  }

  Future<FolderNode> addFolder({required String name, String? parentId}) async {
    final parent = parentId == null ? null : folderById(parentId);
    final id = 'folder-${DateTime.now().microsecondsSinceEpoch}';
    final folder = FolderNode(
      id: id,
      parentId: parentId,
      name: name.trim(),
      path: parent == null ? name.trim() : '${parent.path}/${name.trim()}',
      sortOrder: _nextSortOrder(parentId),
    );
    _folders.add(folder);
    await _store.saveFolder(folder);
    notifyListeners();
    return folder;
  }

  Future<void> renameFolder(String id, String newName) async {
    final folder = folderById(id);
    if (folder == null || folder.system) return;
    final parent = folder.parentId == null
        ? null
        : folderById(folder.parentId!);
    final oldPath = folder.path;
    final newPath = parent == null
        ? newName.trim()
        : '${parent.path}/${newName.trim()}';
    final renamed = folder.copyWith(name: newName.trim(), path: newPath);
    _replaceFolder(renamed);
    await _store.saveFolder(renamed);

    for (final child in _descendants(id)) {
      final updated = child.copyWith(
        path: child.path.replaceFirst(oldPath, newPath),
      );
      _replaceFolder(updated);
      await _store.saveFolder(updated);
    }
    notifyListeners();
  }

  Future<bool> deleteFolder(String id) async {
    final folder = folderById(id);
    if (folder == null || folder.system) return false;
    if (childrenOf(id).isNotEmpty) return false;
    final hasDocuments = documents.any((doc) => doc.folderId == id);
    if (hasDocuments) return false;
    _folders.removeWhere((item) => item.id == id);
    await _store.deleteFolder(id);
    notifyListeners();
    return true;
  }

  int documentCountInFolder(String id, {bool includeChildren = true}) {
    final ids = includeChildren ? _descendantIds(id) : {id};
    return documents.where((doc) => ids.contains(doc.folderId)).length;
  }

  Map<DocType, int> get countsByType {
    final result = <DocType, int>{};
    for (final doc in documents) {
      result[doc.docType] = (result[doc.docType] ?? 0) + 1;
    }
    return result;
  }

  Uint8List buildIndexCsv() {
    return buildCsvBytes(documents, {
      for (final folder in _folders) folder.id: folder,
    });
  }

  Uint8List buildZip() {
    final archive = Archive();
    final usedPaths = <String>{};
    final folderMap = {for (final folder in _folders) folder.id: folder};

    for (final doc in documents) {
      final bytes = _store.readFile(doc.id);
      if (bytes == null) continue;
      final folder = folderMap[doc.folderId];
      final directory = folder?.path ?? '99 Sin clasificar';
      final path = uniquePath(
        usedPaths,
        '$directory/${buildNormalizedName(doc)}',
      );
      archive.addFile(ArchiveFile(path, bytes.length, bytes));
    }

    final csv = buildIndexCsv();
    archive.addFile(ArchiveFile('_indice.csv', csv.length, csv));
    final encoded = ZipEncoder().encode(archive);
    return Uint8List.fromList(encoded);
  }

  String exportBaseName() {
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('-', '')
        .split('.')
        .first;
    return 'TuAdministradorNB_$stamp';
  }

  Future<void> resetAll() async {
    await _store.clearAll();
    _documents.clear();
    _folders.clear();
    _settings = AppSettings.empty;
    notifyListeners();
    await load();
  }

  Future<void> _seedFolders() async {
    const seed = <(String, String?, String, int)>[
      ('facturas', null, '01 Facturas', 1),
      ('facturas-recibidas', 'facturas', 'Recibidas', 1),
      ('facturas-emitidas', 'facturas', 'Emitidas', 2),
      ('fiscal', null, '02 Fiscal', 2),
      ('iva', 'fiscal', 'IVA', 1),
      ('modelos', 'fiscal', 'Modelos y declaraciones', 2),
      ('contabilidad', null, '03 Contabilidad', 3),
      ('laboral', null, '04 Laboral', 4),
      ('nominas', 'laboral', 'Nóminas', 1),
      ('seguros-sociales', 'laboral', 'Seguros sociales', 2),
      ('contratos-laborales', 'laboral', 'Contratos', 3),
      ('bancos', null, '05 Bancos', 5),
      ('extractos', 'bancos', 'Extractos', 1),
      ('clientes', null, '06 Clientes', 6),
      ('proveedores', null, '07 Proveedores', 7),
      ('contratos-legal', null, '08 Contratos y legal', 8),
      ('presupuestos', null, '09 Presupuestos', 9),
      ('seguros', null, '10 Seguros', 10),
      ('administracion-publica', null, '11 Administración pública', 11),
      ('correspondencia', null, '12 Correspondencia', 12),
      ('hojas-calculo', null, '13 Hojas de cálculo', 13),
      ('sin-clasificar', null, '99 Sin clasificar', 99),
    ];

    final paths = <String, String>{};
    for (final (id, parentId, name, sortOrder) in seed) {
      final parentPath = parentId == null ? null : paths[parentId];
      final path = parentPath == null ? name : '$parentPath/$name';
      paths[id] = path;
      final folder = FolderNode(
        id: id,
        parentId: parentId,
        name: name,
        path: path,
        sortOrder: sortOrder,
        system: true,
      );
      _folders.add(folder);
      await _store.saveFolder(folder);
    }
  }

  int _nextSortOrder(String? parentId) {
    final children = childrenOf(parentId);
    if (children.isEmpty) return 1;
    return children
            .map((folder) => folder.sortOrder)
            .reduce((a, b) => a > b ? a : b) +
        1;
  }

  void _replaceFolder(FolderNode folder) {
    final index = _folders.indexWhere((item) => item.id == folder.id);
    if (index >= 0) _folders[index] = folder;
  }

  Set<String> _descendantIds(String id) {
    final result = <String>{id};
    var added = true;
    while (added) {
      added = false;
      for (final folder in _folders) {
        if (folder.parentId != null &&
            result.contains(folder.parentId) &&
            !result.contains(folder.id)) {
          result.add(folder.id);
          added = true;
        }
      }
    }
    return result;
  }

  List<FolderNode> _descendants(String id) {
    final ids = _descendantIds(id)..remove(id);
    return _folders.where((folder) => ids.contains(folder.id)).toList();
  }
}

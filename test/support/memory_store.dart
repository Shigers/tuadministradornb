import 'dart:typed_data';

import 'package:tu_administrador_nb/data/local_store.dart';
import 'package:tu_administrador_nb/data/models.dart';

/// Almacén en memoria para pruebas: mismo contrato que [LocalStore] pero sin
/// Hive, sin disco y sin IndexedDB.
class MemoryStore implements WorkspaceStore {
  MemoryStore([this._settings]);

  AppSettings? _settings;
  final Map<String, DocumentRecord> _documents = {};
  final Map<String, FolderNode> _folders = {};
  final Map<String, Uint8List> _files = {};

  @override
  Future<void> init([String? namespace]) async {}

  @override
  Future<void> close() async {}

  @override
  AppSettings readSettings() => _settings ?? AppSettings.empty;

  @override
  Future<void> saveSettings(AppSettings settings) async {
    _settings = settings;
  }

  @override
  List<DocumentRecord> readDocuments() => _documents.values.toList();

  @override
  Future<void> saveDocument(DocumentRecord document) async {
    _documents[document.id] = document;
  }

  @override
  Future<void> saveFile(String id, Uint8List bytes) async {
    _files[id] = bytes;
  }

  @override
  Uint8List? readFile(String id) => _files[id];

  @override
  List<FolderNode> readFolders() => _folders.values.toList();

  @override
  Future<void> saveFolder(FolderNode folder) async {
    _folders[folder.id] = folder;
  }

  @override
  Future<void> deleteFolder(String id) async {
    _folders.remove(id);
  }

  @override
  Future<void> deleteDocumentPermanently(String id) async {
    _documents.remove(id);
    _files.remove(id);
  }

  @override
  int get storedBytes =>
      _files.values.fold(0, (total, bytes) => total + bytes.length);

  @override
  Future<void> clearAll() async {
    _settings = null;
    _documents.clear();
    _folders.clear();
    _files.clear();
  }

  /// Datos de ejemplo para las pruebas de interfaz.
  void seedDemo() {
    final now = DateTime(2026, 3, 14, 10, 30);
    _settings = AppSettings(
      companyName: 'Talleres Norte S.L.',
      ownerName: 'Lucía Ferrer',
      taxId: 'B12345678',
      onboardingComplete: true,
      createdAt: now,
    );

    _folders['facturas-recibidas'] = const FolderNode(
      id: 'facturas-recibidas',
      name: 'Facturas recibidas',
      path: '01 Facturas/Facturas recibidas',
      sortOrder: 10,
    );
    _folders['facturas-emitidas'] = const FolderNode(
      id: 'facturas-emitidas',
      name: 'Facturas emitidas',
      path: '01 Facturas/Facturas emitidas',
      sortOrder: 20,
    );
    _folders['nominas'] = const FolderNode(
      id: 'nominas',
      name: 'Nóminas',
      path: '02 Personal/Nóminas',
      sortOrder: 30,
    );
    _folders['sin-clasificar'] = const FolderNode(
      id: 'sin-clasificar',
      name: 'Sin clasificar',
      path: '99 Sin clasificar',
      sortOrder: 999,
      system: true,
    );

    final docs = [
      DocumentRecord(
        id: 'doc-1',
        originalName: 'Factura Endesa 2026-03-14.pdf',
        extension: 'pdf',
        mimeType: 'application/pdf',
        sizeBytes: 184320,
        sha256: 'hash-1',
        originPath: 'Facturas/2026/Factura Endesa 2026-03-14.pdf',
        folderId: 'facturas-recibidas',
        docType: DocType.facturaRecibida,
        status: DocStatus.filed,
        supplier: 'Endesa Energía',
        documentDate: DateTime(2026, 3, 14),
        amount: 1234.50,
        confidence: 0.92,
        createdAt: now,
        updatedAt: now,
      ),
      DocumentRecord(
        id: 'doc-2',
        originalName: 'Nomina marzo 2026.pdf',
        extension: 'pdf',
        mimeType: 'application/pdf',
        sizeBytes: 96256,
        sha256: 'hash-2',
        originPath: 'Personal/Nomina marzo 2026.pdf',
        folderId: 'nominas',
        docType: DocType.nomina,
        status: DocStatus.filed,
        supplier: 'Talleres Norte S.L.',
        documentDate: DateTime(2026, 3, 1),
        amount: 1950,
        confidence: 0.88,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      DocumentRecord(
        id: 'doc-3',
        originalName: 'gastos-varios.xlsx',
        extension: 'xlsx',
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        sizeBytes: 40960,
        sha256: 'hash-3',
        originPath: 'Contabilidad/gastos-varios.xlsx',
        folderId: 'sin-clasificar',
        docType: DocType.hojaCalculo,
        status: DocStatus.pending,
        confidence: 0.42,
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now.subtract(const Duration(hours: 5)),
      ),
    ];

    for (final doc in docs) {
      _documents[doc.id] = doc;
      _files[doc.id] = Uint8List(doc.sizeBytes);
    }
  }
}

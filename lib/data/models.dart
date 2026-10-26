import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Tipos de documento que la aplicación reconoce.
enum DocType {
  facturaRecibida(
    label: 'Factura recibida',
    slug: 'FACTURA-RECIBIDA',
    icon: Icons.receipt_long_outlined,
    defaultFolderId: 'facturas-recibidas',
  ),
  facturaEmitida(
    label: 'Factura emitida',
    slug: 'FACTURA-EMITIDA',
    icon: Icons.request_quote_outlined,
    defaultFolderId: 'facturas-emitidas',
  ),
  nomina(
    label: 'Nómina',
    slug: 'NOMINA',
    icon: Icons.badge_outlined,
    defaultFolderId: 'nominas',
  ),
  seguroSocial(
    label: 'Seguro social',
    slug: 'SEGURO-SOCIAL',
    icon: Icons.health_and_safety_outlined,
    defaultFolderId: 'seguros-sociales',
  ),
  extractoBancario(
    label: 'Extracto bancario',
    slug: 'EXTRACTO-BANCARIO',
    icon: Icons.account_balance_outlined,
    defaultFolderId: 'extractos',
  ),
  modeloFiscal(
    label: 'Modelo fiscal',
    slug: 'MODELO-FISCAL',
    icon: Icons.percent_outlined,
    defaultFolderId: 'modelos',
  ),
  contrato(
    label: 'Contrato',
    slug: 'CONTRATO',
    icon: Icons.handshake_outlined,
    defaultFolderId: 'contratos-legal',
  ),
  presupuesto(
    label: 'Presupuesto',
    slug: 'PRESUPUESTO',
    icon: Icons.calculate_outlined,
    defaultFolderId: 'presupuestos',
  ),
  albaran(
    label: 'Albarán',
    slug: 'ALBARAN',
    icon: Icons.local_shipping_outlined,
    defaultFolderId: 'proveedores',
  ),
  poliza(
    label: 'Póliza de seguro',
    slug: 'POLIZA',
    icon: Icons.shield_outlined,
    defaultFolderId: 'seguros',
  ),
  escritura(
    label: 'Escritura',
    slug: 'ESCRITURA',
    icon: Icons.gavel_outlined,
    defaultFolderId: 'contratos-legal',
  ),
  acta(
    label: 'Acta',
    slug: 'ACTA',
    icon: Icons.groups_outlined,
    defaultFolderId: 'contratos-legal',
  ),
  certificado(
    label: 'Certificado',
    slug: 'CERTIFICADO',
    icon: Icons.verified_outlined,
    defaultFolderId: 'administracion-publica',
  ),
  carta(
    label: 'Carta o comunicación',
    slug: 'CARTA',
    icon: Icons.mail_outline,
    defaultFolderId: 'correspondencia',
  ),
  hojaCalculo(
    label: 'Hoja de cálculo',
    slug: 'HOJA-CALCULO',
    icon: Icons.table_chart_outlined,
    defaultFolderId: 'hojas-calculo',
  ),
  imagen(
    label: 'Imagen',
    slug: 'IMAGEN',
    icon: Icons.image_outlined,
    defaultFolderId: 'sin-clasificar',
  ),
  xmlFacturae(
    label: 'Factura electrónica (XML)',
    slug: 'FACTURA-XML',
    icon: Icons.code_outlined,
    defaultFolderId: 'facturas-recibidas',
  ),
  otro(
    label: 'Otro documento',
    slug: 'DOCUMENTO',
    icon: Icons.insert_drive_file_outlined,
    defaultFolderId: 'sin-clasificar',
  );

  const DocType({
    required this.label,
    required this.slug,
    required this.icon,
    required this.defaultFolderId,
  });

  final String label;
  final String slug;
  final IconData icon;
  final String defaultFolderId;

  static DocType fromName(String? name) {
    return DocType.values.firstWhere(
      (type) => type.name == name,
      orElse: () => DocType.otro,
    );
  }
}

/// Estado del documento dentro del flujo de trabajo.
enum DocStatus {
  pending('Sin clasificar'),
  review('Por revisar'),
  filed('Archivado'),
  duplicate('Duplicado');

  const DocStatus(this.label);

  final String label;

  static DocStatus fromName(String? name) {
    return DocStatus.values.firstWhere(
      (status) => status.name == name,
      orElse: () => DocStatus.pending,
    );
  }
}

/// Carpeta lógica del archivo. La ruta ya viene calculada para poder mostrarla
/// y exportarla sin recorrer el árbol.
class FolderNode {
  const FolderNode({
    required this.id,
    required this.name,
    required this.path,
    this.parentId,
    this.sortOrder = 0,
    this.system = false,
  });

  final String id;
  final String? parentId;
  final String name;
  final String path;
  final int sortOrder;
  final bool system;

  FolderNode copyWith({String? name, String? path, int? sortOrder}) {
    return FolderNode(
      id: id,
      parentId: parentId,
      name: name ?? this.name,
      path: path ?? this.path,
      sortOrder: sortOrder ?? this.sortOrder,
      system: system,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'parentId': parentId,
    'name': name,
    'path': path,
    'sortOrder': sortOrder,
    'system': system,
  };

  factory FolderNode.fromMap(Map<dynamic, dynamic> map) {
    return FolderNode(
      id: map['id'] as String,
      parentId: map['parentId'] as String?,
      name: map['name'] as String,
      path: map['path'] as String,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      system: map['system'] as bool? ?? false,
    );
  }
}

/// Documento indexado. Los bytes se guardan aparte para que el listado sea
/// ligero.
class DocumentRecord {
  const DocumentRecord({
    required this.id,
    required this.originalName,
    required this.extension,
    required this.mimeType,
    required this.sizeBytes,
    required this.sha256,
    required this.originPath,
    required this.folderId,
    required this.docType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.supplier,
    this.documentDate,
    this.amount,
    this.currency = 'EUR',
    this.confidence,
    this.notes,
    this.deleted = false,
  });

  final String id;
  final String originalName;
  final String extension;
  final String mimeType;
  final int sizeBytes;
  final String sha256;
  final String originPath;
  final String folderId;
  final DocType docType;
  final DocStatus status;
  final String? supplier;
  final DateTime? documentDate;
  final double? amount;
  final String currency;
  final double? confidence;
  final String? notes;
  final bool deleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPending =>
      status == DocStatus.pending || status == DocStatus.review;

  DocumentRecord copyWith({
    String? folderId,
    DocType? docType,
    DocStatus? status,
    String? supplier,
    DateTime? documentDate,
    double? amount,
    String? currency,
    double? confidence,
    String? notes,
    bool? deleted,
    DateTime? updatedAt,
  }) {
    return DocumentRecord(
      id: id,
      originalName: originalName,
      extension: extension,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      sha256: sha256,
      originPath: originPath,
      folderId: folderId ?? this.folderId,
      docType: docType ?? this.docType,
      status: status ?? this.status,
      supplier: supplier ?? this.supplier,
      documentDate: documentDate ?? this.documentDate,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      confidence: confidence ?? this.confidence,
      notes: notes ?? this.notes,
      deleted: deleted ?? this.deleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'originalName': originalName,
    'extension': extension,
    'mimeType': mimeType,
    'sizeBytes': sizeBytes,
    'sha256': sha256,
    'originPath': originPath,
    'folderId': folderId,
    'docType': docType.name,
    'status': status.name,
    'supplier': supplier,
    'documentDate': documentDate?.toIso8601String(),
    'amount': amount,
    'currency': currency,
    'confidence': confidence,
    'notes': notes,
    'deleted': deleted,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory DocumentRecord.fromMap(Map<dynamic, dynamic> map) {
    final created = DateTime.tryParse(map['createdAt'] as String? ?? '');
    final updated = DateTime.tryParse(map['updatedAt'] as String? ?? '');
    return DocumentRecord(
      id: map['id'] as String,
      originalName: map['originalName'] as String,
      extension: map['extension'] as String? ?? '',
      mimeType: map['mimeType'] as String? ?? 'application/octet-stream',
      sizeBytes: (map['sizeBytes'] as num?)?.toInt() ?? 0,
      sha256: map['sha256'] as String? ?? '',
      originPath: map['originPath'] as String? ?? '',
      folderId: map['folderId'] as String? ?? 'sin-clasificar',
      docType: DocType.fromName(map['docType'] as String?),
      status: DocStatus.fromName(map['status'] as String?),
      supplier: map['supplier'] as String?,
      documentDate: DateTime.tryParse(map['documentDate'] as String? ?? ''),
      amount: (map['amount'] as num?)?.toDouble(),
      currency: map['currency'] as String? ?? 'EUR',
      confidence: (map['confidence'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      deleted: map['deleted'] as bool? ?? false,
      createdAt: created ?? DateTime.now(),
      updatedAt: updated ?? created ?? DateTime.now(),
    );
  }
}

/// Configuración del espacio de trabajo. En esta versión todo vive en el
/// dispositivo; el modo nube llegará como evolución del proyecto.
class AppSettings {
  const AppSettings({
    required this.companyName,
    required this.ownerName,
    required this.onboardingComplete,
    this.taxId = '',
    this.currency = 'EUR',
    this.createdAt,
  });

  final String companyName;
  final String ownerName;
  final String taxId;
  final String currency;
  final bool onboardingComplete;
  final DateTime? createdAt;

  static const empty = AppSettings(
    companyName: '',
    ownerName: '',
    onboardingComplete: false,
  );

  AppSettings copyWith({
    String? companyName,
    String? ownerName,
    String? taxId,
    String? currency,
    bool? onboardingComplete,
    DateTime? createdAt,
  }) {
    return AppSettings(
      companyName: companyName ?? this.companyName,
      ownerName: ownerName ?? this.ownerName,
      taxId: taxId ?? this.taxId,
      currency: currency ?? this.currency,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
    'companyName': companyName,
    'ownerName': ownerName,
    'taxId': taxId,
    'currency': currency,
    'onboardingComplete': onboardingComplete,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory AppSettings.fromMap(Map<dynamic, dynamic> map) {
    return AppSettings(
      companyName: map['companyName'] as String? ?? '',
      ownerName: map['ownerName'] as String? ?? '',
      taxId: map['taxId'] as String? ?? '',
      currency: map['currency'] as String? ?? 'EUR',
      onboardingComplete: map['onboardingComplete'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? ''),
    );
  }
}

/// Archivo listo para entrar en la bandeja. En web el contenido llega en
/// memoria; en escritorio se guarda la ruta y se lee de una en una para no
/// cargar miles de archivos a la vez.
class IncomingFile {
  const IncomingFile({
    required this.name,
    required this.originPath,
    this.bytes,
    this.filePath,
  });

  final String name;
  final String originPath;
  final Uint8List? bytes;
  final String? filePath;
}

class UploadSummary {
  const UploadSummary({
    required this.added,
    required this.duplicates,
    required this.errors,
    this.messages = const [],
  });

  final int added;
  final int duplicates;
  final int errors;
  final List<String> messages;

  int get total => added + duplicates + errors;

  String get message {
    final parts = <String>[];
    if (added > 0) {
      parts.add(
        '$added archivo${added == 1 ? '' : 's'} añadido${added == 1 ? '' : 's'}',
      );
    }
    if (duplicates > 0) {
      parts.add('$duplicates duplicado${duplicates == 1 ? '' : 's'}');
    }
    if (errors > 0) parts.add('$errors con error');
    return parts.isEmpty ? 'No se añadió ningún archivo' : parts.join(' · ');
  }
}

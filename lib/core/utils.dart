import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

import '../data/models.dart';

String sha256Of(Uint8List bytes) => sha256.convert(bytes).toString();

String humanBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB', 'TB'];
  var value = bytes / 1024;
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final decimals = value >= 100 ? 0 : (value >= 10 ? 1 : 2);
  return '${value.toStringAsFixed(decimals)} ${units[unit]}';
}

String formatMoney(double? amount, {String currency = 'EUR'}) {
  if (amount == null) return '—';
  final symbol = switch (currency) {
    'EUR' => '€',
    'USD' => '\$',
    'GBP' => '£',
    'MXN' => 'MX\$',
    _ => currency,
  };
  final number = NumberFormat('#,##0.00', 'es').format(amount);
  return '$number $symbol';
}

String formatDate(DateTime? date) {
  if (date == null) return 'Sin fecha';
  return DateFormat('dd/MM/yyyy').format(date);
}

String formatDateTime(DateTime? date) {
  if (date == null) return '—';
  return DateFormat('dd/MM/yyyy HH:mm').format(date);
}

String fileNameDate(DateTime? date) {
  if (date == null) return 'SIN-FECHA';
  return DateFormat('yyyy-MM-dd').format(date);
}

String stripAccents(String input) {
  const replacements = {
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    'â': 'a',
    'ã': 'a',
    'é': 'e',
    'è': 'e',
    'ë': 'e',
    'ê': 'e',
    'í': 'i',
    'ì': 'i',
    'ï': 'i',
    'î': 'i',
    'ó': 'o',
    'ò': 'o',
    'ö': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'û': 'u',
    'ñ': 'n',
    'ç': 'c',
  };
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final char = String.fromCharCode(rune).toLowerCase();
    buffer.write(replacements[char] ?? char);
  }
  return buffer.toString();
}

/// Convierte un texto libre en un segmento seguro para nombres de archivo y
/// rutas de carpetas.
String sanitizeSegment(String input, {bool upper = false}) {
  var value = stripAccents(input.trim());
  value = value.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  value = value.replaceAll(RegExp(r'-{2,}'), '-');
  value = value.replaceAll(RegExp(r'^-+|-+$'), '');
  if (value.isEmpty) value = 'SIN-DATO';
  if (value.length > 60) value = value.substring(0, 60);
  return upper ? value.toUpperCase() : value;
}

String extensionOf(String name) {
  final index = name.lastIndexOf('.');
  if (index <= 0 || index == name.length - 1) return '';
  return name.substring(index + 1).toLowerCase();
}

String baseNameOf(String name) {
  final normalized = name.replaceAll('\\', '/');
  final last = normalized.split('/').last;
  final index = last.lastIndexOf('.');
  if (index <= 0) return last;
  return last.substring(0, index);
}

/// Nombre final del documento dentro del archivo:
/// AAAA-MM-DD__TIPO__PROVEEDOR__IMPORTE.ext
String buildNormalizedName(DocumentRecord doc) {
  final parts = <String>[
    fileNameDate(doc.documentDate),
    doc.docType.slug,
    sanitizeSegment(doc.supplier ?? 'sin-proveedor', upper: true),
  ];
  if (doc.amount != null) {
    final amount = doc.amount!.toStringAsFixed(2).replaceAll('.', ',');
    parts.add('$amount${doc.currency}');
  }
  var base = parts.join('__');
  if (base.length > 150) base = base.substring(0, 150);
  final extension = doc.extension.isEmpty
      ? ''
      : '.${doc.extension.toLowerCase()}';
  return '$base$extension';
}

/// Evita dos archivos con el mismo nombre dentro del ZIP exportado.
String uniquePath(Set<String> used, String path) {
  if (!used.contains(path)) {
    used.add(path);
    return path;
  }
  final dot = path.lastIndexOf('.');
  final slash = path.lastIndexOf('/');
  final insertAt = dot > slash ? dot : path.length;
  final base = path.substring(0, insertAt);
  final extension = path.substring(insertAt);
  var copy = 2;
  while (true) {
    final candidate = '${base}__v$copy$extension';
    if (!used.contains(candidate)) {
      used.add(candidate);
      return candidate;
    }
    copy++;
  }
}

String csvEscape(String? value) {
  final text = value ?? '';
  if (text.contains(';') || text.contains('"') || text.contains('\n')) {
    return '"${text.replaceAll('"', '""')}"';
  }
  return text;
}

/// CSV con BOM y separador de punto y coma, que es lo que abre bien Excel en
/// español.
Uint8List buildCsvBytes(
  List<DocumentRecord> documents,
  Map<String, FolderNode> folders,
) {
  final buffer = StringBuffer('\uFEFF');
  buffer.writeln(
    'Archivo normalizado;Carpeta;Tipo;Proveedor;Fecha documento;Importe;Moneda;Estado;Nombre original;Ruta de origen;SHA-256',
  );
  for (final doc in documents) {
    final folder = folders[doc.folderId]?.path ?? '99 Sin clasificar';
    buffer.writeln(
      [
        csvEscape(buildNormalizedName(doc)),
        csvEscape(folder),
        csvEscape(doc.docType.label),
        csvEscape(doc.supplier ?? ''),
        csvEscape(
          doc.documentDate == null ? '' : fileNameDate(doc.documentDate),
        ),
        csvEscape(doc.amount?.toStringAsFixed(2) ?? ''),
        csvEscape(doc.currency),
        csvEscape(doc.status.label),
        csvEscape(doc.originalName),
        csvEscape(doc.originPath),
        csvEscape(doc.sha256),
      ].join(';'),
    );
  }
  return Uint8List.fromList(utf8.encode(buffer.toString()));
}

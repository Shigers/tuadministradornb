import '../data/models.dart';
import 'utils.dart';

class ClassificationSuggestion {
  const ClassificationSuggestion({
    required this.docType,
    required this.folderId,
    required this.confidence,
    required this.reason,
  });

  final DocType docType;
  final String folderId;
  final double confidence;
  final String reason;
}

/// Clasificador determinista y explicable. No usa IA: mira el nombre, la
/// extensión y la carpeta de origen. La IA llegará después, solo para los casos
/// que aquí no alcanzan confianza suficiente.
class Classifier {
  static ClassificationSuggestion suggest({
    required String fileName,
    required String mimeType,
    String originPath = '',
  }) {
    final name = stripAccents(fileName.toLowerCase());
    final origin = stripAccents(originPath.toLowerCase());
    final extension = extensionOf(fileName);

    ClassificationSuggestion make(
      DocType type,
      double confidence,
      String reason,
    ) {
      return ClassificationSuggestion(
        docType: type,
        folderId: type.defaultFolderId,
        confidence: confidence,
        reason: reason,
      );
    }

    if (extension == 'xml' ||
        name.contains('facturae') ||
        name.contains('factura electronica')) {
      return make(
        DocType.xmlFacturae,
        0.95,
        'El archivo es una factura electrónica XML',
      );
    }
    if (_any(name, ['factura emitida', 'factura-emitida', 'nuestra factura'])) {
      return make(
        DocType.facturaEmitida,
        0.94,
        'El nombre indica una factura emitida',
      );
    }
    if (_any(name, ['nomina', 'nomimas', 'salario', 'recibo de salarios'])) {
      return make(DocType.nomina, 0.94, 'El nombre contiene «nómina»');
    }
    if (_any(name, [
      'tc2',
      'seguro social',
      'seguros sociales',
      'cotizacion',
    ])) {
      return make(
        DocType.seguroSocial,
        0.92,
        'El nombre apunta a seguros sociales',
      );
    }
    if (_any(name, ['extracto', 'movimientos bancarios', 'cuenta corriente'])) {
      return make(
        DocType.extractoBancario,
        0.92,
        'El nombre contiene «extracto»',
      );
    }
    if (_any(name, [
      'modelo 303',
      'modelo 130',
      'modelo 111',
      'modelo 115',
      'modelo 347',
      'autoliquidacion',
    ])) {
      return make(
        DocType.modeloFiscal,
        0.92,
        'El nombre menciona un modelo fiscal',
      );
    }
    if (_any(name, ['poliza', 'seguro', 'recibo de seguro'])) {
      return make(
        DocType.poliza,
        0.9,
        'El nombre contiene «póliza» o «seguro»',
      );
    }
    if (_any(name, ['contrato', 'convenio'])) {
      return make(DocType.contrato, 0.9, 'El nombre contiene «contrato»');
    }
    if (_any(name, [
      'presupuesto',
      'oferta economica',
      'cotizacion comercial',
    ])) {
      return make(DocType.presupuesto, 0.9, 'El nombre contiene «presupuesto»');
    }
    if (_any(name, ['albaran', 'albaranes', 'nota de entrega'])) {
      return make(DocType.albaran, 0.9, 'El nombre contiene «albarán»');
    }
    if (_any(name, ['escritura', 'testimonio notarial'])) {
      return make(DocType.escritura, 0.9, 'El nombre contiene «escritura»');
    }
    if (_any(name, ['acta', 'actas'])) {
      return make(DocType.acta, 0.86, 'El nombre contiene «acta»');
    }
    if (_any(name, ['certificado', 'certificacion'])) {
      return make(
        DocType.certificado,
        0.88,
        'El nombre contiene «certificado»',
      );
    }
    if (_any(name, [
      'carta',
      'comunicacion',
      'notificacion',
      'requerimiento',
    ])) {
      return make(DocType.carta, 0.8, 'El nombre apunta a una comunicación');
    }
    if (_any(name, ['factura', 'facturas', 'invoice', 'fra ', 'recibo'])) {
      return make(DocType.facturaRecibida, 0.9, 'El nombre contiene «factura»');
    }

    if (_any(origin, ['nomina', 'nominas'])) {
      return make(DocType.nomina, 0.82, 'La carpeta de origen es de nóminas');
    }
    if (_any(origin, ['factura', 'facturas', 'recibidas'])) {
      return make(
        DocType.facturaRecibida,
        0.8,
        'La carpeta de origen es de facturas',
      );
    }
    if (_any(origin, ['extracto', 'banco', 'bancos'])) {
      return make(
        DocType.extractoBancario,
        0.8,
        'La carpeta de origen es de bancos',
      );
    }
    if (_any(origin, ['contrato', 'contratos', 'legal'])) {
      return make(
        DocType.contrato,
        0.78,
        'La carpeta de origen es de contratos',
      );
    }

    if (_any(extension, ['xls', 'xlsx', 'csv', 'ods'])) {
      return make(
        DocType.hojaCalculo,
        0.72,
        'La extensión corresponde a una hoja de cálculo',
      );
    }
    if (_any(extension, [
      'jpg',
      'jpeg',
      'png',
      'tif',
      'tiff',
      'heic',
      'webp',
    ])) {
      return make(DocType.imagen, 0.6, 'Es una imagen; conviene revisarla');
    }
    if (mimeType.startsWith('image/')) {
      return make(DocType.imagen, 0.55, 'El contenido es una imagen');
    }

    return const ClassificationSuggestion(
      docType: DocType.otro,
      folderId: 'sin-clasificar',
      confidence: 0.35,
      reason: 'No hay pistas suficientes en el nombre ni en el tipo',
    );
  }

  static bool _any(String haystack, List<String> needles) {
    for (final needle in needles) {
      if (haystack.contains(needle)) return true;
    }
    return false;
  }

  /// Intenta leer una fecha del nombre del archivo.
  static DateTime? extractDate(String fileName) {
    final name = stripAccents(fileName);

    final compact = RegExp(r'(20\d{2})[._\-/ ]?(\d{2})[._\-/ ]?(\d{2})')
        .firstMatch(name);
    if (compact != null) {
      final parsed = _safeDate(
        int.parse(compact.group(1)!),
        int.parse(compact.group(2)!),
        int.parse(compact.group(3)!),
      );
      if (parsed != null) return parsed;
    }

    final european = RegExp(r'(\d{1,2})[._\-/](\d{1,2})[._\-/](20\d{2})')
        .firstMatch(name);
    if (european != null) {
      final parsed = _safeDate(
        int.parse(european.group(3)!),
        int.parse(european.group(2)!),
        int.parse(european.group(1)!),
      );
      if (parsed != null) return parsed;
    }
    return null;
  }

  static DateTime? _safeDate(int year, int month, int day) {
    if (year < 2000 ||
        year > 2100 ||
        month < 1 ||
        month > 12 ||
        day < 1 ||
        day > 31) {
      return null;
    }
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  /// Solo acepta importes acompañados de moneda para no confundirlos con
  /// fechas o números de factura.
  static double? extractAmount(String fileName) {
    final name = stripAccents(fileName);
    final match = RegExp(r'(\d{1,3}(?:[.,]\d{3})*[.,]\d{2})\s*(?:eur|euros|€)')
        .firstMatch(name);
    if (match == null) return null;
    var raw = match.group(1)!;
    if (raw.contains(',') && raw.contains('.')) {
      raw = raw.replaceAll('.', '').replaceAll(',', '.');
    } else {
      raw = raw.replaceAll(',', '.');
    }
    return double.tryParse(raw);
  }
}

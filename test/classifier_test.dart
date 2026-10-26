import 'package:flutter_test/flutter_test.dart';
import 'package:tu_administrador_nb/core/classifier.dart';
import 'package:tu_administrador_nb/data/models.dart';

void main() {
  group('Classifier.suggest', () {
    test('detecta facturas recibidas por nombre', () {
      final result = Classifier.suggest(
        fileName: 'Factura Endesa 2026-03-14.pdf',
        mimeType: 'application/pdf',
      );
      expect(result.docType, DocType.facturaRecibida);
      expect(result.folderId, 'facturas-recibidas');
      expect(result.confidence, greaterThan(0.8));
    });

    test('distingue facturas emitidas', () {
      final result = Classifier.suggest(
        fileName: 'factura emitida cliente 45.pdf',
        mimeType: 'application/pdf',
      );
      expect(result.docType, DocType.facturaEmitida);
    });

    test('detecta nóminas', () {
      final result = Classifier.suggest(
        fileName: 'Nomina marzo 2026.pdf',
        mimeType: 'application/pdf',
      );
      expect(result.docType, DocType.nomina);
      expect(result.folderId, 'nominas');
    });

    test('detecta XML de factura electrónica', () {
      final result = Classifier.suggest(
        fileName: 'facturae_2026.xml',
        mimeType: 'application/xml',
      );
      expect(result.docType, DocType.xmlFacturae);
    });

    test('usa la extensión para hojas de cálculo', () {
      final result = Classifier.suggest(
        fileName: 'gastos.xlsx',
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      expect(result.docType, DocType.hojaCalculo);
      expect(result.folderId, 'hojas-calculo');
    });

    test('usa la carpeta de origen cuando el nombre no basta', () {
      final result = Classifier.suggest(
        fileName: 'documento.pdf',
        mimeType: 'application/pdf',
        originPath: 'Contabilidad/Nominas/2026/enero.pdf',
      );
      expect(result.docType, DocType.nomina);
      expect(result.confidence, lessThan(0.9));
    });

    test('deja en sin clasificar lo que no reconoce', () {
      final result = Classifier.suggest(
        fileName: 'archivo.pdf',
        mimeType: 'application/pdf',
      );
      expect(result.docType, DocType.otro);
      expect(result.folderId, 'sin-clasificar');
      expect(result.confidence, lessThan(0.5));
    });

    test('ignora acentos y mayúsculas', () {
      final result = Classifier.suggest(
        fileName: 'ALBARÁN proveedor.pdf',
        mimeType: 'application/pdf',
      );
      expect(result.docType, DocType.albaran);
    });
  });

  group('Classifier.extractDate', () {
    test('lee fecha compacta', () {
      expect(
        Classifier.extractDate('factura 20260314.pdf'),
        DateTime(2026, 3, 14),
      );
    });

    test('lee fecha europea', () {
      expect(
        Classifier.extractDate('nomina 3-4-2026.pdf'),
        DateTime(2026, 4, 3),
      );
    });

    test('descarta fechas imposibles', () {
      expect(Classifier.extractDate('factura 2026-02-31.pdf'), isNull);
    });

    test('sin fecha devuelve null', () {
      expect(Classifier.extractDate('factura_varias.pdf'), isNull);
    });
  });

  group('Classifier.extractAmount', () {
    test('lee importe con moneda euro', () {
      expect(Classifier.extractAmount('factura 1.234,56 EUR.pdf'), 1234.56);
    });

    test('no confunde el número de factura con un importe', () {
      expect(Classifier.extractAmount('factura 2026-0457.pdf'), isNull);
    });
  });
}

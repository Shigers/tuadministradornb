import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tu_administrador_nb/core/utils.dart';
import 'package:tu_administrador_nb/data/models.dart';

DocumentRecord _doc({
  String originalName = 'factura.pdf',
  String extension = 'pdf',
  DocType type = DocType.facturaRecibida,
  String? supplier = 'Endesa Energía',
  bool withDate = true,
  double? amount = 1234.5,
  String currency = 'EUR',
}) {
  final now = DateTime(2026, 3, 14);
  return DocumentRecord(
    id: 'id-1',
    originalName: originalName,
    extension: extension,
    mimeType: 'application/pdf',
    sizeBytes: 10,
    sha256: 'hash',
    originPath: 'Facturas/2026/factura.pdf',
    folderId: 'facturas-recibidas',
    docType: type,
    status: DocStatus.filed,
    supplier: supplier,
    documentDate: withDate ? DateTime(2026, 3, 14) : null,
    amount: amount,
    currency: currency,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('sanitizeSegment', () {
    test('quita acentos, espacios y caracteres prohibidos', () {
      expect(
        sanitizeSegment('  Endesa Energía, S.A. / Norte  '),
        'endesa-energia-s-a-norte',
      );
    });

    test('puede devolver el segmento en mayúsculas', () {
      expect(sanitizeSegment('iberdrola', upper: true), 'IBERDROLA');
    });

    test('nunca devuelve un segmento vacío', () {
      expect(sanitizeSegment('///'), 'SIN-DATO');
    });
  });

  group('extensionOf / baseNameOf', () {
    test('extrae la extensión en minúsculas', () {
      expect(extensionOf('Factura.PDF'), 'pdf');
      expect(extensionOf('carpeta/archivo.tar'), 'tar');
    });

    test('sin extensión devuelve cadena vacía', () {
      expect(extensionOf('README'), '');
      expect(extensionOf('.gitignore'), '');
    });

    test('el nombre base ignora la ruta', () {
      expect(baseNameOf('a/b/Factura 2026.pdf'), 'Factura 2026');
    });
  });

  group('buildNormalizedName', () {
    test('sigue el patrón fecha__tipo__proveedor__importe', () {
      final name = buildNormalizedName(_doc());
      expect(
        name,
        '2026-03-14__FACTURA-RECIBIDA__ENDESA-ENERGIA__1234,50EUR.pdf',
      );
    });

    test('omite el importe cuando no se conoce', () {
      final name = buildNormalizedName(_doc(amount: null));
      expect(name, '2026-03-14__FACTURA-RECIBIDA__ENDESA-ENERGIA.pdf');
    });

    test('marca los documentos sin fecha', () {
      final name = buildNormalizedName(_doc(withDate: false));
      expect(name, startsWith('SIN-FECHA__FACTURA-RECIBIDA'));
    });
  });

  group('uniquePath', () {
    test('deja pasar el primer nombre y versiona los repetidos', () {
      final used = <String>{};
      expect(
        uniquePath(used, '01 Facturas/factura.pdf'),
        '01 Facturas/factura.pdf',
      );
      expect(
        uniquePath(used, '01 Facturas/factura.pdf'),
        '01 Facturas/factura__v2.pdf',
      );
      expect(
        uniquePath(used, '01 Facturas/factura.pdf'),
        '01 Facturas/factura__v3.pdf',
      );
    });
  });

  group('humanBytes', () {
    test('formatea bytes y megabytes', () {
      expect(humanBytes(512), '512 B');
      expect(humanBytes(2048), '2.00 KB');
      expect(humanBytes(5 * 1024 * 1024), '5.00 MB');
    });
  });

  group('buildCsvBytes', () {
    test('incluye BOM, cabecera y una fila por documento', () {
      final bytes = buildCsvBytes(
        [_doc()],
        {
          'facturas-recibidas': const FolderNode(
            id: 'facturas-recibidas',
            name: 'Recibidas',
            path: '01 Facturas/Recibidas',
          ),
        },
      );
      expect(bytes.take(3).toList(), [0xEF, 0xBB, 0xBF]);
      final text = utf8.decode(bytes);
      expect(text.startsWith('Archivo normalizado;Carpeta;Tipo'), isTrue);
      expect(text, contains('01 Facturas/Recibidas'));
      expect(text, contains('Factura recibida'));
    });

    test('escapa los campos con punto y coma', () {
      final doc = DocumentRecord(
        id: 'x',
        originalName: 'factura;rara.pdf',
        extension: 'pdf',
        mimeType: 'application/pdf',
        sizeBytes: 1,
        sha256: 'h',
        originPath: '',
        folderId: 'sin-clasificar',
        docType: DocType.facturaRecibida,
        status: DocStatus.pending,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final text = String.fromCharCodes(buildCsvBytes([doc], const {}));
      expect(text, contains('"factura;rara.pdf"'));
    });
  });

  group('sha256Of', () {
    test('es estable y distingue contenidos', () {
      final a = sha256Of(Uint8List.fromList([1, 2, 3]));
      final b = sha256Of(Uint8List.fromList([1, 2, 3]));
      final c = sha256Of(Uint8List.fromList([1, 2, 4]));
      expect(a, b);
      expect(a, isNot(c));
      expect(a.length, 64);
    });
  });
}

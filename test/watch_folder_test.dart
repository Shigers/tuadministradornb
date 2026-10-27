import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:tu_administrador_nb/core/extension_categories.dart';
import 'package:tu_administrador_nb/core/watch_folder_service_io.dart';

void main() {
  group('categoryForExtension', () {
    test('agrupa por tipo conocido', () {
      expect(categoryForExtension('pdf'), 'PDF');
      expect(categoryForExtension('PDF'), 'PDF');
      expect(categoryForExtension('xlsx'), 'Hojas de cálculo');
      expect(categoryForExtension('png'), 'Imágenes');
      expect(categoryForExtension('zip'), 'Comprimidos');
    });

    test('desconocidos van a Otros y sin extensión aparte', () {
      expect(categoryForExtension('qwerty'), 'Otros');
      expect(categoryForExtension(''), 'Sin extensión');
    });
  });

  group('organizeFolderOnce', () {
    late Directory source;
    late Directory dest;

    setUp(() async {
      source = await Directory.systemTemp.createTemp('tanb_src_');
      dest = await Directory.systemTemp.createTemp('tanb_dst_');
    });

    tearDown(() async {
      if (await source.exists()) await source.delete(recursive: true);
      if (await dest.exists()) await dest.delete(recursive: true);
    });

    test('coloca cada archivo en su carpeta de tipo y detecta duplicados', () async {
      await File(p.join(source.path, 'factura.pdf')).writeAsString('pdf-A');
      await File(p.join(source.path, 'gastos.xlsx')).writeAsString('hoja-B');
      await File(p.join(source.path, 'foto.png')).writeAsString('img-C');
      // Duplicado exacto de factura.pdf, con otro nombre.
      await File(p.join(source.path, 'copia.pdf')).writeAsString('pdf-A');

      final seen = <String>{};
      final result = await organizeFolderOnce(
        sourceDir: source.path,
        destDir: dest.path,
        seenHashes: seen,
        respectSettleTime: false,
      );

      expect(result.organized, 3);
      expect(result.duplicates, 1);
      expect(result.errors, 0);
      expect(result.importable.length, 3);

      // Solo uno de los dos PDF de igual contenido se copia (el otro es duplicado).
      final pdfFiles = Directory(p.join(dest.path, 'PDF'))
          .listSync()
          .whereType<File>()
          .toList();
      expect(pdfFiles.length, 1);
      expect(pdfFiles.first.readAsStringSync(), 'pdf-A');
      expect(
        File(p.join(dest.path, 'Hojas de cálculo', 'gastos.xlsx')).existsSync(),
        isTrue,
      );
      expect(
        File(p.join(dest.path, 'Imágenes', 'foto.png')).existsSync(),
        isTrue,
      );
      // El original nunca se borra.
      expect(File(p.join(source.path, 'factura.pdf')).existsSync(), isTrue);
    });

    test('no reprocesa lo ya visto en una segunda pasada', () async {
      await File(p.join(source.path, 'a.pdf')).writeAsString('contenido');
      final seen = <String>{};

      final first = await organizeFolderOnce(
        sourceDir: source.path,
        destDir: dest.path,
        seenHashes: seen,
        respectSettleTime: false,
      );
      final second = await organizeFolderOnce(
        sourceDir: source.path,
        destDir: dest.path,
        seenHashes: seen,
        respectSettleTime: false,
      );

      expect(first.organized, 1);
      expect(second.organized, 0);
      expect(second.duplicates, 1);
    });

    test('versiona nombres repetidos de distinto contenido', () async {
      final sub = Directory(p.join(source.path, 'sub'))..createSync();
      await File(p.join(source.path, 'doc.pdf')).writeAsString('uno');
      await File(p.join(sub.path, 'doc.pdf')).writeAsString('dos');

      final result = await organizeFolderOnce(
        sourceDir: source.path,
        destDir: dest.path,
        seenHashes: <String>{},
        respectSettleTime: false,
      );

      expect(result.organized, 2);
      expect(File(p.join(dest.path, 'PDF', 'doc.pdf')).existsSync(), isTrue);
      expect(File(p.join(dest.path, 'PDF', 'doc__v2.pdf')).existsSync(), isTrue);
    });
  });
}

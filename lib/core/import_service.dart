import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../data/models.dart';
import 'folder_reader_stub.dart'
    if (dart.library.io) 'folder_reader_io.dart'
    as platform;
import 'utils.dart';

class ImportService {
  static const int maxFilesPerBatch = 1000;
  static const int maxZipEntries = 1000;
  static const int maxZipBytes = 512 * 1024 * 1024;

  static Future<Uint8List> readBytes(IncomingFile file) async {
    if (file.bytes != null) return file.bytes!;
    if (file.filePath != null) {
      final bytes = await platform.readPathBytes(file.filePath!);
      if (bytes != null) return bytes;
    }
    throw StateError('No se pudo leer el contenido de ${file.name}');
  }

  static Future<List<IncomingFile>> pickFiles() async {
    final picked = await FilePickerPlatform.instance.pickFiles(
      dialogTitle: 'Selecciona los archivos que quieres ordenar',
    );
    if (picked.isEmpty) return const [];

    final files = <IncomingFile>[];
    for (final file in picked.take(maxFilesPerBatch)) {
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) continue;
        files.add(
          IncomingFile(name: file.name, originPath: file.name, bytes: bytes),
        );
      } else {
        final path = file.path;
        if (path == null) continue;
        files.add(
          IncomingFile(name: file.name, originPath: file.name, filePath: path),
        );
      }
    }
    return files;
  }

  static Future<List<IncomingFile>> pickFolder() async {
    if (kIsWeb) return const [];
    final directory = await FilePickerPlatform.instance.getDirectoryPath(
      dialogTitle: 'Selecciona una carpeta completa',
    );
    if (directory == null) return const [];
    return platform.readFolderFiles(directory);
  }

  /// Si el usuario selecciona un ZIP, se abre y se conserva la estructura
  /// interna como ruta de origen. Si no se puede abrir, el ZIP se guarda tal
  /// cual: nunca se pierde un archivo.
  static Future<List<IncomingFile>> expandZips(List<IncomingFile> files) async {
    final result = <IncomingFile>[];
    for (final file in files) {
      if (extensionOf(file.name) != 'zip') {
        result.add(file);
        continue;
      }

      try {
        final bytes = await readBytes(file);
        final archive = ZipDecoder().decodeBytes(bytes);
        final base = baseNameOf(file.name);
        var count = 0;
        var total = 0;

        for (final entry in archive.files) {
          if (!entry.isFile) continue;
          final entryName = entry.name.replaceAll('\\', '/');
          final segments = entryName.split('/');
          if (segments.first == '__MACOSX' ||
              segments.any((segment) => segment.startsWith('.'))) {
            continue;
          }
          final data = entry.content;
          if (data.isEmpty && entry.size > 0) continue;
          if (count >= maxZipEntries || total + data.length > maxZipBytes) {
            break;
          }
          result.add(
            IncomingFile(
              name: p.basename(entryName),
              originPath: '$base/$entryName',
              bytes: data,
            ),
          );
          count++;
          total += data.length;
        }

        if (count == 0) result.add(file);
      } catch (_) {
        result.add(file);
      }
    }
    return result;
  }
}

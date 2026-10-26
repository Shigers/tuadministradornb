import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../data/models.dart';

Future<List<IncomingFile>> readFolderFiles(String rootPath) async {
  final directory = Directory(rootPath);
  final result = <IncomingFile>[];
  if (!await directory.exists()) return result;

  await for (final entity in directory.list(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is! File) continue;
    final name = p.basename(entity.path);
    if (name.startsWith('~\$') ||
        name == 'Thumbs.db' ||
        name == 'desktop.ini' ||
        name == '.DS_Store') {
      continue;
    }
    final relative = p
        .relative(entity.path, from: rootPath)
        .replaceAll('\\', '/');
    if (relative.split('/').any((segment) => segment.startsWith('.'))) {
      continue;
    }
    result.add(
      IncomingFile(name: name, originPath: relative, filePath: entity.path),
    );
    if (result.length >= 1000) break;
  }

  result.sort((a, b) => a.originPath.compareTo(b.originPath));
  return result;
}

Future<Uint8List?> readPathBytes(String path) async {
  try {
    final file = File(path);
    if (!await file.exists()) return null;
    return await file.readAsBytes();
  } catch (_) {
    return null;
  }
}

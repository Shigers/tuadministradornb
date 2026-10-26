import 'dart:typed_data';

import '../data/models.dart';

/// En web no se puede recorrer una carpeta del disco: se sube un ZIP o se
/// seleccionan los archivos uno a uno.
Future<List<IncomingFile>> readFolderFiles(String rootPath) async => const [];

Future<Uint8List?> readPathBytes(String path) async => null;

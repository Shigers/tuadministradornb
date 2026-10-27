import 'package:flutter/foundation.dart';

import '../data/models.dart';

/// Una línea del registro de actividad de la carpeta vigilada.
class WatchLogEntry {
  WatchLogEntry(this.message, {this.isError = false})
    : time = DateTime.now();

  final String message;
  final bool isError;
  final DateTime time;
}

/// Resultado de una pasada del organizador sobre la carpeta de entrada.
class OrganizeResult {
  OrganizeResult({
    this.organized = 0,
    this.duplicates = 0,
    this.errors = 0,
    List<String>? messages,
    List<IncomingFile>? importable,
  }) : messages = messages ?? [],
       importable = importable ?? [];

  int organized;
  int duplicates;
  int errors;

  /// Mensajes legibles de lo ocurrido (errores, avisos).
  final List<String> messages;

  /// Archivos ya copiados al destino, listos para importar a la app si procede.
  final List<IncomingFile> importable;
}

/// Función que importa a la app los archivos ya organizados en disco.
typedef AppImporter = Future<void> Function(List<IncomingFile> files);

/// Controlador de la carpeta vigilada. En web no está soportado (ver stub).
abstract class WatchFolderController extends ChangeNotifier {
  /// `false` en web o en plataformas sin acceso al disco.
  bool get supported;
  bool get running;

  int get organizedCount;
  int get duplicateCount;
  int get errorCount;

  List<WatchLogEntry> get log;

  Future<void> start();
  Future<void> stop();
}

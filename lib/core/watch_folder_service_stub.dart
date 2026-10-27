import 'watch_folder_types.dart';

/// En web no hay acceso al sistema de archivos del equipo: la carpeta vigilada
/// no está disponible. Se devuelve un controlador inerte marcado como no
/// soportado para que la interfaz lo oculte o lo explique.
WatchFolderController createWatchFolderController({
  required String sourceDir,
  required String destDir,
  required bool importToApp,
  AppImporter? importer,
}) {
  return _UnsupportedWatchFolderController();
}

class _UnsupportedWatchFolderController extends WatchFolderController {
  @override
  bool get supported => false;
  @override
  bool get running => false;
  @override
  int get organizedCount => 0;
  @override
  int get duplicateCount => 0;
  @override
  int get errorCount => 0;
  @override
  List<WatchLogEntry> get log => const [];

  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}
}

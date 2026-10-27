import 'watch_folder_service_stub.dart'
    if (dart.library.io) 'watch_folder_service_io.dart'
    as platform;
import 'watch_folder_types.dart';

export 'watch_folder_types.dart';

/// Crea el controlador de la carpeta vigilada adecuado a la plataforma.
/// En escritorio organiza archivos por tipo; en web no está soportado.
WatchFolderController createWatchFolderController({
  required String sourceDir,
  required String destDir,
  required bool importToApp,
  AppImporter? importer,
}) {
  return platform.createWatchFolderController(
    sourceDir: sourceDir,
    destDir: destDir,
    importToApp: importToApp,
    importer: importer,
  );
}

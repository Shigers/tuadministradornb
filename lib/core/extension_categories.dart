/// Agrupa archivos por extensión en una carpeta de categoría, para el
/// organizador de carpeta vigilada ("los pdf con los pdf").
///
/// Devuelve el nombre de la carpeta destino para una extensión dada. Las
/// extensiones desconocidas van a «Otros»: nada se descarta.
library;

const Map<String, List<String>> _categoryExtensions = {
  'PDF': ['pdf'],
  'Hojas de cálculo': ['xls', 'xlsx', 'xlsm', 'xlsb', 'csv', 'ods', 'tsv'],
  'Documentos': ['doc', 'docx', 'odt', 'rtf', 'txt', 'md', 'pages'],
  'Presentaciones': ['ppt', 'pptx', 'odp', 'key'],
  'Imágenes': [
    'jpg', 'jpeg', 'png', 'gif', 'bmp', 'tif', 'tiff', 'heic', 'heif',
    'webp', 'svg',
  ],
  'Comprimidos': ['zip', 'rar', '7z', 'tar', 'gz', 'bz2'],
  'Correo': ['eml', 'msg'],
  'Datos': ['xml', 'json', 'yml', 'yaml'],
  'Audio': ['mp3', 'wav', 'm4a', 'ogg', 'flac'],
  'Vídeo': ['mp4', 'mov', 'avi', 'mkv', 'webm'],
};

/// Carpeta de categoría para una extensión (sin punto, p. ej. `pdf`).
String categoryForExtension(String extension) {
  final ext = extension.toLowerCase();
  if (ext.isEmpty) return 'Sin extensión';
  for (final entry in _categoryExtensions.entries) {
    if (entry.value.contains(ext)) return entry.key;
  }
  return 'Otros';
}

/// Todas las categorías posibles (para ayudas de la interfaz).
List<String> get allCategories => [
  ..._categoryExtensions.keys,
  'Sin extensión',
  'Otros',
];

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/import_service.dart';
import '../core/theme.dart';
import '../data/app_controller.dart';
import '../data/models.dart';

Future<void> runUpload(
  BuildContext context,
  AppController controller, {
  bool folder = false,
}) async {
  try {
    final picked = folder
        ? await ImportService.pickFolder()
        : await ImportService.pickFiles();
    if (picked.isEmpty) return;

    final expanded = await ImportService.expandZips(picked);
    if (expanded.isEmpty) return;
    if (!context.mounted) return;

    final summary = await showDialog<UploadSummary>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          UploadDialog(controller: controller, files: expanded),
    );

    if (!context.mounted || summary == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(summary.message),
        duration: const Duration(seconds: 5),
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No se pudo iniciar la subida: $error')),
    );
  }
}

class UploadDialog extends StatefulWidget {
  const UploadDialog({
    super.key,
    required this.controller,
    required this.files,
  });

  final AppController controller;
  final List<IncomingFile> files;

  @override
  State<UploadDialog> createState() => _UploadDialogState();
}

class _UploadDialogState extends State<UploadDialog> {
  int _completed = 0;
  String _current = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final summary = await widget.controller.importFiles(
      widget.files,
      onProgress: (completed, total, current) {
        if (!mounted) return;
        setState(() {
          _completed = completed;
          _current = current;
        });
      },
    );
    if (!mounted) return;
    Navigator.of(context).pop(summary);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.files.length;
    final progress = total == 0 ? 0.0 : (_completed / total).clamp(0.0, 1.0);

    return AlertDialog(
      title: const Text('Ordenando archivos'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 9,
                backgroundColor: AppColors.surfaceAlt,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '$_completed de $total archivos',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _current.isEmpty ? 'Preparando la bandeja…' : _current,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            Text(
              'Calculando huella, detectando el tipo y proponiendo una carpeta. '
              'No cierres esta ventana.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class UploadMenuButton extends StatelessWidget {
  const UploadMenuButton({
    super.key,
    required this.controller,
    this.expanded = false,
  });

  final AppController controller;
  final bool expanded;

  Future<void> _openOptions(BuildContext context) async {
    final folder = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (context) {
        return SafeArea(
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Añadir al archivo',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Todo se procesa en este dispositivo. Nada se envía a un servidor.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    _OptionTile(
                      icon: Icons.upload_file_outlined,
                      title: 'Archivos o ZIP',
                      subtitle:
                          'Selecciona documentos sueltos o un ZIP con carpetas',
                      onTap: () => Navigator.of(context).pop(false),
                    ),
                    if (!kIsWeb) ...[
                      const SizedBox(height: 10),
                      _OptionTile(
                        icon: Icons.drive_folder_upload_outlined,
                        title: 'Carpeta completa',
                        subtitle: 'Recorre la carpeta y conserva la ruta de cada archivo',
                        onTap: () => Navigator.of(context).pop(true),
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      Text(
                        'En la versión web, comprime la carpeta en un ZIP para conservar su estructura.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (folder == null || !context.mounted) return;
    await runUpload(context, controller, folder: folder);
  }

  @override
  Widget build(BuildContext context) {
    if (expanded) {
      return FilledButton.icon(
        onPressed: () => _openOptions(context),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Añadir archivos'),
      );
    }
    return IconButton.filledTonal(
      tooltip: 'Añadir archivos',
      onPressed: () => _openOptions(context),
      icon: const Icon(Icons.add, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.navySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 21, color: AppColors.navy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

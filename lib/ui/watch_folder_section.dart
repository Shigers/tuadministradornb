import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/watch_folder_service.dart';
import '../data/app_controller.dart';
import 'widgets.dart';

/// Sección de Ajustes (solo escritorio) para activar una carpeta vigilada:
/// todo lo que se deje en ella se organiza por tipo en una carpeta destino.
class WatchFolderSection extends StatefulWidget {
  const WatchFolderSection({super.key});

  @override
  State<WatchFolderSection> createState() => _WatchFolderSectionState();
}

class _WatchFolderSectionState extends State<WatchFolderSection> {
  String? _sourceDir;
  String? _destDir;
  bool _importToApp = true;
  WatchFolderController? _controller;

  @override
  void dispose() {
    _controller?.stop();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool source}) async {
    final path = await FilePickerPlatform.instance.getDirectoryPath(
      dialogTitle: source
          ? 'Carpeta a vigilar (donde dejarás los archivos)'
          : 'Carpeta destino (donde se organizarán por tipo)',
    );
    if (path == null) return;
    setState(() {
      if (source) {
        _sourceDir = path;
      } else {
        _destDir = path;
      }
    });
  }

  Future<void> _start() async {
    final source = _sourceDir;
    final dest = _destDir;
    if (source == null || dest == null) return;
    if (source == dest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La carpeta destino debe ser distinta de la vigilada.'),
        ),
      );
      return;
    }

    final appController = context.read<AppController>();
    final controller = createWatchFolderController(
      sourceDir: source,
      destDir: dest,
      importToApp: _importToApp,
      importer: (files) async {
        await appController.importFiles(files);
      },
    );
    setState(() => _controller = controller);
    await controller.start();
  }

  Future<void> _stop() async {
    final controller = _controller;
    if (controller == null) return;
    await controller.stop();
    controller.dispose();
    setState(() => _controller = null);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final running = controller?.running ?? false;

    return SectionCard(
      title: 'Carpeta vigilada',
      subtitle: 'Deja archivos sueltos en una carpeta y se ordenan solos por tipo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const InlineNotice(
            message:
                'La app vigila una carpeta de tu PC: todo lo que dejes ahí se '
                'copia, agrupado por tipo (PDF, Hojas de cálculo, Imágenes…), en '
                'la carpeta destino. Los originales no se tocan.',
            icon: Icons.auto_awesome_motion_outlined,
          ),
          const SizedBox(height: 14),
          _FolderRow(
            label: 'Carpeta vigilada',
            value: _sourceDir,
            enabled: !running,
            onPick: () => _pick(source: true),
          ),
          const SizedBox(height: 10),
          _FolderRow(
            label: 'Carpeta destino',
            value: _destDir,
            enabled: !running,
            onPick: () => _pick(source: false),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Añadir también al archivo de la app',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Además de ordenarlos en disco, quedan buscables y en el índice.',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _importToApp,
                onChanged: running
                    ? null
                    : (v) => setState(() => _importToApp = v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (!running)
                FilledButton.icon(
                  onPressed: (_sourceDir != null && _destDir != null)
                      ? _start
                      : null,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Empezar a vigilar'),
                )
              else
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.danger,
                  ),
                  onPressed: _stop,
                  icon: const Icon(Icons.stop, size: 18),
                  label: const Text('Detener'),
                ),
              const SizedBox(width: 12),
              if (running)
                const Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Vigilando…', style: TextStyle(fontSize: 12.5)),
                  ],
                ),
            ],
          ),
          if (controller != null) ...[
            const SizedBox(height: 16),
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _Stat(label: 'Organizados', value: controller.organizedCount),
                        _Stat(label: 'Duplicados', value: controller.duplicateCount),
                        _Stat(label: 'Errores', value: controller.errorCount),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (controller.log.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 160),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            for (final entry in controller.log)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  entry.message,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: entry.isError
                                        ? AppColors.danger
                                        : AppColors.inkSoft,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _FolderRow extends StatelessWidget {
  const _FolderRow({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onPick,
  });

  final String label;
  final String? value;
  final bool enabled;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value ?? 'Sin seleccionar',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: value == null ? AppColors.muted : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton(
          onPressed: enabled ? onPick : null,
          child: const Text('Elegir'),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

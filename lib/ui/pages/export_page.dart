import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/app_controller.dart';
import '../../data/models.dart';
import '../widgets.dart';

class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  bool _busy = false;

  Future<void> _exportZip(AppController controller) async {
    setState(() => _busy = true);
    try {
      final bytes = controller.buildZip();
      await FileSaver.instance.saveFile(
        name: controller.exportBaseName(),
        bytes: bytes,
        fileExtension: 'zip',
        mimeType: MimeType.zip,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ZIP exportado · ${humanBytes(bytes.length)} · '
            '${controller.totalDocuments} documentos',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('No se pudo exportar: $error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportCsv(AppController controller) async {
    setState(() => _busy = true);
    try {
      final bytes = controller.buildIndexCsv();
      await FileSaver.instance.saveFile(
        name: '${controller.exportBaseName()}_indice',
        bytes: bytes,
        fileExtension: 'csv',
        mimeType: MimeType.csv,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Índice CSV exportado')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('No se pudo exportar: $error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final examples = controller.documents.take(3).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 40),
      children: [
        PageHeader(
          title: 'Exportar',
          subtitle:
              'Saca el archivo completo con la estructura de carpetas y un índice '
              'listo para Excel.',
          actions: [
            FilledButton.icon(
              onPressed: controller.totalDocuments == 0 || _busy
                  ? null
                  : () => _exportZip(controller),
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download_outlined, size: 18),
              label: const Text('Exportar ZIP'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const InlineNotice(
          title: 'Tus originales no se tocan',
          message:
              'El ZIP es una copia ordenada. La aplicación solo lee los archivos que '
              'le das; nunca mueve ni modifica los de tu carpeta.',
          icon: Icons.lock_outline,
          tone: NoticeTone.success,
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 880;
            final zipCard = _ExportCard(
              icon: Icons.folder_zip_outlined,
              title: 'Archivo completo (.zip)',
              description:
                  'Carpetas reales, nombres normalizados y un índice en CSV dentro '
                  'del propio ZIP.',
              detail:
                  '${controller.totalDocuments} documentos · ${humanBytes(controller.totalBytes)}',
              actionLabel: 'Descargar ZIP',
              enabled: controller.totalDocuments > 0 && !_busy,
              onAction: () => _exportZip(controller),
            );
            final csvCard = _ExportCard(
              icon: Icons.table_chart_outlined,
              title: 'Índice en CSV',
              description:
                  'Una fila por documento con tipo, proveedor, fecha, importe, estado, '
                  'ruta de origen y huella.',
              detail: 'Compatible con Excel en español',
              actionLabel: 'Descargar CSV',
              enabled: controller.totalDocuments > 0 && !_busy,
              onAction: () => _exportCsv(controller),
              accent: AppColors.blue,
            );
            if (!wide) {
              return Column(
                children: [zipCard, const SizedBox(height: 14), csvCard],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: zipCard),
                const SizedBox(width: 14),
                Expanded(child: csvCard),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 880;
            final structure = _StructurePreview(controller: controller);
            final naming = _NamingPreview(examples: examples);
            if (!wide) {
              return Column(
                children: [structure, const SizedBox(height: 22), naming],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: structure),
                const SizedBox(width: 22),
                Expanded(flex: 2, child: naming),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ExportCard extends StatelessWidget {
  const _ExportCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.detail,
    required this.actionLabel,
    required this.enabled,
    required this.onAction,
    this.accent = AppColors.navy,
  });

  final IconData icon;
  final String title;
  final String description;
  final String detail;
  final String actionLabel;
  final bool enabled;
  final VoidCallback onAction;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 22, color: accent),
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 14),
          Text(
            detail,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: enabled ? onAction : null,
            icon: const Icon(Icons.download_outlined, size: 17),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _StructurePreview extends StatelessWidget {
  const _StructurePreview({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final roots = controller.rootFolders.take(7).toList();
    return SectionCard(
      title: 'Cómo quedará el ZIP',
      subtitle: 'Las primeras carpetas del árbol',
      action: TextButton(
        onPressed: () => context.go('/folders'),
        child: const Text('Editar'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final folder in roots)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.folder_outlined,
                    size: 17,
                    color: AppColors.amber,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      folder.path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),
                  Text(
                    '${controller.documentCountInFolder(folder.id)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Text(
            'Dentro de cada carpeta se añade _indice.csv con todos los metadatos.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _NamingPreview extends StatelessWidget {
  const _NamingPreview({required this.examples});

  final List<DocumentRecord> examples;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Nombres normalizados',
      subtitle: 'Fecha · tipo · proveedor · importe',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (examples.isEmpty)
            Text(
              'Añade documentos para ver ejemplos reales.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            for (final doc in examples)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  buildNormalizedName(doc),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: AppColors.inkSoft,
                    height: 1.4,
                  ),
                ),
              ),
          const SizedBox(height: 6),
          Text(
            'El nombre original se conserva en el índice y en la ficha del documento.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

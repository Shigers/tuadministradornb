import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/app_controller.dart';
import '../../data/models.dart';
import '../dialogs.dart';
import '../upload_flow.dart';
import '../widgets.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final pending = controller.pendingDocuments;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 40),
      children: [
        PageHeader(
          title: 'Bandeja de revisión',
          subtitle: pending.isEmpty
              ? 'No queda nada pendiente. El archivo está al día.'
              : '${pending.length} documento${pending.length == 1 ? '' : 's'} esperando tu confirmación.',
          actions: [
            UploadMenuButton(controller: controller, expanded: true),
            OutlinedButton.icon(
              onPressed: () => context.go('/documents'),
              icon: const Icon(Icons.folder_open_outlined, size: 18),
              label: const Text('Ver archivo'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (pending.isEmpty)
          SectionCard(
            child: EmptyState(
              icon: Icons.task_alt,
              title: 'Todo revisado',
              message:
                  'Cada documento tiene su tipo y su carpeta. Si añades más archivos, '
                  'aparecerán aquí con una propuesta.',
              action: UploadMenuButton(controller: controller, expanded: true),
            ),
          )
        else ...[
          const InlineNotice(
            title: 'Cómo funciona la revisión',
            message:
                'La aplicación propone un tipo y una carpeta a partir del nombre, la '
                'extensión y el origen. Tú decides: «Archivar» acepta la propuesta; '
                '«Corregir» te deja cambiarla antes de guardar.',
            icon: Icons.auto_awesome_outlined,
            tone: NoticeTone.info,
          ),
          const SizedBox(height: 16),
          for (final document in pending) ...[
            _ReviewCard(controller: controller, document: document),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.controller, required this.document});

  final AppController controller;
  final DocumentRecord document;

  @override
  Widget build(BuildContext context) {
    final folder = controller.folderPath(document.folderId);
    final confidence = ((document.confidence ?? 0) * 100).round();
    final messenger = ScaffoldMessenger.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FileTypeIcon(type: document.docType, size: 46),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.originalName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${document.originPath.isEmpty ? document.originalName : document.originPath} · ${humanBytes(document.sizeBytes)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(status: document.status),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TypePill(type: document.docType, dense: true),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.subdirectory_arrow_right,
                            size: 15,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              folder,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.3,
                                color: AppColors.inkSoft,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: confidence >= 80
                            ? AppColors.accentSoft
                            : AppColors.amberSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$confidence %',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: confidence >= 80
                              ? AppColors.accentDark
                              : AppColors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _reason(document),
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(fontSize: 11.8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;
              final actions = [
                OutlinedButton.icon(
                  onPressed: () =>
                      showClassifyDialog(context, controller, document),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Corregir'),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    await controller.fileDocument(document.id);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Archivado en ${controller.folderPath(document.folderId)}',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check, size: 17),
                  label: const Text('Archivar'),
                ),
                TextButton.icon(
                  onPressed: () =>
                      showDocumentDetail(context, controller, document),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Ver'),
                ),
              ];
              if (compact) {
                return Wrap(spacing: 8, runSpacing: 8, children: actions);
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (var index = 0; index < actions.length; index++) ...[
                    if (index > 0) const SizedBox(width: 8),
                    actions[index],
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _reason(DocumentRecord document) {
    if (document.confidence == null) return 'Sin propuesta automática';
    if (document.confidence! >= 0.9) {
      return 'Propuesta con alta confianza. Puedes archivarlo tal cual.';
    }
    if (document.confidence! >= 0.7) {
      return 'Propuesta razonable, pero conviene confirmar el tipo y la carpeta.';
    }
    return 'Poca información en el nombre. Revisa el documento antes de archivarlo.';
  }
}

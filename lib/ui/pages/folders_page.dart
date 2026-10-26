import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/app_controller.dart';
import '../../data/models.dart';
import '../dialogs.dart';
import '../widgets.dart';

class FoldersPage extends StatefulWidget {
  const FoldersPage({super.key});

  @override
  State<FoldersPage> createState() => _FoldersPageState();
}

class _FoldersPageState extends State<FoldersPage> {
  final Set<String> _collapsed = {};

  Future<void> _addFolder(AppController controller, {String? parentId}) async {
    final name = await showTextInputDialog(
      context,
      title: parentId == null ? 'Nueva carpeta' : 'Nueva subcarpeta',
      subtitle: parentId == null
          ? 'Se creará en la raíz del archivo.'
          : 'Dentro de ${controller.folderPath(parentId)}',
      hint: 'Ej. Facturas 2027',
    );
    if (name == null) return;
    await controller.addFolder(name: name, parentId: parentId);
    if (!mounted) return;
    setState(() => _collapsed.remove(parentId));
  }

  Future<void> _renameFolder(
    AppController controller,
    FolderNode folder,
  ) async {
    final name = await showTextInputDialog(
      context,
      title: 'Renombrar carpeta',
      initialValue: folder.name,
      hint: folder.name,
    );
    if (name == null) return;
    await controller.renameFolder(folder.id, name);
  }

  Future<void> _deleteFolder(
    AppController controller,
    FolderNode folder,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Eliminar carpeta',
      message:
          'Solo se puede eliminar una carpeta vacía y sin subcarpetas. '
          'Los documentos no se borran nunca desde aquí.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (!confirmed) return;
    final deleted = await controller.deleteFolder(folder.id);
    if (!mounted) return;
    if (!deleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se puede eliminar: todavía contiene documentos o subcarpetas.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 40),
      children: [
        PageHeader(
          title: 'Carpetas',
          subtitle:
              'La estructura del archivo. Puedes adaptarla a tu empresa sin miedo: '
              'los archivos no se mueven del disco.',
          actions: [
            FilledButton.icon(
              onPressed: () => _addFolder(controller),
              icon: const Icon(Icons.create_new_folder_outlined, size: 18),
              label: const Text('Nueva carpeta'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const InlineNotice(
          message:
              'El ZIP exportado reproduce exactamente este árbol. Las carpetas '
              'marcadas como base no se pueden borrar, pero sí ampliar.',
          icon: Icons.account_tree_outlined,
          tone: NoticeTone.info,
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Árbol del archivo',
          subtitle:
              '${controller.folders.length} carpetas · '
              '${controller.totalDocuments} documentos',
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
          child: Column(
            children: [
              for (final folder in controller.rootFolders)
                ..._buildTree(controller, folder, 0),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildTree(
    AppController controller,
    FolderNode folder,
    int depth,
  ) {
    final children = controller.childrenOf(folder.id);
    final expanded = !_collapsed.contains(folder.id);
    final count = controller.documentCountInFolder(folder.id);
    final rows = <Widget>[
      _FolderRow(
        folder: folder,
        depth: depth,
        count: count,
        hasChildren: children.isNotEmpty,
        expanded: expanded,
        onToggle: () {
          setState(() {
            if (expanded) {
              _collapsed.add(folder.id);
            } else {
              _collapsed.remove(folder.id);
            }
          });
        },
        onOpen: () => context.go('/documents?folder=${folder.id}'),
        onAddChild: () => _addFolder(controller, parentId: folder.id),
        onRename: folder.system
            ? null
            : () => _renameFolder(controller, folder),
        onDelete: folder.system
            ? null
            : () => _deleteFolder(controller, folder),
      ),
    ];

    if (expanded) {
      for (final child in children) {
        rows.addAll(_buildTree(controller, child, depth + 1));
      }
    }
    return rows;
  }
}

class _FolderRow extends StatelessWidget {
  const _FolderRow({
    required this.folder,
    required this.depth,
    required this.count,
    required this.hasChildren,
    required this.expanded,
    required this.onToggle,
    required this.onOpen,
    required this.onAddChild,
    required this.onRename,
    required this.onDelete,
  });

  final FolderNode folder;
  final int depth;
  final int count;
  final bool hasChildren;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onOpen;
  final VoidCallback onAddChild;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.only(
            left: 8 + depth * 20.0,
            right: 4,
            top: 4,
            bottom: 4,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: hasChildren
                    ? IconButton(
                        tooltip: expanded ? 'Contraer' : 'Desplegar',
                        onPressed: onToggle,
                        icon: Icon(
                          expanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_right,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Icon(
                expanded && hasChildren
                    ? Icons.folder_open_outlined
                    : Icons.folder_outlined,
                size: 19,
                color: depth == 0 ? AppColors.amber : AppColors.inkSoft,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  folder.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.3,
                    fontWeight: depth == 0 ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
              PopupMenuButton<String>(
                tooltip: 'Acciones',
                icon: const Icon(Icons.more_horiz, size: 18),
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  switch (value) {
                    case 'open':
                      onOpen();
                    case 'child':
                      onAddChild();
                    case 'rename':
                      onRename?.call();
                    case 'delete':
                      onDelete?.call();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'open',
                    child: Text('Abrir documentos'),
                  ),
                  const PopupMenuItem(
                    value: 'child',
                    child: Text('Añadir subcarpeta'),
                  ),
                  if (onRename != null)
                    const PopupMenuItem(
                      value: 'rename',
                      child: Text('Renombrar'),
                    ),
                  if (onDelete != null)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Eliminar carpeta'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

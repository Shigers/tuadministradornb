import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/app_controller.dart';
import '../../data/models.dart';
import '../dialogs.dart';
import '../upload_flow.dart';
import '../widgets.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key, this.initialFolderId, this.initialQuery});

  final String? initialFolderId;
  final String? initialQuery;

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  late final TextEditingController _search;
  String? _folderId;
  DocType? _type;
  DocStatus? _status;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.initialQuery ?? '');
    _folderId = widget.initialFolderId;
  }

  @override
  void didUpdateWidget(covariant DocumentsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFolderId != oldWidget.initialFolderId) {
      _folderId = widget.initialFolderId;
    }
    if (widget.initialQuery != oldWidget.initialQuery &&
        widget.initialQuery != null) {
      _search.text = widget.initialQuery!;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _hasFilters =>
      _search.text.trim().isNotEmpty ||
      _folderId != null ||
      _type != null ||
      _status != null;

  void _clearFilters() {
    setState(() {
      _search.clear();
      _folderId = null;
      _type = null;
      _status = null;
    });
  }

  List<DocumentRecord> _filtered(AppController controller) {
    final query = stripAccents(_search.text.trim().toLowerCase());
    return controller.documents.where((doc) {
      if (_folderId != null && doc.folderId != _folderId) return false;
      if (_type != null && doc.docType != _type) return false;
      if (_status != null && doc.status != _status) return false;
      if (query.isEmpty) return true;
      final haystack = stripAccents(
        '${doc.originalName} ${doc.supplier ?? ''} ${doc.docType.label} '
        '${controller.folderPath(doc.folderId)} ${doc.amount ?? ''} '
        '${doc.documentDate?.toIso8601String() ?? ''} ${doc.originPath}',
      ).toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final filtered = _filtered(controller);
    final folderName = _folderId == null
        ? null
        : controller.folderPath(_folderId!);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              PageHeader(
                title: 'Documentos',
                subtitle:
                    '${filtered.length} de ${controller.totalDocuments} documentos · '
                    'todo lo que entra queda indexado.',
                actions: [
                  UploadMenuButton(controller: controller, expanded: true),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 860;
                    final search = SearchField(
                      controller: _search,
                      hint: 'Nombre, proveedor, importe…',
                      onChanged: (_) => setState(() {}),
                    );
                    final filters = [
                      SizedBox(
                        width: 178,
                        child: _FilterDropdown(
                          label: 'Estado',
                          value: _status?.name ?? 'all',
                          options: const [
                            MapEntry('all', 'Todos los estados'),
                            MapEntry('pending', 'Sin clasificar'),
                            MapEntry('review', 'Por revisar'),
                            MapEntry('filed', 'Archivados'),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _status = value == 'all'
                                  ? null
                                  : DocStatus.fromName(value);
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 196,
                        child: _FilterDropdown(
                          label: 'Tipo',
                          value: _type?.name ?? 'all',
                          options: [
                            const MapEntry('all', 'Todos los tipos'),
                            for (final type in DocType.values)
                              MapEntry(type.name, type.label),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _type = value == 'all'
                                  ? null
                                  : DocType.fromName(value);
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 230,
                        child: _FilterDropdown(
                          label: 'Carpeta',
                          value: _folderId ?? 'all',
                          options: [
                            const MapEntry('all', 'Todas las carpetas'),
                            for (final folder in controller.folders)
                              MapEntry(folder.id, folder.path),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _folderId = value == 'all' ? null : value;
                            });
                          },
                        ),
                      ),
                      if (_hasFilters)
                        TextButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(
                            Icons.filter_alt_off_outlined,
                            size: 16,
                          ),
                          label: const Text('Limpiar'),
                        ),
                    ];

                    if (!wide) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          search,
                          const SizedBox(height: 10),
                          Wrap(spacing: 10, runSpacing: 10, children: filters),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 3, child: search),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 5,
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.end,
                            children: filters,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (folderName != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.folder_outlined,
                      size: 17,
                      color: AppColors.amber,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Mostrando: $folderName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => setState(() => _folderId = null),
                      child: const Text(
                        'Ver todas',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
            ]),
          ),
        ),
        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: controller.totalDocuments == 0
                  ? Icons.upload_file_outlined
                  : Icons.search_off,
              title: controller.totalDocuments == 0
                  ? 'Todavía no hay documentos'
                  : 'Ningún documento coincide',
              message: controller.totalDocuments == 0
                  ? 'Añade archivos o una carpeta completa. Se indexarán aquí '
                        'con su tipo, fecha e importe.'
                  : 'Prueba con otra búsqueda o quita los filtros.',
              action: controller.totalDocuments == 0
                  ? UploadMenuButton(controller: controller, expanded: true)
                  : OutlinedButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.filter_alt_off_outlined, size: 17),
                      label: const Text('Quitar filtros'),
                    ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final doc = filtered[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DocumentRow(
                      document: doc,
                      folderPath: controller.folderPath(doc.folderId),
                      onTap: () => showDocumentDetail(context, controller, doc),
                      trailing: Text(
                        formatDate(doc.documentDate),
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(fontSize: 11.5),
                      ),
                    ),
                  ),
                );
              }, childCount: filtered.length),
            ),
          ),
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<MapEntry<String, String>> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.any((option) => option.key == value) ? value : 'all',
          isExpanded: true,
          isDense: true,
          style: const TextStyle(fontSize: 12.8, color: AppColors.ink),
          items: [
            for (final option in options)
              DropdownMenuItem(
                value: option.key,
                child: Text(
                  option.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
        ),
      ),
    );
  }
}

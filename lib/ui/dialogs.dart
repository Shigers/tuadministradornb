import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/utils.dart';
import '../data/app_controller.dart';
import '../data/models.dart';
import 'widgets.dart';

Future<void> showClassifyDialog(
  BuildContext context,
  AppController controller,
  DocumentRecord document,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) =>
        _ClassifyDialog(controller: controller, document: document),
  );
}

class _ClassifyDialog extends StatefulWidget {
  const _ClassifyDialog({required this.controller, required this.document});

  final AppController controller;
  final DocumentRecord document;

  @override
  State<_ClassifyDialog> createState() => _ClassifyDialogState();
}

class _ClassifyDialogState extends State<_ClassifyDialog> {
  late DocType _type;
  late String _folderId;
  late final TextEditingController _supplier;
  late final TextEditingController _amount;
  DateTime? _date;
  bool _archive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final doc = widget.document;
    _type = doc.docType;
    _folderId = doc.folderId;
    _supplier = TextEditingController(text: doc.supplier ?? '');
    _amount = TextEditingController(
      text: doc.amount == null
          ? ''
          : doc.amount!.toStringAsFixed(2).replaceAll('.', ','),
    );
    _date = doc.documentDate;
  }

  @override
  void dispose() {
    _supplier.dispose();
    _amount.dispose();
    super.dispose();
  }

  double? _parseAmount() {
    final raw = _amount.text.trim();
    if (raw.isEmpty) return null;
    var normalized = raw;
    if (raw.contains(',') && raw.contains('.')) {
      normalized = raw.replaceAll('.', '').replaceAll(',', '.');
    } else {
      normalized = raw.replaceAll(',', '.');
    }
    return double.tryParse(normalized);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: 'Fecha del documento',
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.controller.classifyDocument(
      widget.document.id,
      docType: _type,
      folderId: _folderId,
      supplier: _supplier.text,
      documentDate: _date,
      amount: _parseAmount(),
      archive: _archive,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final folders = widget.controller.folders;
    return AlertDialog(
      title: Row(
        children: [
          FileTypeIcon(type: _type, size: 38),
          const SizedBox(width: 12),
          const Expanded(child: Text('Clasificar documento')),
        ],
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.document.originalName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 18),
              _LabeledField(
                label: 'Tipo de documento',
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<DocType>(
                    value: _type,
                    isExpanded: true,
                    items: [
                      for (final type in DocType.values)
                        DropdownMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              Icon(type.icon, size: 18, color: typeColor(type)),
                              const SizedBox(width: 9),
                              Text(
                                type.label,
                                style: const TextStyle(fontSize: 13.5),
                              ),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _type = value;
                        _folderId = value.defaultFolderId;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _LabeledField(
                label: 'Carpeta',
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: folders.any((folder) => folder.id == _folderId)
                        ? _folderId
                        : 'sin-clasificar',
                    isExpanded: true,
                    menuMaxHeight: 340,
                    items: [
                      for (final folder in folders)
                        DropdownMenuItem(
                          value: folder.id,
                          child: Text(
                            folder.path,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _folderId = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _supplier,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Proveedor o cliente',
                        hintText: 'Ej. Endesa',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Importe',
                        suffixText: widget.document.currency,
                        hintText: '0,00',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha del documento',
                    suffixIcon: _date == null
                        ? const Icon(Icons.calendar_today_outlined, size: 18)
                        : IconButton(
                            tooltip: 'Quitar fecha',
                            icon: const Icon(Icons.close, size: 17),
                            onPressed: () => setState(() => _date = null),
                          ),
                  ),
                  child: Text(
                    _date == null ? 'Sin fecha' : formatDate(_date),
                    style: TextStyle(
                      fontSize: 13.5,
                      color: _date == null ? AppColors.muted : AppColors.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _archive,
                onChanged: (value) => setState(() => _archive = value),
                title: const Text(
                  'Dejar archivado',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Si lo desactivas, quedará en la bandeja para revisarlo después.',
                  style: TextStyle(fontSize: 11.5),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: child,
    );
  }
}

Future<void> showDocumentDetail(
  BuildContext context,
  AppController controller,
  DocumentRecord document,
) async {
  final bytes = controller.fileBytes(document.id);
  final folder = controller.folderPath(document.folderId);
  final messenger = ScaffoldMessenger.of(context);
  final outerContext = context;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 22, 12, 0),
        title: Row(
          children: [
            FileTypeIcon(type: document.docType, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.originalName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15.5),
                  ),
                  const SizedBox(height: 3),
                  Text(folder, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Cerrar',
              onPressed: () => Navigator.of(dialogContext).pop(),
              icon: const Icon(Icons.close, size: 20),
            ),
          ],
        ),
        content: SizedBox(
          width: 680,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (bytes != null && document.mimeType.startsWith('image/'))
                  Container(
                    height: 240,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.memory(bytes, fit: BoxFit.contain),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        FileTypeIcon(type: document.docType, size: 48),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                document.extension.isEmpty
                                    ? 'Documento'
                                    : '.${document.extension.toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Vista previa no disponible para este formato. '
                                'Puedes descargarlo y abrirlo con su aplicación.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 24,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: 190,
                      child: LabelValue(
                        label: 'Tipo',
                        value: document.docType.label,
                      ),
                    ),
                    SizedBox(
                      width: 190,
                      child: LabelValue(
                        label: 'Estado',
                        value: document.status.label,
                      ),
                    ),
                    SizedBox(
                      width: 190,
                      child: LabelValue(
                        label: 'Proveedor / cliente',
                        value: document.supplier ?? 'Sin asignar',
                      ),
                    ),
                    SizedBox(
                      width: 190,
                      child: LabelValue(
                        label: 'Fecha del documento',
                        value: formatDate(document.documentDate),
                      ),
                    ),
                    SizedBox(
                      width: 190,
                      child: LabelValue(
                        label: 'Importe',
                        value: formatMoney(
                          document.amount,
                          currency: document.currency,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 190,
                      child: LabelValue(
                        label: 'Tamaño',
                        value: humanBytes(document.sizeBytes),
                      ),
                    ),
                    SizedBox(
                      width: 190,
                      child: LabelValue(
                        label: 'Añadido',
                        value: formatDateTime(document.createdAt),
                      ),
                    ),
                    SizedBox(
                      width: 190,
                      child: LabelValue(
                        label: 'Ruta de origen',
                        value: document.originPath.isEmpty
                            ? document.originalName
                            : document.originPath,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Huella SHA-256',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                SelectableText(
                  document.sha256,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontFamily: 'monospace',
                    color: AppColors.inkSoft,
                  ),
                ),
                if (document.confidence != null) ...[
                  const SizedBox(height: 14),
                  InlineNotice(
                    message:
                        'Confianza de la propuesta: ${(document.confidence! * 100).round()} %. '
                        'Siempre puedes corregirla.',
                    icon: Icons.auto_awesome_outlined,
                    tone: document.confidence! >= 0.8
                        ? NoticeTone.success
                        : NoticeTone.warning,
                  ),
                ],
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
        actions: [
          TextButton.icon(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await showClassifyDialog(outerContext, controller, document);
            },
            icon: const Icon(Icons.edit_outlined, size: 17),
            label: const Text('Clasificar'),
          ),
          TextButton.icon(
            onPressed: () async {
              if (bytes == null) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('El archivo no está disponible'),
                  ),
                );
                return;
              }
              try {
                await downloadDocument(document, bytes);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Documento descargado')),
                );
              } catch (error) {
                messenger.showSnackBar(
                  SnackBar(content: Text('No se pudo descargar: $error')),
                );
              }
            },
            icon: const Icon(Icons.download_outlined, size: 17),
            label: const Text('Descargar'),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () async {
              final confirmed = await showConfirmDialog(
                dialogContext,
                title: 'Eliminar documento',
                message:
                    'Se quitará del archivo y se borrará su copia local. Los archivos '
                    'originales de tu carpeta no se tocan.',
                confirmLabel: 'Eliminar',
                destructive: true,
              );
              if (!confirmed) return;
              await controller.deleteDocument(document.id);
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Documento eliminado del archivo'),
                ),
              );
            },
            icon: const Icon(Icons.delete_outline, size: 17),
            label: const Text('Eliminar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      );
    },
  );
}

Future<void> downloadDocument(DocumentRecord document, Uint8List bytes) async {
  final extension = document.extension.toLowerCase();
  final normalized = buildNormalizedName(document);
  final base = extension.isEmpty
      ? normalized
      : normalized.substring(0, normalized.length - extension.length - 1);
  final mime = switch (extension) {
    'pdf' => MimeType.pdf,
    'png' => MimeType.png,
    'jpg' || 'jpeg' => MimeType.jpeg,
    'xlsx' => MimeType.microsoftExcel,
    'docx' => MimeType.microsoftWord,
    'csv' => MimeType.csv,
    'zip' => MimeType.zip,
    'xml' => MimeType.xml,
    'txt' => MimeType.text,
    _ => MimeType.other,
  };
  await FileSaver.instance.saveFile(
    name: base,
    bytes: bytes,
    fileExtension: extension,
    mimeType: mime,
  );
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(width: 420, child: Text(message)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: AppColors.danger)
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  String? subtitle,
  String? initialValue,
  String hint = '',
}) async {
  final controller = TextEditingController(text: initialValue ?? '');
  final formKey = GlobalKey<FormState>();
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 400,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (subtitle != null) ...[
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 14),
              ],
              TextFormField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  hintText: hint,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Escribe un nombre';
                  }
                  return null;
                },
                onFieldSubmitted: (_) {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(context).pop(controller.text.trim());
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.of(context).pop(controller.text.trim());
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

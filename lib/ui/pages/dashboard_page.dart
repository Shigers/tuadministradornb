import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/app_controller.dart';
import '../upload_flow.dart';
import '../widgets.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final settings = controller.settings;
    final name = settings.ownerName.trim();
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Buenos días'
        : hour < 20
        ? 'Buenas tardes'
        : 'Buenas noches';

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 40),
      children: [
        PageHeader(
          title: name.isEmpty ? greeting : '$greeting, $name',
          subtitle: 'Este es el estado del archivo de ${settings.companyName}.',
          actions: [
            UploadMenuButton(controller: controller, expanded: true),
            OutlinedButton.icon(
              onPressed: () => context.go('/export'),
              icon: const Icon(Icons.archive_outlined, size: 18),
              label: const Text('Exportar'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (controller.pendingCount > 0) ...[
          InlineNotice(
            title: controller.pendingCount == 1
                ? '1 documento espera tu criterio'
                : '${controller.pendingCount} documentos esperan tu criterio',
            message: 'La aplicación ya propuso una carpeta para cada uno. Confirma o corrige para dejarlos archivados.',
            icon: Icons.visibility_outlined,
            tone: NoticeTone.warning,
          ),
          const SizedBox(height: 18),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1000
                ? 4
                : constraints.maxWidth >= 600
                ? 2
                : 1;
            final width = (constraints.maxWidth - 14 * (columns - 1)) / columns;
            final stats = [
              StatCard(
                icon: Icons.description_outlined,
                label: 'Documentos',
                value: '${controller.totalDocuments}',
                hint: 'en el archivo',
                color: AppColors.navy,
                background: AppColors.navySoft,
              ),
              StatCard(
                icon: Icons.visibility_outlined,
                label: 'Por revisar',
                value: '${controller.pendingCount}',
                hint: controller.pendingCount == 0
                    ? 'todo al día'
                    : 'pendientes',
                color: AppColors.amber,
                background: AppColors.amberSoft,
              ),
              StatCard(
                icon: Icons.check_circle_outline,
                label: 'Archivados',
                value: '${controller.filedCount}',
                hint: 'con carpeta asignada',
                color: AppColors.accentDark,
                background: AppColors.accentSoft,
              ),
              StatCard(
                icon: Icons.storage_outlined,
                label: 'Espacio usado',
                value: humanBytes(controller.totalBytes),
                hint: 'en este dispositivo',
                color: AppColors.blue,
                background: AppColors.blueSoft,
              ),
            ];
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final stat in stats) SizedBox(width: width, child: stat),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900 ? 3 : 1;
            final width = (constraints.maxWidth - 14 * (columns - 1)) / columns;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                SizedBox(
                  width: width,
                  child: _QuickAction(
                    icon: Icons.upload_file_outlined,
                    title: 'Subir archivos',
                    subtitle: 'Documentos sueltos o un ZIP',
                    onTap: () => runUpload(context, controller),
                  ),
                ),
                if (!kIsWeb)
                  SizedBox(
                    width: width,
                    child: _QuickAction(
                      icon: Icons.drive_folder_upload_outlined,
                      title: 'Subir carpeta',
                      subtitle: 'Conserva la ruta de origen',
                      onTap: () => runUpload(context, controller, folder: true),
                    ),
                  ),
                SizedBox(
                  width: width,
                  child: _QuickAction(
                    icon: Icons.inbox_outlined,
                    title: 'Revisar bandeja',
                    subtitle: controller.pendingCount == 0
                        ? 'No hay nada pendiente'
                        : '${controller.pendingCount} por confirmar',
                    onTap: () => context.go('/inbox'),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        if (controller.totalDocuments == 0)
          _FirstSteps(controller: controller)
        else ...[
          SectionCard(
            title: 'Actividad reciente',
            subtitle: 'Los últimos documentos que entraron en el archivo',
            action: TextButton(
              onPressed: () => context.go('/documents'),
              child: const Text('Ver todos'),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < controller.recentDocuments.length;
                  index++
                ) ...[
                  DocumentRow(
                    document: controller.recentDocuments[index],
                    folderPath: controller.folderPath(
                      controller.recentDocuments[index].folderId,
                    ),
                    onTap: () => context.go('/documents'),
                  ),
                  if (index < controller.recentDocuments.length - 1)
                    const Divider(height: 1, indent: 66),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final breakdown = _TypeBreakdown(controller: controller);
              final foldersCard = _FolderSummary(controller: controller);
              if (!wide) {
                return Column(
                  children: [
                    breakdown,
                    const SizedBox(height: 22),
                    foldersCard,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: breakdown),
                  const SizedBox(width: 22),
                  Expanded(flex: 2, child: foldersCard),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
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
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
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
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
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
              const Icon(Icons.arrow_forward, size: 17, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _FirstSteps extends StatelessWidget {
  const _FirstSteps({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Empieza en tres pasos',
      subtitle: 'No hay que configurar nada más',
      child: Column(
        children: [
          _Step(
            number: '1',
            title: 'Sube tus carpetas',
            message:
                'Arrastra archivos, selecciona una carpeta completa o un ZIP. '
                'La ruta original se conserva.',
          ),
          const _Step(
            number: '2',
            title: 'Revisa lo que propone',
            message:
                'Detecta facturas, nóminas, extractos y hojas de cálculo. '
                'Tú confirmas: nada se archiva a ciegas.',
          ),
          const _Step(
            number: '3',
            title: 'Exporta el archivo',
            message:
                'Descarga un ZIP con la estructura de carpetas y un índice en CSV '
                'listo para Excel.',
            last: true,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: UploadMenuButton(controller: controller, expanded: true),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.message,
    this.last = false,
  });

  final String number;
  final String title;
  final String message;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.accentDark,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(message, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeBreakdown extends StatelessWidget {
  const _TypeBreakdown({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final counts = controller.countsByType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = counts.take(6).toList();

    return SectionCard(
      title: 'Composición del archivo',
      subtitle: 'Qué tipo de documentos tienes',
      child: Column(
        children: [
          for (final entry in top)
            MetricBar(
              label: entry.key.label,
              value: entry.value,
              total: controller.totalDocuments,
              color: typeColor(entry.key),
            ),
        ],
      ),
    );
  }
}

class _FolderSummary extends StatelessWidget {
  const _FolderSummary({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final roots = controller.rootFolders.take(5).toList();
    return SectionCard(
      title: 'Carpetas principales',
      subtitle: 'La estructura estándar, lista para usar',
      action: TextButton(
        onPressed: () => context.go('/folders'),
        child: const Text('Abrir'),
      ),
      child: Column(
        children: [
          for (final folder in roots)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.folder_outlined,
                    size: 18,
                    color: AppColors.amber,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      folder.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.8,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),
                  Text(
                    '${controller.documentCountInFolder(folder.id)}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

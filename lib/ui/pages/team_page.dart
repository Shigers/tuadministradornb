import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/app_controller.dart';
import '../widgets.dart';

class TeamPage extends StatelessWidget {
  const TeamPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final settings = controller.settings;
    final initial = settings.ownerName.trim().isEmpty
        ? 'A'
        : settings.ownerName.trim().substring(0, 1).toUpperCase();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 40),
      children: [
        const PageHeader(
          title: 'Equipo',
          subtitle:
              'Quién usa el archivo y qué podrá hacer cuando se active el modo '
              'compartido.',
        ),
        const SizedBox(height: 20),
        const InlineNotice(
          title: 'Ahora mismo: modo local',
          message:
              'Esta versión guarda todo en el dispositivo y no necesita cuentas ni '
              'servidores. El trabajo en equipo llegará con una capa gratuita en la '
              'nube; entonces los roles de esta página se activarán.',
          icon: Icons.lock_outline,
          tone: NoticeTone.info,
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 860;
            final profile = SectionCard(
              title: 'Persona propietaria',
              subtitle: 'El único perfil de este espacio local',
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: AppColors.navySoft,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          settings.ownerName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          settings.companyName,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Propietario',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentDark,
                      ),
                    ),
                  ),
                ],
              ),
            );
            final stats = SectionCard(
              title: 'Resumen del espacio',
              subtitle: 'Datos guardados en este dispositivo',
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'Documentos',
                    value: '${controller.totalDocuments}',
                  ),
                  _SummaryRow(
                    label: 'Por revisar',
                    value: '${controller.pendingCount}',
                  ),
                  _SummaryRow(
                    label: 'Carpetas',
                    value: '${controller.folders.length}',
                  ),
                  _SummaryRow(
                    label: 'Espacio',
                    value:
                        '${(controller.totalBytes / 1024 / 1024).toStringAsFixed(1)} MB',
                    last: true,
                  ),
                ],
              ),
            );
            if (!wide) {
              return Column(
                children: [profile, const SizedBox(height: 16), stats],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: profile),
                const SizedBox(width: 18),
                Expanded(flex: 2, child: stats),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        SectionCard(
          title: 'Roles previstos para el modo equipo',
          subtitle: 'Se activarán con la nube gratuita (fase 2)',
          padding: const EdgeInsets.all(10),
          child: Column(
            children: const [
              _RoleRow(
                role: 'Propietario',
                description:
                    'Todo, incluida la configuración y el borrado del espacio.',
                icon: Icons.workspace_premium_outlined,
              ),
              _RoleRow(
                role: 'Administrador',
                description: 'Miembros, taxonomía, exportaciones y ajustes.',
                icon: Icons.admin_panel_settings_outlined,
              ),
              _RoleRow(
                role: 'Gestor',
                description: 'Sube, clasifica, mueve y revisa documentos.',
                icon: Icons.edit_note_outlined,
              ),
              _RoleRow(
                role: 'Revisor',
                description: 'Valida o corrige propuestas, sin borrar nada.',
                icon: Icons.fact_check_outlined,
              ),
              _RoleRow(
                role: 'Lectura',
                description: 'Busca y descarga, sin modificar el archivo.',
                icon: Icons.visibility_outlined,
                last: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SectionCard(
          title: 'Hoja de ruta',
          subtitle: 'Lo que ya funciona y lo que viene',
          child: Column(
            children: const [
              _RoadmapRow(
                title: 'Fase 1 · Archivo local',
                description:
                    'Subida de archivos, ZIP y carpetas, clasificación asistida, '
                    'búsqueda, carpetas editables y exportación.',
                status: 'Listo',
                done: true,
              ),
              _RoadmapRow(
                title: 'Fase 2 · Equipo en la nube',
                description: 'Cuentas gratuitas, invitaciones, roles y aislamiento por empresa.',
                status: 'Siguiente',
              ),
              _RoadmapRow(
                title: 'Fase 3 · Lectura de documentos',
                description:
                    'Texto de PDF, OCR para escaneos y extracción de importes con IA '
                    'opcional.',
                status: 'Después',
              ),
              _RoadmapRow(
                title: 'Fase 4 · Informes y sincronización',
                description:
                    'IVA trimestral, gastos por proveedor, Drive/OneDrive y agente de '
                    'escritorio.',
                status: 'Más adelante',
                last: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({
    required this.role,
    required this.description,
    required this.icon,
    this.last = false,
  });

  final String role;
  final String description;
  final IconData icon;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: AppColors.inkSoft),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.lock_outline, size: 15, color: AppColors.muted),
        ],
      ),
    );
  }
}

class _RoadmapRow extends StatelessWidget {
  const _RoadmapRow({
    required this.title,
    required this.description,
    required this.status,
    this.done = false,
    this.last = false,
  });

  final String title;
  final String description;
  final String status;
  final bool done;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: done ? AppColors.accentSoft : AppColors.surfaceAlt,
              shape: BoxShape.circle,
              border: Border.all(
                color: done ? AppColors.accent : AppColors.border,
              ),
            ),
            child: Icon(
              done ? Icons.check : Icons.circle_outlined,
              size: 12,
              color: done ? AppColors.accentDark : AppColors.muted,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: done
                            ? AppColors.accentSoft
                            : AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: done ? AppColors.accentDark : AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

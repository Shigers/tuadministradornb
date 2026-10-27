import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/supabase_config.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/app_controller.dart';
import '../dialogs.dart';
import '../watch_folder_section.dart';
import '../widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _company;
  late final TextEditingController _owner;
  late final TextEditingController _taxId;
  String _currency = 'EUR';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<AppController>().settings;
    _company = TextEditingController(text: settings.companyName);
    _owner = TextEditingController(text: settings.ownerName);
    _taxId = TextEditingController(text: settings.taxId);
    _currency = settings.currency;
  }

  @override
  void dispose() {
    _company.dispose();
    _owner.dispose();
    _taxId.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_company.text.trim().length < 2 || _owner.text.trim().length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre de la empresa y el tuyo son obligatorios'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    await context.read<AppController>().updateSettings(
      companyName: _company.text,
      ownerName: _owner.text,
      taxId: _taxId.text,
      currency: _currency,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Datos guardados')));
  }

  Future<void> _logout() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Cerrar sesión',
      message:
          'Se cerrará tu sesión en este dispositivo. Tus documentos se conservan '
          'y volverán a estar disponibles cuando inicies sesión de nuevo.',
      confirmLabel: 'Cerrar sesión',
    );
    if (!confirmed || !mounted) return;
    try {
      await SupabaseConfig.client.auth.signOut();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(SupabaseConfig.friendlyErrorMessage(error))),
      );
      return;
    }
    if (mounted) context.go('/auth');
  }

  Future<void> _reset() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Borrar el archivo completo',
      message:
          'Se eliminarán los documentos, las carpetas y la configuración de este '
          'dispositivo. Esta acción no se puede deshacer. Los archivos originales de '
          'tus carpetas no se tocan.',
      confirmLabel: 'Borrar todo',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await context.read<AppController>().resetAll();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 40),
      children: [
        const PageHeader(
          title: 'Ajustes',
          subtitle: 'Datos de la empresa, almacenamiento y control total sobre lo que se guarda.',
        ),
        const SizedBox(height: 20),
        SectionCard(
          title: 'Datos de la empresa',
          subtitle: 'Aparecen en la cabecera y en el índice exportado',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 720;
              final fields = [
                TextField(
                  controller: _company,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la empresa',
                    prefixIcon: Icon(Icons.business_outlined, size: 19),
                  ),
                ),
                TextField(
                  controller: _owner,
                  decoration: const InputDecoration(
                    labelText: 'Persona propietaria',
                    prefixIcon: Icon(Icons.person_outline, size: 19),
                  ),
                ),
                TextField(
                  controller: _taxId,
                  decoration: const InputDecoration(
                    labelText: 'CIF / NIF (opcional)',
                    prefixIcon: Icon(Icons.badge_outlined, size: 19),
                  ),
                ),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Moneda'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _currency,
                      isExpanded: true,
                      isDense: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'EUR',
                          child: Text('Euro (EUR)'),
                        ),
                        DropdownMenuItem(
                          value: 'USD',
                          child: Text('Dólar (USD)'),
                        ),
                        DropdownMenuItem(
                          value: 'GBP',
                          child: Text('Libra (GBP)'),
                        ),
                        DropdownMenuItem(
                          value: 'MXN',
                          child: Text('Peso mexicano (MXN)'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _currency = value);
                      },
                    ),
                  ),
                ),
              ];
              if (!wide) {
                return Column(
                  children: [
                    for (final field in fields) ...[
                      field,
                      const SizedBox(height: 12),
                    ],
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        child: Text(_saving ? 'Guardando…' : 'Guardar cambios'),
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: fields[0]),
                      const SizedBox(width: 12),
                      Expanded(child: fields[1]),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: fields[2]),
                      const SizedBox(width: 12),
                      Expanded(child: fields[3]),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.check, size: 17),
                      label: Text(_saving ? 'Guardando…' : 'Guardar cambios'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 860;
            final storage = SectionCard(
              title: 'Almacenamiento',
              subtitle: 'Todo vive en este dispositivo',
              child: Column(
                children: [
                  _InfoRow(
                    label: 'Documentos',
                    value: '${controller.totalDocuments}',
                  ),
                  _InfoRow(
                    label: 'Espacio ocupado',
                    value: humanBytes(controller.totalBytes),
                  ),
                  _InfoRow(
                    label: 'Carpetas',
                    value: '${controller.folders.length}',
                  ),
                  _InfoRow(
                    label: 'Ubicación',
                    value: 'Datos locales de la aplicación',
                    last: true,
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/export'),
                      icon: const Icon(Icons.archive_outlined, size: 17),
                      label: const Text('Crear copia de seguridad'),
                    ),
                  ),
                ],
              ),
            );
            final privacy = SectionCard(
              title: 'Privacidad',
              subtitle: 'Tus archivos no salen de este equipo',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const InlineNotice(
                    message:
                        'Los archivos no salen de este equipo. La aplicación no tiene '
                        'publicidad, telemetría ni modelos en la nube.',
                    icon: Icons.shield_outlined,
                    tone: NoticeTone.success,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Cuando se active el modo equipo, la sincronización será opcional y '
                    'con un proveedor europeo. Esta versión local seguirá funcionando.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
            if (!wide) {
              return Column(
                children: [storage, const SizedBox(height: 16), privacy],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: storage),
                const SizedBox(width: 18),
                Expanded(child: privacy),
              ],
            );
          },
        ),
        if (!kIsWeb) ...[
          const SizedBox(height: 22),
          const WatchFolderSection(),
        ],
        const SizedBox(height: 22),
        SectionCard(
          title: 'Cuenta',
          subtitle: 'Sesión iniciada en este dispositivo',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                label: 'Correo',
                value: SupabaseConfig.userEmail.isEmpty
                    ? 'Sesión activa'
                    : SupabaseConfig.userEmail,
                last: true,
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Cerrar sesión'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SectionCard(
          title: 'Zona sensible',
          subtitle: 'Solo afecta a la copia que gestiona la aplicación',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Borrar el archivo elimina los documentos y carpetas de la aplicación. '
                'No borra los archivos originales que hayas seleccionado en tu disco.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
                onPressed: _reset,
                icon: const Icon(Icons.delete_forever_outlined, size: 18),
                label: const Text('Borrar todos los datos'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const SectionCard(
          title: 'Acerca de',
          subtitle: 'TuAdministradorNB 0.1.0',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Archivo digital gratuito para ordenar facturas, nóminas, contratos y '
                'hojas de cálculo de una empresa. Hecho con Flutter para funcionar en '
                'Windows, Android y web.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.55,
                  color: AppColors.inkSoft,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Fase 1 · Modo local',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.last = false});

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
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

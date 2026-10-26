import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/app_controller.dart';
import '../widgets.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final _formKey = GlobalKey<FormState>();
  final _company = TextEditingController();
  final _owner = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _company.dispose();
    _owner.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await context.read<AppController>().completeOnboarding(
      companyName: _company.text,
      ownerName: _owner.text,
    );
    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final form = _WelcomeForm(
            formKey: _formKey,
            company: _company,
            owner: _owner,
            saving: _saving,
            onSubmit: _start,
          );

          if (!wide) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const AppMark(size: 40),
                        const SizedBox(width: 10),
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                              letterSpacing: -0.3,
                            ),
                            children: [
                              TextSpan(text: 'TuAdministrador'),
                              TextSpan(
                                text: 'NB',
                                style: TextStyle(color: AppColors.accent),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'El archivo de tu empresa, en orden.',
                      style: Theme.of(context).textTheme.displaySmall
                          ?.copyWith(fontSize: 30),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Facturas, nóminas, contratos y hojas de cálculo clasificados '
                      'en un solo lugar. Gratis y sin subir nada a un servidor.',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: 28),
                    form,
                  ],
                ),
              ),
            );
          }

          return Row(
            children: [
              Expanded(
                flex: 10,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.navy,
                        Color(0xFF173F5F),
                        Color(0xFF0C6B5D),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(52),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const AppMark(size: 44),
                              const SizedBox(width: 12),
                              RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                  children: [
                                    TextSpan(text: 'TuAdministrador'),
                                    TextSpan(
                                      text: 'NB',
                                      style: TextStyle(
                                        color: Color(0xFF5EEAD4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            'El archivo de tu empresa,\nen orden.',
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontSize: 44,
                                  height: 1.1,
                                ),
                          ),
                          const SizedBox(height: 18),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: Text(
                              'Sube tus carpetas una vez. La aplicación detecta qué es '
                              'cada archivo, propone una carpeta y te deja todo '
                              'localizable en segundos.',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.78),
                                    height: 1.55,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 34),
                          const _Feature(
                            icon: Icons.lock_outline,
                            text: 'Tus archivos se quedan en este dispositivo',
                          ),
                          const _Feature(
                            icon: Icons.auto_awesome_outlined,
                            text: 'Clasificación asistida y siempre revisable',
                          ),
                          const _Feature(
                            icon: Icons.archive_outlined,
                            text: 'Exporta el archivo ordenado en un ZIP',
                          ),
                          const Spacer(),
                          Text(
                            'Gratis · sin cuotas · sin cuenta de pago',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 11,
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(48),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: form,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF5EEAD4)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.86),
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeForm extends StatelessWidget {
  const _WelcomeForm({
    required this.formKey,
    required this.company,
    required this.owner,
    required this.saving,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController company;
  final TextEditingController owner;
  final bool saving;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Crea tu espacio de trabajo',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Solo necesitamos el nombre de la empresa. No hay registro, '
            'correo ni tarjeta.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: company,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Nombre de la empresa',
              hintText: 'Ej. Administraciones Norte',
              prefixIcon: Icon(Icons.business_outlined, size: 20),
            ),
            validator: (value) {
              if (value == null || value.trim().length < 2) {
                return 'Escribe el nombre de la empresa';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: owner,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
            decoration: const InputDecoration(
              labelText: 'Tu nombre',
              hintText: 'Ej. Marta Ruiz',
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
            validator: (value) {
              if (value == null || value.trim().length < 2) {
                return 'Escribe tu nombre';
              }
              return null;
            },
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: saving ? null : onSubmit,
            child: saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Empezar gratis'),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 16,
                color: AppColors.accentDark,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Los documentos se guardan cifrados por el sistema en este equipo. '
                  'Puedes borrarlo todo desde Ajustes.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(fontSize: 11.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.groups_outlined,
                  size: 19,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '¿Trabajas con más personas? El modo equipo en la nube '
                    '(gratuito) llegará en la siguiente fase del proyecto.',
                    style: Theme.of(context).textTheme.bodySmall,
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

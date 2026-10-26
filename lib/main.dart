import 'package:flutter/material.dart';

import 'app.dart';
import 'core/supabase_config.dart';
import 'core/theme.dart';
import 'data/app_controller.dart';
import 'data/local_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase para autenticación multiusuario
  try {
    await SupabaseConfig.init();
  } catch (error) {
    debugPrint('Aviso: Supabase init error: $error');
  }

  final store = LocalStore();
  final controller = AppController(store);

  // Si hay una sesión persistida, cargar el espacio de ese usuario. Si no,
  // el router llevará a la pantalla de acceso y los datos se cargarán al
  // iniciar sesión.
  final userId = SupabaseConfig.currentUser?.id;
  if (userId != null) {
    try {
      await controller.loadForUser(userId);
    } catch (error) {
      runApp(_StartupErrorApp(error: error));
      return;
    }
  }

  runApp(TuAdministradorNBApp(controller: controller));
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 44,
                    color: AppColors.danger,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No se pudo abrir el archivo local',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

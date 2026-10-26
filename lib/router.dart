import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase_config.dart';
import 'data/app_controller.dart';
import 'ui/pages/auth_page.dart';
import 'ui/pages/dashboard_page.dart';
import 'ui/pages/documents_page.dart';
import 'ui/pages/export_page.dart';
import 'ui/pages/folders_page.dart';
import 'ui/pages/inbox_page.dart';
import 'ui/pages/settings_page.dart';
import 'ui/pages/team_page.dart';
import 'ui/pages/welcome_page.dart';
import 'ui/shell.dart';

/// Escucha los cambios de sesión de Supabase y mantiene sincronizado el
/// espacio de datos del usuario: carga sus datos al iniciar sesión y los cierra
/// al cerrarla. También refresca el router.
class SessionManager extends ChangeNotifier {
  SessionManager(this._controller) {
    try {
      _sub = SupabaseConfig.client.auth.onAuthStateChange.listen(_onAuthChange);
    } catch (error) {
      debugPrint('Aviso: no se pudo escuchar el estado de sesión: $error');
    }
  }

  final AppController _controller;
  StreamSubscription<AuthState>? _sub;

  Future<void> _onAuthChange(AuthState data) async {
    final user = data.session?.user;
    if (user != null) {
      // Cargar el espacio del usuario si no es el que ya está cargado.
      if (_controller.currentUserId != user.id) {
        try {
          await _controller.loadForUser(user.id);
        } catch (error) {
          debugPrint('Aviso: no se pudo cargar el espacio del usuario: $error');
        }
      }
    } else if (_controller.currentUserId != null) {
      await _controller.endSession();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

GoRouter buildRouter(AppController controller) {
  final authNotifier = SessionManager(controller);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: Listenable.merge([controller, authNotifier]),
    redirect: (context, state) {
      final isAuthenticated = SupabaseConfig.isAuthenticated;
      final atAuth = state.matchedLocation == '/auth';

      // 1. Si no está autenticado, redirigir a /auth
      if (!isAuthenticated) {
        return atAuth ? null : '/auth';
      }

      // 2. Si ya está autenticado y está en /auth, redirigir adentro
      if (atAuth) {
        return '/';
      }

      // 3. Flujo normal de bienvenida/empresa
      final atWelcome = state.matchedLocation == '/welcome';
      if (!controller.hasWorkspace) return atWelcome ? null : '/welcome';
      if (atWelcome) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(currentPath: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/inbox',
            builder: (context, state) => const InboxPage(),
          ),
          GoRoute(
            path: '/documents',
            builder: (context, state) => DocumentsPage(
              initialFolderId: state.uri.queryParameters['folder'],
              initialQuery: state.uri.queryParameters['q'],
            ),
          ),
          GoRoute(
            path: '/folders',
            builder: (context, state) => const FoldersPage(),
          ),
          GoRoute(
            path: '/export',
            builder: (context, state) => const ExportPage(),
          ),
          GoRoute(path: '/team', builder: (context, state) => const TeamPage()),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
}

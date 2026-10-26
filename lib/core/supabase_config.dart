import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Se pueden sobreescribir en compilación con:
  //   flutter build web --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  // El valor por defecto es la clave *publicable* (segura de exponer en el cliente;
  // la seguridad real la aporta RLS cuando se guarden datos en Supabase).
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://zwzxzofxnekflihqabwo.supabase.co',
  );
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_7Kv5sLY7CyiDUItmBXA17g_WCIMdQQN',
  );

  static SupabaseClient get client => Supabase.instance.client;

  /// `true` solo si `Supabase.initialize` se completó. Evita que los accesos a
  /// `client` lancen excepción cuando la inicialización falló (p. ej. sin red).
  static bool get isInitialized {
    try {
      Supabase.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  static User? get currentUser {
    try {
      return client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  static bool get isAuthenticated => currentUser != null;

  static String get userEmail => currentUser?.email ?? '';

  static Future<void> init() async {
    await Supabase.initialize(
      url: url,
      publishableKey: publishableKey,
      debug: kDebugMode,
    );
  }

  static String friendlyErrorMessage(Object error) {
    final message = error.toString();
    if (message.contains('Invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (message.contains('User already registered')) {
      return 'Este correo ya está registrado. Prueba a iniciar sesión.';
    }
    if (message.contains('Password should be at least')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (message.contains('Email not confirmed')) {
      return 'Debes confirmar tu correo electrónico antes de entrar.';
    }
    if (message.contains('rate limit') || message.contains('over_email_send_rate_limit')) {
      return 'Demasiados intentos. Espera unos momentos antes de reintentar.';
    }
    if (message.contains('Network') || message.contains('Failed host lookup')) {
      return 'Sin conexión a internet. Comprueba tu red.';
    }
    return 'Error: $message';
  }
}

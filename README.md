# TuAdministradorNB

Archivo digital para empresas: añade facturas, nóminas, contratos y hojas de cálculo
desordenados y la app los clasifica, los deja buscables y los exporta ordenados en un
ZIP con su estructura real. Hecho con Flutter (web, Windows y Android).

- **Local-first:** los documentos se guardan en el dispositivo (Hive / IndexedDB), aislados por usuario.
- **Acceso con cuenta:** autenticación mediante Supabase Auth.
- **Los originales nunca se modifican.**

En producción: https://tuadministradornb.vercel.app (PWA instalable).

## Desarrollo

```bash
flutter pub get
flutter run -d chrome        # desarrollo web
flutter analyze
flutter test
flutter build web --release  # build de producción
```

## Despliegue

Cada push a `main` despliega automáticamente en Vercel: `vercel.json` instala Flutter y
ejecuta `flutter build web --release`. La clave de Supabase es publicable (segura en el
cliente) y puede sobreescribirse con `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`.

Más detalle del proyecto en `docs/00-PROYECTO.md`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tu_administrador_nb/core/theme.dart';
import 'package:tu_administrador_nb/data/app_controller.dart';
import 'package:tu_administrador_nb/data/local_store.dart';
import 'package:tu_administrador_nb/ui/pages/welcome_page.dart';

void main() {
  testWidgets('la pantalla de bienvenida muestra el formulario de empresa', (
    tester,
  ) async {
    final controller = AppController(LocalStore());

    await tester.pumpWidget(
      ChangeNotifierProvider<AppController>.value(
        value: controller,
        child: MaterialApp(theme: AppTheme.light(), home: const WelcomePage()),
      ),
    );

    expect(find.text('Crea tu espacio de trabajo'), findsOneWidget);
    expect(find.text('Nombre de la empresa'), findsOneWidget);
    expect(find.text('Tu nombre'), findsOneWidget);
    expect(find.text('Empezar gratis'), findsOneWidget);
  });

  testWidgets('el formulario valida que los nombres no estén vacíos', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AppController>.value(
        value: AppController(LocalStore()),
        child: MaterialApp(theme: AppTheme.light(), home: const WelcomePage()),
      ),
    );

    await tester.tap(find.text('Empezar gratis'));
    await tester.pump();

    expect(find.text('Escribe el nombre de la empresa'), findsOneWidget);
    expect(find.text('Escribe tu nombre'), findsOneWidget);
  });
}

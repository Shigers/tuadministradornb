import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tu_administrador_nb/core/theme.dart';
import 'package:tu_administrador_nb/data/app_controller.dart';
import 'package:tu_administrador_nb/ui/pages/dashboard_page.dart';
import 'package:tu_administrador_nb/ui/pages/documents_page.dart';
import 'package:tu_administrador_nb/ui/pages/export_page.dart';
import 'package:tu_administrador_nb/ui/pages/folders_page.dart';
import 'package:tu_administrador_nb/ui/pages/inbox_page.dart';
import 'package:tu_administrador_nb/ui/pages/settings_page.dart';
import 'package:tu_administrador_nb/ui/pages/team_page.dart';
import 'package:tu_administrador_nb/ui/shell.dart';

import 'support/memory_store.dart';

class _Destination {
  const _Destination(this.path, this.page);

  final String path;
  final Widget page;
}

const _destinations = <_Destination>[
  _Destination('/', DashboardPage()),
  _Destination('/inbox', InboxPage()),
  _Destination('/documents', DocumentsPage()),
  _Destination('/folders', FoldersPage()),
  _Destination('/export', ExportPage()),
  _Destination('/team', TeamPage()),
  _Destination('/settings', SettingsPage()),
];

Future<AppController> _seededController() async {
  final store = MemoryStore()..seedDemo();
  final controller = AppController(store);
  await store.init();
  await controller.load();
  return controller;
}

Widget _harness(AppController controller, _Destination destination) {
  return ChangeNotifierProvider<AppController>.value(
    value: controller,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('es', 'ES'),
      supportedLocales: const [Locale('es', 'ES'), Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AppShell(currentPath: destination.path, child: destination.page),
    ),
  );
}

void main() {
  for (final size in const [Size(1440, 900), Size(390, 844)]) {
    final label = size.width >= 1000 ? 'escritorio' : 'móvil';

    group('layout $label', () {
      for (final destination in _destinations) {
        testWidgets('${destination.path} se pinta sin errores ni desbordes', (
          tester,
        ) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          addTearDown(tester.view.reset);

          final controller = await _seededController();
          await tester.pumpWidget(_harness(controller, destination));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        });
      }
    });
  }
}

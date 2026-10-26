import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'data/app_controller.dart';
import 'router.dart';

class TuAdministradorNBApp extends StatefulWidget {
  const TuAdministradorNBApp({super.key, required this.controller});

  final AppController controller;

  @override
  State<TuAdministradorNBApp> createState() => _TuAdministradorNBAppState();
}

class _TuAdministradorNBAppState extends State<TuAdministradorNBApp> {
  late final GoRouter _router = buildRouter(widget.controller);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppController>.value(
      value: widget.controller,
      child: MaterialApp.router(
        title: 'TuAdministradorNB',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: _router,
        locale: const Locale('es', 'ES'),
        supportedLocales: const [Locale('es', 'ES'), Locale('es')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

class SmartPassApp extends StatefulWidget {
  final Uri initialUri;

  const SmartPassApp({
    super.key,
    required this.initialUri,
  });

  @override
  State<SmartPassApp> createState() => _SmartPassAppState();
}

class _SmartPassAppState extends State<SmartPassApp> {
  // Le routeur est créé une seule fois pour conserver la navigation
  // lors des reconstructions (changement de thème, etc.).
  late final GoRouter _router = AppRouter.create(widget.initialUri);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, _) {
        return MaterialApp.router(
          title: 'SmartPass',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          routerConfig: _router,
        );
      },
    );
  }
}

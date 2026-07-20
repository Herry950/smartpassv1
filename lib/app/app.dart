import 'package:flutter/material.dart';

import 'router.dart';
import 'theme/app_theme.dart';

class SmartPassApp extends StatelessWidget {
  const SmartPassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SmartPass',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
    );
  }
}
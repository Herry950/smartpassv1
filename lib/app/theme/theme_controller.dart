import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';

/// Gère le thème choisi par l'utilisateur (« Clair » ou « Sombre »)
/// et le conserve entre les sessions.
class ThemeController {
  ThemeController._();

  static const String _storageKey = 'smartpass_theme_mode';

  static final ValueNotifier<ThemeMode> mode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  static bool get isDark => mode.value == ThemeMode.dark;

  /// Charge le thème enregistré. À appeler avant `runApp`.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);
      _apply(saved == 'dark' ? ThemeMode.dark : ThemeMode.light);
    } catch (error) {
      debugPrint('Thème : lecture impossible ($error). Mode clair utilisé.');
      _apply(ThemeMode.light);
    }
  }

  /// Change le thème et l'enregistre.
  static Future<void> setMode(ThemeMode newMode) async {
    final normalized =
        newMode == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light;

    if (normalized == mode.value) return;

    _apply(normalized);
    _rebuildAllWidgets();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        normalized == ThemeMode.dark ? 'dark' : 'light',
      );
    } catch (error) {
      debugPrint('Thème : enregistrement impossible ($error).');
    }
  }

  static void _apply(ThemeMode newMode) {
    AppColors.applyDarkMode(newMode == ThemeMode.dark);
    mode.value = newMode;
  }

  /// Les couleurs `AppColors` sont lues pendant le `build` des widgets.
  /// On force donc la reconstruction de tout l'arbre (sans perdre l'état)
  /// pour appliquer immédiatement le nouveau thème à toutes les pages.
  static void _rebuildAllWidgets() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      void rebuild(Element element) {
        element.markNeedsBuild();
        element.visitChildren(rebuild);
      }

      WidgetsBinding.instance.rootElement?.visitChildren(rebuild);
    });
  }
}

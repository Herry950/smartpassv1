import 'package:flutter/material.dart';

/// Palette SmartPass.
///
/// Les couleurs neutres (fonds, textes, bordures) et les couleurs de marque
/// utilisées comme texte/icône dépendent du thème actif (clair ou sombre).
/// Le thème actif est piloté par `ThemeController`.
class AppColors {
  AppColors._();

  static bool _isDark = false;

  /// Indique si le thème sombre est actif.
  static bool get isDark => _isDark;

  /// Réservé à `ThemeController`.
  static void applyDarkMode(bool value) => _isDark = value;

  // ===========================
  // Couleurs de marque (fixes)
  // ===========================

  /// Bleu SmartPass.
  static const Color brandNavy = Color(0xFF071A4C);

  /// Accent principal.
  static const Color brandAccent = Color(0xFF2563EB);

  /// Fond principal du mode sombre.
  static const Color darkBackground = Color(0xFF040D26);

  /// Cartes et modales du mode sombre.
  static const Color darkSurface = Color(0xFF0B2261);

  // ===========================
  // Identité (dépend du thème)
  // ===========================

  /// Couleur principale : bleu en mode clair, accent en mode sombre
  /// (le bleu foncé serait illisible sur le fond sombre).
  static Color get primary => _isDark ? brandAccent : brandNavy;

  /// Variante utilisée pour les textes accentués.
  static Color get primaryDark =>
      _isDark ? const Color(0xFF93C5FD) : brandNavy;

  /// Variante claire.
  static Color get primaryLight =>
      _isDark ? const Color(0xFF3B82F6) : brandAccent;

  // ===========================
  // États
  // ===========================

  /// Succès (vert émeraude).
  static const Color success = Color(0xFF10B981);

  /// Attention / alerte (ambre).
  static const Color warning = Color(0xFFF59E0B);

  /// Erreur (rouge).
  static const Color error = Color(0xFFEF4444);

  /// Information (accent).
  static const Color info = brandAccent;

  // ===========================
  // Fonds
  // ===========================

  /// Fond principal.
  static Color get background =>
      _isDark ? darkBackground : const Color(0xFFF8FAFC);

  /// Cartes.
  static Color get surface => _isDark ? darkSurface : Colors.white;

  // ===========================
  // Texte
  // ===========================

  static Color get textPrimary =>
      _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

  static Color get textSecondary =>
      _isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

  /// Texte désactivé / placeholders.
  static const Color textDisabled = Color(0xFF94A3B8);

  static const Color textLight = Colors.white;

  // ===========================
  // Bordures
  // ===========================

  static Color get border =>
      _isDark ? Colors.white12 : const Color(0xFFE2E8F0);

  // ===========================
  // Dégradé SmartPass
  // ===========================

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      brandNavy,
      darkSurface,
      brandAccent,
    ],
  );
}

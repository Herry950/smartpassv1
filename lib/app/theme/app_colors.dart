import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ===========================
  // Identité SmartPass
  // ===========================

  /// Couleur principale (Olive Premium)
  static const Color primary = Color(0xFF556B2F);

  /// Variante plus foncée
  static const Color primaryDark = Color(0xFF3F5222);

  /// Variante plus claire
  static const Color primaryLight = Color(0xFF6B8E23);

  // ===========================
  // États
  // ===========================

  /// Succès
  static const Color success = Color(0xFF2E7D32);

  /// Attention
  static const Color warning = Color(0xFFF9A825);

  /// Erreur
  static const Color error = Color(0xFFC62828);

  /// Information
  static const Color info = Color(0xFF1565C0);

  // ===========================
  // Fonds
  // ===========================

  /// Fond principal
  static const Color background = Color(0xFFF8F9FA);

  /// Cartes
  static const Color surface = Colors.white;

  // ===========================
  // Texte
  // ===========================

  static const Color textPrimary = Color(0xFF212121);

  static const Color textSecondary = Color(0xFF616161);

  static const Color textLight = Colors.white;

  // ===========================
  // Bordures
  // ===========================

  static const Color border = Color(0xFFE0E0E0);

  // ===========================
  // Dégradé SmartPass
  // ===========================

  static const LinearGradient primaryGradient =
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primaryDark,
          primary,
          primaryLight,
        ],
      );
}
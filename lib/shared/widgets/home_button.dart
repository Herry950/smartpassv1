import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/auth_service.dart';

/// Bouton « Accueil » : ramène l'utilisateur au tableau de bord de son
/// rôle réel (déterminé en base). Les gardes de navigation restent
/// appliquées par le routeur.
class HomeButton extends StatelessWidget {
  const HomeButton({super.key});

  Future<void> _goHome(BuildContext context) async {
    String? home;
    try {
      home = AuthService.homeRouteForRole(
        await AuthService.getCachedUserRole(),
      );
    } catch (_) {
      home = null;
    }

    if (!context.mounted) return;
    context.go(home ?? '/login');
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Accueil',
      icon: const Icon(Icons.home_rounded),
      onPressed: () => _goHome(context),
    );
  }
}

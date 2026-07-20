import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:myprojectflut/features/auth/presentation/widgets/role_card.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 80 : 24,
            vertical: 40,
          ),
          child: Column(
            children: [
              const SizedBox(height: 30),

              Text(
                "Bienvenue sur SmartPass",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall,
              ).animate().fadeIn().slideY(begin: 0.2),

              const SizedBox(height: 16),

              Text(
                "Choisissez votre espace pour continuer",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 50),

              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 700,
                ),
                child: Column(
                  children: [
                    RoleCard(
                      icon: Icons.school_rounded,
                      title: "Étudiant",
                      description:
                          "Paiement, carte numérique et accès aux examens.",
                      onTap: () {
                        context.go('/login');
                      },
                    ).animate().fadeIn(delay: 300.ms).slideX(),

                    const SizedBox(height: 20),

                    RoleCard(
                      icon: Icons.qr_code_scanner_rounded,
                      title: "Assistant",
                      description:
                          "Scanner un QR Code ou vérifier un matricule.",
                      onTap: () {
                        context.go('/login');
                      },
                    ).animate().fadeIn(delay: 500.ms).slideX(),

                    const SizedBox(height: 20),

                    RoleCard(
                      icon: Icons.admin_panel_settings_rounded,
                      title: "Administrateur",
                      description:
                          "Gestion des étudiants, paiements et accès.",
                      onTap: () {
                        context.go('/login');
                      },
                    ).animate().fadeIn(delay: 700.ms).slideX(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:myprojectflut/app/theme/app_colors.dart';
import 'package:myprojectflut/core/services/auth_service.dart';
import 'package:myprojectflut/shared/widgets/app_logout_card.dart';
import 'package:myprojectflut/shared/widgets/app_settings_card.dart';
import 'package:myprojectflut/shared/widgets/change_password_dialog.dart';

import '../widgets/assistant_header.dart';
import 'matricule_search_page.dart';
import 'receipt_verification_page.dart';
import 'cash_payment_validation_page.dart';

class AssistantDashboardPage extends StatefulWidget {
  const AssistantDashboardPage({super.key});

  @override
  State<AssistantDashboardPage> createState() =>
      _AssistantDashboardPageState();
}

class _AssistantDashboardPageState extends State<AssistantDashboardPage> {
  bool _showProfile = false;

  @override
  Widget build(BuildContext context) {
    debugPrint('Session Supabase active : ${AuthService.hasActiveSession()}');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Espace Assistant"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _showProfile
                  ? Icons.dashboard_outlined
                  : Icons.person_outline_rounded,
              color: AppColors.primary,
            ),
            tooltip: _showProfile ? "Tableau de bord" : "Mon Profil",
            onPressed: () {
              setState(() => _showProfile = !_showProfile);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1300),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. EN-TÊTE ASSISTANT
                const AssistantHeader(
                  assistantName: "Jean Assistant",
                )
                    .animate()
                    .fadeIn()
                    .slideY(begin: .1),

                const SizedBox(height: 24),

                if (_showProfile) ...[
                  // --- SECTION PROFIL & PARAMÈTRES ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Mon Profil & Paramètres",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() => _showProfile = false),
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: AppColors.primary),
                        label: const Text(
                          "Retour",
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppSettingsCard(
                    onChangePassword: () => showChangePasswordDialog(context),
                  )
                      .animate()
                      .fadeIn()
                      .slideY(begin: .1),
                  const SizedBox(height: 20),
                  const AppLogoutCard()
                      .animate()
                      .fadeIn(delay: 100.ms)
                      .slideY(begin: .1),
                ] else ...[
                  // --- SECTION TABLEAU DE BORD ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Mode de vérification",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          setState(() => _showProfile = true);
                        },
                        icon: const Icon(Icons.person_rounded, size: 18),
                        label: const Text("Mon Profil"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 4 Boutons de modes de vérification
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;
                      final double buttonWidth = isMobile
                          ? (constraints.maxWidth - 12) / 2
                          : 165;

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildActionButton(
                            context,
                            icon: Icons.qr_code_scanner_rounded,
                            title: "Scanner QR Code",
                            width: buttonWidth,
                            color: AppColors.primary,
                            onTap: () {
                              // TODO: Naviguer vers la page du Scanner QR Code
                            },
                          ),
                          _buildActionButton(
                            context,
                            icon: Icons.badge_outlined,
                            title: "Par Matricule",
                            width: buttonWidth,
                            color: AppColors.info,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (context) => const MatriculeSearchPage(),
                              ));
                            },
                          ),
                          _buildActionButton(
                            context,
                            icon: Icons.receipt_long_rounded,
                            title: "Vérifier Reçu",
                            width: buttonWidth,
                            color: AppColors.primaryLight,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (context) => const ReceiptVerificationPage(),
                              ));
                            },
                          ),
                          _buildActionButton(
                            context,
                            icon: Icons.how_to_reg_rounded,
                            title: "Validation Manuelle",
                            width: buttonWidth,
                            color: AppColors.success,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (context) => const CashPaymentValidationPage(),
                              ));
                            },
                          ),
                        ],
                      );
                    },
                  )
                      .animate()
                      .fadeIn(delay: 150.ms)
                      .slideY(begin: .1),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget helper pour les boutons d'action rapide
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required double width,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

import 'package:myprojectflut/app/theme/app_colors.dart';

class DashboardStatsGrid extends StatelessWidget {
  final bool examAuthorized;
  final bool paymentValidated;
  final int upcomingExamCount;
  final int unreadNotificationCount;

  const DashboardStatsGrid({
    super.key,
    required this.examAuthorized,
    required this.paymentValidated,
    required this.upcomingExamCount,
    required this.unreadNotificationCount,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Téléphone (< 480 px) : 4 tuiles compactes sur une ligne,
        // dans le style des « Actions rapides ».
        if (constraints.maxWidth < 480) {
          return GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.72,
            children: _cards(compact: true),
          );
        }

        // Tablette et ordinateur : disposition existante conservée.
        return GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width >= 900 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.25,
          children: _cards(compact: false),
        );
      },
    );
  }

  List<Widget> _cards({required bool compact}) {
    return [
        _StatCard(
          icon: examAuthorized
              ? Icons.verified_user_rounded
              : Icons.gpp_maybe_rounded,
          title: "Accès",
          value: examAuthorized ? "Autorisé" : "Non autorisé",
          color: examAuthorized ? AppColors.success : AppColors.textSecondary,
          compact: compact,
        ),
        _StatCard(
          icon: Icons.account_balance_wallet_rounded,
          title: "Paiement",
          value: paymentValidated ? "Validé" : "Non validé",
          color: paymentValidated ? AppColors.success : AppColors.info,
          compact: compact,
        ),
        _StatCard(
          icon: Icons.event_available_rounded,
          title: "Examens à venir",
          value: "$upcomingExamCount",
          color: AppColors.info,
          compact: compact,
        ),
        _StatCard(
          icon: Icons.notifications_active_rounded,
          title: "Notifications non lues",
          value: "$unreadNotificationCount",
          color: AppColors.primaryLight,
          compact: compact,
        ),
    ];
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  final bool compact;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.compact = false,
  });

  Widget _buildCompact(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: color.withValues(alpha: .15),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompact(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color.withValues(alpha: .15),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
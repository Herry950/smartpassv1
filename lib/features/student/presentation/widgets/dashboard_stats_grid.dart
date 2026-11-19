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
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width >= 900 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.25,
      children: [
        _StatCard(
          icon: examAuthorized
              ? Icons.verified_user_rounded
              : Icons.gpp_maybe_rounded,
          title: "Accès",
          value: examAuthorized ? "Autorisé" : "Non autorisé",
          color: examAuthorized ? AppColors.success : AppColors.textSecondary,
        ),
        _StatCard(
          icon: Icons.account_balance_wallet_rounded,
          title: "Paiement",
          value: paymentValidated ? "Validé" : "Non validé",
          color: paymentValidated ? AppColors.success : AppColors.info,
        ),
        _StatCard(
          icon: Icons.event_available_rounded,
          title: "Examens à venir",
          value: "$upcomingExamCount",
          color: AppColors.info,
        ),
        _StatCard(
          icon: Icons.notifications_active_rounded,
          title: "Notifications non lues",
          value: "$unreadNotificationCount",
          color: AppColors.primaryLight,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
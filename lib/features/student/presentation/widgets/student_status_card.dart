import 'package:flutter/material.dart';

import 'package:myprojectflut/app/theme/app_colors.dart';

class StudentStatusCard extends StatelessWidget {
  final bool paymentValidated;
  final bool examAuthorized;

  const StudentStatusCard({
    super.key,
    required this.paymentValidated,
    required this.examAuthorized,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String title;
    String subtitle;

    if (examAuthorized) {
      icon = Icons.verified_rounded;
      color = AppColors.success;
      title = "Accès aux examens";
      subtitle = "Autorisé à passer l'examen";
    } else if (paymentValidated) {
      icon = Icons.hourglass_top_rounded;
      color = AppColors.warning;
      title = "Accès aux examens";
      subtitle = "En attente de validation";
    } else {
      icon = Icons.warning_rounded;
      color = AppColors.error;
      title = "Accès aux examens";
      subtitle = "Paiement non validé";
    }

    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),

            const SizedBox(width: 20),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    subtitle,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
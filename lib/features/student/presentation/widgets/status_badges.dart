import 'package:myprojectflut/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

class StatusBadges extends StatelessWidget {
  final bool paymentValidated;
  final bool examAuthorized;

  const StatusBadges({
    super.key,
    required this.paymentValidated,
    required this.examAuthorized,
  });

  Widget badge(
    String text,
    bool ok,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: ok
            ? AppColors.success.withValues(alpha: .15)
            : AppColors.error.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok
                ? Icons.check_circle
                : Icons.cancel,
            size: 18,
            color:
                ok ? AppColors.success : AppColors.error,
          ),

          const SizedBox(width: 8),

          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color:
                  ok ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        badge(
          "Paiement validé",
          paymentValidated,
        ),
        badge(
          "Accès autorisé",
          examAuthorized,
        ),
      ],
    );
  }
}
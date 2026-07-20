import 'package:flutter/material.dart';

import 'package:myprojectflut/app/theme/app_colors.dart';

class PaymentValidationCard extends StatelessWidget {
  const PaymentValidationCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
            CircleAvatar(
              radius: 28,
              backgroundColor:
                  AppColors.success.withValues(alpha: .15),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.success,
              ),
            ),

            const SizedBox(width: 18),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    "Paiement",
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "Paiement validé",
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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
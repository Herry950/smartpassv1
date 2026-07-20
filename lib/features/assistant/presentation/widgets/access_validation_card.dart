import 'package:flutter/material.dart';

import 'package:myprojectflut/app/theme/app_colors.dart';

class AccessValidationCard extends StatelessWidget {
  const AccessValidationCard({
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
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              "Contrôle d'accès",
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),

            const SizedBox(height: 10),

            Text(
              "Après vérification du paiement, choisissez une action.",
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.success,
                  foregroundColor:
                      AppColors.textLight,
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                ),
                onPressed: () {
                  // TODO :
                  // Autoriser l'accès
                },
                icon: const Icon(
                  Icons.check_circle_rounded,
                ),
                label: const Text(
                  "Autoriser l'accès",
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      AppColors.error,
                  side: const BorderSide(
                    color: AppColors.error,
                  ),
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                ),
                onPressed: () {
                  // TODO :
                  // Refuser l'accès
                },
                icon: const Icon(
                  Icons.cancel_rounded,
                ),
                label: const Text(
                  "Refuser l'accès",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
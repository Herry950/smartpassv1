import 'package:flutter/material.dart';

import 'package:myprojectflut/app/theme/app_colors.dart';

class AssistantSearchCard extends StatelessWidget {
  const AssistantSearchCard({
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
              "Recherche d'un étudiant",
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),

            const SizedBox(height: 8),

            Text(
              "Scannez le QR Code ou recherchez un étudiant à l'aide de son matricule.",
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO :
                  // Scanner le QR Code
                },
                icon: const Icon(
                  Icons.qr_code_scanner_rounded,
                ),
                label: const Text(
                  "Scanner le QR Code",
                ),
              ),
            ),

            const SizedBox(height: 24),

            TextField(
              decoration: InputDecoration(
                hintText: "Ex : 21007",
                labelText: "Matricule",
                prefixIcon: const Icon(
                  Icons.badge_rounded,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO :
                  // Recherche Supabase
                },
                icon: const Icon(
                  Icons.search_rounded,
                ),
                label: const Text(
                  "Rechercher",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
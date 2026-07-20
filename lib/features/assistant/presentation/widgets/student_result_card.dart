import 'package:flutter/material.dart';

import 'package:myprojectflut/app/theme/app_colors.dart';

class StudentResultCard extends StatelessWidget {
  const StudentResultCard({
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor:
                  AppColors.primary.withValues(alpha: .12),
              child: const Icon(
                Icons.person,
                size: 42,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(width: 20),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    "Héritier Bamumi",
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge,
                  ),

                  const SizedBox(height: 18),

                  _infoRow(
                    Icons.badge,
                    "Matricule",
                    "21007",
                  ),

                  const SizedBox(height: 10),

                  _infoRow(
                    Icons.school,
                    "Faculté",
                    "Génie Informatique",
                  ),

                  const SizedBox(height: 10),

                  _infoRow(
                    Icons.class_,
                    "Promotion",
                    "L3",
                  ),

                  const SizedBox(height: 10),

                  _infoRow(
                    Icons.calendar_month,
                    "Année",
                    "2025 - 2026",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.primary,
        ),

        const SizedBox(width: 10),

        Text(
          "$title : ",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),

        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
}
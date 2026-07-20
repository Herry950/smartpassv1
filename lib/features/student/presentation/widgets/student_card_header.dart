import 'package:flutter/material.dart';

import 'package:myprojectflut/app/theme/app_colors.dart';
import 'package:myprojectflut/core/models/student.dart';

class StudentCardHeader extends StatelessWidget {
  final Student student;

  const StudentCardHeader({
    super.key,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 58,
                  height: 58,
                  color: Colors.white,
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    "assets/images/ulpgl_logo.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "UNIVERSITÉ LIBRE DES PAYS DES GRANDS LACS",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Image.asset(
                      "assets/images/smartpass_logo.png",
                      height: 28,
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      "Carte Étudiante Numérique",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: student.examAuthorized
                ? AppColors.success
                : AppColors.error,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: (student.examAuthorized
                        ? AppColors.success
                        : AppColors.error)
                    .withValues(alpha: .35),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                student.examAuthorized
                    ? Icons.verified_user_rounded
                    : Icons.gpp_bad_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                student.examAuthorized ? "AUTORISÉ" : "REFUSÉ",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: .6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
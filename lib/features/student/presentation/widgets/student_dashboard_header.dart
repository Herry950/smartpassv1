import 'package:flutter/material.dart';

import 'package:myprojectflut/app/theme/app_colors.dart';
import 'package:myprojectflut/core/models/student.dart';

import 'today_card.dart';
import 'exam_countdown_card.dart';
import 'status_badges.dart';

class StudentDashboardHeader extends StatelessWidget {
  final Student student;

  const StudentDashboardHeader({
    super.key,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = student.fullName.split(" ").first;

    final hasPhoto =
        student.photoUrl != null &&
        student.photoUrl!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Bonjour $firstName 👋",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "Bienvenue dans votre espace SmartPass",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        const Icon(
                          Icons.school_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),

                        const SizedBox(width: 6),

                        Expanded(
                          child: Text(
                            "${student.promotion} • ${student.department}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              Hero(
                tag: "student_avatar",
                child: CircleAvatar(
                  radius: 38,
                  backgroundColor: Colors.white,
                  backgroundImage: hasPhoto
                      ? NetworkImage(
                          student.photoUrl!,
                        )
                      : null,
                  child: !hasPhoto
                      ? const Icon(
                          Icons.person,
                          size: 42,
                          color: AppColors.primary,
                        )
                      : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          const TodayCard(),

          const SizedBox(height: 16),

          ExamCountdownCard(
            examDate: DateTime(2026, 8, 17),
          ),

          const SizedBox(height: 16),

          StatusBadges(
            paymentValidated:
                student.paymentValidated,
            examAuthorized:
                student.examAuthorized,
          ),
        ],
      ),
    );
  }
}
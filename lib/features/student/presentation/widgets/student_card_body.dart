import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:myprojectflut/app/theme/app_colors.dart';
import 'package:myprojectflut/core/models/student.dart';

import 'student_card_hologram.dart';

class StudentCardBody extends StatelessWidget {
  final Student student;

  const StudentCardBody({
    super.key,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        student.photoUrl != null &&
        student.photoUrl!.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 90,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                image: hasPhoto
                    ? DecorationImage(
                        image: NetworkImage(
                          student.photoUrl!,
                        ),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: !hasPhoto
                  ? const Icon(
                      Icons.person,
                      size: 50,
                      color: AppColors.primary,
                    )
                  : null,
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                student.promotion,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(width: 24),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF7E08A),
                      Color(0xFFD4AF37),
                      Color(0xFFB8860B),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white24,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 2,
                        color: Colors.brown
                            .withValues(
                          alpha: .45,
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 2,
                        height: 28,
                        color: Colors.brown
                            .withValues(
                          alpha: .45,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 13,
                      top: 7,
                      child: Container(
                        width: 30,
                        height: 1.5,
                        color: Colors.brown
                            .withValues(
                          alpha: .35,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 13,
                      bottom: 7,
                      child: Container(
                        width: 30,
                        height: 1.5,
                        color: Colors.brown
                            .withValues(
                          alpha: .35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Text(
                student.fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "N° SP-${student.academicYear.substring(5)}-${student.matricule}",
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                "Matricule : ${student.matricule}",
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),

              Text(
                "Faculté : ${student.faculty}",
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),

              Text(
                "Département : ${student.department}",
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),

              Text(
                "Année : ${student.academicYear}",
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),

        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: QrImageView(
                data:
                    "${student.id}|${student.matricule}|${student.academicYear}",
                version: QrVersions.auto,
                size: 110,
                backgroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            const StudentCardHologram(),

            const SizedBox(height: 8),

            const Text(
              "SECURE",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
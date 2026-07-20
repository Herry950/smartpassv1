import 'package:flutter/material.dart';

import 'package:myprojectflut/app/theme/app_colors.dart';
import 'package:myprojectflut/core/models/student.dart';

import 'student_card_3d.dart';
import 'student_card_body.dart';
import 'student_card_header.dart';

class StudentIdentityCard extends StatelessWidget {
  final Student student;

  const StudentIdentityCard({
    super.key,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    final expiryText = student.expiryDate == null
        ? "--/--/----"
        : "${student.expiryDate!.day}/${student.expiryDate!.month}/${student.expiryDate!.year}";

    return StudentCard3D(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .20),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              /// Bande métallique Premium
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 18,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFFF3B0),
                        Color(0xFFE0C15A),
                        Color(0xFFB8860B),
                        Color(0xFFE0C15A),
                        Color(0xFFFFF3B0),
                      ],
                    ),
                  ),
                ),
              ),

              /// Cercle décoratif haut droite
              Positioned(
                top: -70,
                right: -60,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .06),
                  ),
                ),
              ),

              /// Cercle décoratif bas gauche
              Positioned(
                bottom: -90,
                left: -70,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .05),
                  ),
                ),
              ),

              /// Reflet PVC
              Positioned(
                top: -40,
                left: -20,
                child: Transform.rotate(
                  angle: -.45,
                  child: Container(
                    width: 180,
                    height: 380,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: .18),
                          Colors.white.withValues(alpha: .02),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              /// Filigrane
              Center(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: .045,
                    child: Transform.rotate(
                      angle: -.25,
                      child: const Text(
                        "ULPGL",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 170,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              /// Lignes de sécurité
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: .025,
                    child: Column(
                      children: List.generate(
                        45,
                        (index) => Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 1,
                            ),
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  34,
                  24,
                  24,
                  24,
                ),
                child: Column(
                  children: [
                    StudentCardHeader(
                      student: student,
                    ),

                    const SizedBox(height: 30),

                    StudentCardBody(
                      student: student,
                    ),

                    const SizedBox(height: 24),

                    const Divider(
                      color: Colors.white38,
                    ),

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Expire le : $expiryText",
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),

                        const Row(
                          children: [
                            Icon(
                              Icons.verified_user_rounded,
                              color: Colors.white70,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              "SmartPass v1",
                              style: TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
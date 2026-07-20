import 'package:flutter/material.dart';

import 'package:myprojectflut/app/theme/app_colors.dart';
import 'package:myprojectflut/core/models/student.dart';

class ProfileHeader extends StatelessWidget {
  final Student student;

  const ProfileHeader({
    super.key,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        student.photoUrl != null &&
        student.photoUrl!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Hero(
            tag: "student_avatar",
            child: CircleAvatar(
              radius: 55,
              backgroundColor: Colors.white,
              backgroundImage: hasPhoto
                  ? NetworkImage(student.photoUrl!)
                  : null,
              child: !hasPhoto
                  ? const Icon(
                      Icons.person,
                      size: 60,
                      color: AppColors.primary,
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            student.fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "Matricule : ${student.matricule}",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 18),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _buildBadge(
                Icons.school_rounded,
                student.promotion,
              ),
              _buildBadge(
                Icons.computer_rounded,
                student.department,
              ),
              _buildBadge(
                Icons.workspace_premium_rounded,
                "Étudiant",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(
    IconData icon,
    String text,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
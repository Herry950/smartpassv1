import 'package:flutter/material.dart';

import 'package:myprojectflut/core/models/student.dart';

class ProfileInfoCard extends StatelessWidget {
  final Student student;

  const ProfileInfoCard({
    super.key,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Informations personnelles",
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 24),

            _buildInfoTile(
              Icons.person_rounded,
              "Nom complet",
              student.fullName,
            ),

            _buildInfoTile(
              Icons.badge_rounded,
              "Matricule",
              student.matricule,
            ),

            _buildInfoTile(
              Icons.account_balance_rounded,
              "Faculté",
              student.faculty,
            ),

            _buildInfoTile(
              Icons.computer_rounded,
              "Département",
              student.department,
            ),

            _buildInfoTile(
              Icons.school_rounded,
              "Promotion",
              student.promotion,
            ),

            _buildInfoTile(
              Icons.calendar_today_rounded,
              "Année académique",
              student.academicYear,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.green.withValues(alpha: .12),
            child: Icon(
              icon,
              color: Colors.green,
              size: 20,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
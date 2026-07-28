import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class PaymentReasonCard extends StatelessWidget {
  final String reason;
  final String session;
  final String semester;
  final String academicYear;

  const PaymentReasonCard({
    super.key,
    required this.reason,
    required this.session,
    required this.semester,
    required this.academicYear,
  });

  Widget _buildItem(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            "Motif du paiement",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          _buildItem(
            Icons.description_outlined,
            "Motif",
            reason,
          ),

          const Divider(),

          _buildItem(
            Icons.event_note_outlined,
            "Session",
            session,
          ),

          const Divider(),

          _buildItem(
            Icons.school_outlined,
            "Semestre",
            semester,
          ),

          const Divider(),

          _buildItem(
            Icons.calendar_month_outlined,
            "Année académique",
            academicYear,
          ),
        ],
      ),
    );
  }
}
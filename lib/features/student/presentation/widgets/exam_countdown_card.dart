import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExamCountdownCard extends StatelessWidget {
  final DateTime examDate;

  const ExamCountdownCard({
    super.key,
    required this.examDate,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final days = examDate.difference(now).inDays;

    String title;
    Color color;

    if (days > 1) {
      title = "Début dans : $days jours";
      color = const Color(0xFF8BC34A);
    } else if (days == 1) {
      title = "Début demain";
      color = Colors.orange;
    } else if (days == 0) {
      title = "Examens aujourd'hui";
      color = Colors.redAccent;
    } else {
      title = "Session terminée";
      color = Colors.grey;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: .18),
            child: Icon(
              Icons.school_rounded,
              color: color,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Prochaine session",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  DateFormat(
                    "dd MMMM yyyy",
                    "fr_FR",
                  ).format(examDate),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
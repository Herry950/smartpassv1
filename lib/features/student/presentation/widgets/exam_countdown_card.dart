import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Compte à rebours vers le prochain examen programmé de l'étudiant.
/// La date provient des examens visibles via RLS (aucune date figée).
class ExamCountdownCard extends StatelessWidget {
  /// Date du prochain examen, ou null si aucun examen n'est programmé.
  final DateTime? examDate;

  /// Libellé du cours concerné (facultatif).
  final String? courseLabel;

  const ExamCountdownCard({
    super.key,
    required this.examDate,
    this.courseLabel,
  });

  @override
  Widget build(BuildContext context) {
    final date = examDate;

    String title;
    Color color;

    if (date == null) {
      title = 'Aucun examen programmé';
      color = Colors.white70;
    } else {
      final today = DateUtils.dateOnly(DateTime.now());
      final days = DateUtils.dateOnly(date).difference(today).inDays;

      if (days > 1) {
        title = 'Début dans : $days jours';
        color = const Color(0xFF6EE7B7);
      } else if (days == 1) {
        title = 'Début demain';
        color = const Color(0xFFFCD34D);
      } else {
        title = 'Examen aujourd’hui';
        color = const Color(0xFFFCD34D);
      }
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
                  'Prochain examen',
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
                if (date != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      DateFormat('dd MMMM yyyy', 'fr_FR').format(date),
                      if (courseLabel != null && courseLabel!.isNotEmpty)
                        courseLabel!,
                    ].join(' • '),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

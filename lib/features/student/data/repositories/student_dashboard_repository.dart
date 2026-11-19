import 'package:flutter/material.dart' show DateUtils, debugPrint;
import 'package:myprojectflut/core/models/student.dart';

import '../datasource/student_remote_datasource.dart';
import 'payment_repository.dart';
import 'student_card_repository.dart';
import 'student_repository.dart';

class StudentDashboardRepository {
  StudentDashboardRepository._();

  static Future<Map<String, dynamic>?> loadDashboard() async {
    final Student? student = await StudentRepository.getCurrentStudent();

    if (student == null) {
      debugPrint('Tableau de bord : étudiant introuvable.');
      return null;
    }

    final results = await Future.wait<dynamic>([
      PaymentRepository.getLastPayment(student.id),
      PaymentRepository.getPayments(student.id),
      StudentRemoteDataSource.getNotifications(student.id),
      StudentCardRepository.getStudentCard(student.id),
      StudentRemoteDataSource.getStudentExams(),
    ]);

    final notifications = results[2] as List<Map<String, dynamic>>;
    final exams = results[4] as List<Map<String, dynamic>>;

    // Prochain examen : premier examen programmé aujourd'hui ou plus tard
    // (la liste est déjà triée par date puis heure de début).
    final today = DateUtils.dateOnly(DateTime.now());
    Map<String, dynamic>? nextExam;

    for (final exam in exams) {
      final date = DateTime.tryParse(exam['exam_date']?.toString() ?? '');
      if (date != null && !DateUtils.dateOnly(date).isBefore(today)) {
        nextExam = exam;
        break;
      }
    }

    final upcomingCount = exams.where((exam) {
      final date = DateTime.tryParse(exam['exam_date']?.toString() ?? '');
      return date != null && !DateUtils.dateOnly(date).isBefore(today);
    }).length;

    final course = nextExam?['courses'];

    return {
      'student': student,
      'payment': results[0],
      'payments': results[1],
      'notifications': notifications,
      'studentCard': results[3],
      'exams': exams,
      'upcomingExamCount': upcomingCount,
      'unreadNotificationCount':
          notifications.where((n) => n['is_read'] != true).length,
      'nextExamDate': nextExam == null
          ? null
          : DateTime.tryParse(nextExam['exam_date'].toString()),
      'nextExamLabel': course is Map
          ? [course['code'], course['name']]
              .whereType<String>()
              .join(' — ')
          : null,
    };
  }
}

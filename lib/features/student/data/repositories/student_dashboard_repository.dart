import 'package:myprojectflut/core/models/student.dart';

import 'notification_repository.dart';
import 'payment_repository.dart';
import 'student_card_repository.dart';
import 'student_repository.dart';

class StudentDashboardRepository {
  StudentDashboardRepository._();

  static Future<Map<String, dynamic>?> loadDashboard() async {
    print("========== DASHBOARD ==========");

    final Student? student =
        await StudentRepository.getCurrentStudent();

    if (student == null) {
      print("Étudiant introuvable.");
      return null;
    }

    print("Étudiant chargé : ${student.fullName}");

    final payment =
        await PaymentRepository.getLastPayment(
      student.id,
    );

    print("Dernier paiement : $payment");

    final payments =
        await PaymentRepository.getPayments(
      student.id,
    );

    print("Nombre de paiements : ${payments.length}");

    final notifications =
        await NotificationRepository.getNotifications(
      student.id,
    );

    print(
      "Nombre de notifications : ${notifications.length}",
    );

    final studentCard =
        await StudentCardRepository.getStudentCard(
      student.id,
    );

    print("Carte étudiant : $studentCard");

    print("Dashboard chargé avec succès.");
    print("===============================");

    return {
      'student': student,
      'payment': payment,
      'payments': payments,
      'notifications': notifications,
      'studentCard': studentCard,
    };
  }
}
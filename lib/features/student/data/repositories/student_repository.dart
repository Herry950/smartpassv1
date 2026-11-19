import 'package:flutter/foundation.dart';
import 'package:myprojectflut/core/models/student.dart';

import '../datasource/student_remote_datasource.dart';

class StudentRepository {
  StudentRepository._();

  /// Profil de l'étudiant connecté, construit uniquement
  /// à partir des données Supabase.
  ///
  /// - Paiement validé : paiement validé pour la session ouverte
  ///   aux paiements de l'étudiant ; à défaut de session ouverte,
  ///   statut du dernier paiement.
  /// - Accès autorisé : paiement validé et carte non désactivée.
  ///   (Une carte explicitement désactivée bloque l'accès ;
  ///   l'absence de carte enregistrée ne le bloque pas.)
  /// - Date d'expiration : celle de la carte enregistrée, sinon aucune.
  static Future<Student?> getCurrentStudent() async {
    final data = await StudentRemoteDataSource.getCurrentStudent();

    if (data == null) {
      debugPrint('StudentRepository : aucun profil étudiant trouvé.');
      return null;
    }

    final String studentId = data['id'];

    final currentSession =
        await StudentRemoteDataSource.getCurrentExamSession();

    final bool paymentValidated = currentSession != null
        ? await StudentRemoteDataSource.hasValidatedPaymentForSession(
            studentId,
            currentSession['id'].toString(),
          )
        : await StudentRemoteDataSource.isPaymentValidated(studentId);

    final card = await StudentRemoteDataSource.getStudentCard(studentId);

    final bool cardDeactivated =
        card != null && card['is_active'] != true;

    final DateTime? expiryDate = card?['expires_at'] == null
        ? null
        : DateTime.tryParse(card!['expires_at'].toString());

    return Student(
      id: data['id'],
      authUserId: data['auth_user_id'],
      fullName: data['full_name'],
      matricule: data['matricule'],
      faculty: data['faculty'],
      department: data['department'] ?? '',
      promotion: data['promotion'],
      academicYear: data['academic_year'],
      photoUrl: data['photo_url'],
      expiryDate: expiryDate,
      paymentValidated: paymentValidated,
      examAuthorized: paymentValidated && !cardDeactivated,
    );
  }
}

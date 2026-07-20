import 'package:myprojectflut/core/models/student.dart';

import '../datasource/student_remote_datasource.dart';

class StudentRepository {
  StudentRepository._();

  static Future<Student?> getCurrentStudent() async {
    print("========== StudentRepository ==========");

    final data =
        await StudentRemoteDataSource.getCurrentStudent();

    print("Données étudiant : $data");

    if (data == null) {
      print("Aucun étudiant trouvé dans la table students.");
      return null;
    }

    final String studentId = data['id'];

    print("Student ID : $studentId");

    final paymentValidated =
        await StudentRemoteDataSource.isPaymentValidated(
      studentId,
    );

    print("Paiement validé : $paymentValidated");

    final cardActive =
        await StudentRemoteDataSource.isExamAuthorized(
      studentId,
    );

    print("Carte active : $cardActive");

    final student = Student(
      id: data['id'],
      authUserId: data['auth_user_id'],
      fullName: data['full_name'],
      matricule: data['matricule'],
      faculty: data['faculty'],
      department: data['department'],
      promotion: data['promotion'],
      academicYear: data['academic_year'],
      photoUrl: data['photo_url'],
      expiryDate: DateTime.now().add(
        const Duration(days: 365),
      ),
      paymentValidated: paymentValidated,
      examAuthorized: paymentValidated && cardActive,
    );

    print("Étudiant créé : ${student.fullName}");
    print("=======================================");

    return student;
  }
}
import 'student_repository.dart';
import 'student_card_repository.dart';

class StudentCardPageRepository {
  StudentCardPageRepository._();

  static Future<Map<String, dynamic>?> load() async {
    final student =
        await StudentRepository.getCurrentStudent();

    if (student == null) {
      print("Étudiant NULL");
      return null;
    }

    print("Student ID utilisé : ${student.id}");

    final card =
        await StudentCardRepository.getStudentCard(
      student.id,
    );

    print("Carte récupérée : $card");

    return {
      'student': student,
      'card': card,
    };
  }
}
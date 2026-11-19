
import '../datasource/student_remote_datasource.dart';

class ExamSessionRepository {
  ExamSessionRepository._();

  static Future<Map<String, dynamic>?> getCurrentExamSession() {
    return StudentRemoteDataSource.getCurrentExamSession();
  }

  /// Sessions ouvertes aux paiements concernant l'étudiant connecté.
  static Future<List<Map<String, dynamic>>> getOpenExamSessions() {
    return StudentRemoteDataSource.getOpenExamSessions();
  }

  /// Statuts des paiements de l'étudiant, par session.
  static Future<Map<String, Set<String>>> getPaymentStatusesBySession(
    String studentId,
  ) {
    return StudentRemoteDataSource.getPaymentStatusesBySession(studentId);
  }

  /// Récupère les examens programmés accessibles à l'étudiant connecté.
  static Future<List<Map<String, dynamic>>> getStudentExams() {
    return StudentRemoteDataSource.getStudentExams();
  }
}

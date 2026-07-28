import '../datasource/student_remote_datasource.dart';

class ExamSessionRepository {
  ExamSessionRepository._();

  static Future<Map<String, dynamic>?> getCurrentExamSession() {
    return StudentRemoteDataSource.getCurrentExamSession();
  }
}
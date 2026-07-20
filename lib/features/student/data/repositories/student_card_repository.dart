import '../datasource/student_remote_datasource.dart';

class StudentCardRepository {
  StudentCardRepository._();

  static Future<Map<String, dynamic>?> getStudentCard(
    String studentId,
  ) async {
    return StudentRemoteDataSource.getStudentCard(
      studentId,
    );
  }
}
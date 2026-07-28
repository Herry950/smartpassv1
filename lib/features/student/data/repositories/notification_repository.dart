import '../datasource/student_remote_datasource.dart';
import 'student_repository.dart';

class NotificationRepository {
  NotificationRepository._();

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final student =
        await StudentRepository.getCurrentStudent();

    if (student == null) {
      return [];
    }

    return StudentRemoteDataSource.getNotifications(
      student.id,
    );
  }
}
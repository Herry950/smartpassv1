import '../datasource/student_remote_datasource.dart';

class NotificationRepository {
  NotificationRepository._();

  static Future<List<Map<String, dynamic>>> getNotifications(
    String studentId,
  ) async {
    return StudentRemoteDataSource.getNotifications(
      studentId,
    );
  }
}
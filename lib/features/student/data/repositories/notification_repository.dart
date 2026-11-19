import 'package:supabase_flutter/supabase_flutter.dart';

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

  /// Marque les notifications non lues de l'étudiant connecté comme lues.
  /// RLS : l'étudiant ne peut modifier que is_read de SES notifications.
  static Future<void> markAsRead(List<String> notificationIds) async {
    if (notificationIds.isEmpty) return;
    await Supabase.instance.client
        .from('notifications')
        .update({'is_read': true})
        .inFilter('id', notificationIds)
        .eq('is_read', false);
  }
}
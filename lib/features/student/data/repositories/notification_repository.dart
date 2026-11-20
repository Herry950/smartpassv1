import 'package:flutter/foundation.dart';
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

  /// Incrémenté à chaque changement d'état de lecture : le tableau de
  /// bord s'y abonne pour actualiser son compteur de non lues.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  /// Marque des notifications de l'étudiant connecté comme lues.
  /// RLS + privilège de colonne : l'étudiant ne peut modifier que
  /// is_read de SES notifications.
  static Future<void> markAsRead(List<String> notificationIds) async {
    if (notificationIds.isEmpty) return;
    await Supabase.instance.client
        .from('notifications')
        .update({'is_read': true})
        .inFilter('id', notificationIds)
        .eq('is_read', false);
    changes.value++;
  }

  /// Marque toutes les notifications non lues de l'étudiant connecté.
  static Future<void> markAllAsRead() async {
    final student = await StudentRepository.getCurrentStudent();
    if (student == null) return;

    await Supabase.instance.client
        .from('notifications')
        .update({'is_read': true})
        .eq('student_id', student.id)
        .eq('is_read', false);
    changes.value++;
  }

  /// Page de destination d'une notification (null : aucune navigation).
  static String? destinationFor(Map<String, dynamic> notification) {
    final type = notification['type']?.toString();
    final key = notification['dedupe_key']?.toString() ?? '';

    switch (type) {
      case 'payment':
        return key.startsWith('payment_validated')
            ? '/student/receipts'
            : '/student/payment';
      case 'session':
        return '/student/payment';
      case 'card':
        return '/student/card';
      case 'exam':
      case 'schedule':
        return '/student/exams';
      case 'reconciliation':
        return '/student/reconciliations';
      default:
        return null;
    }
  }
}
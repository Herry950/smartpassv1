import 'package:flutter/material.dart';

import 'package:myprojectflut/app/theme/app_colors.dart';

import 'notification_item.dart';

class NotificationList extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;

  /// Ouverture d'une notification (marquage lu + navigation).
  final void Function(Map<String, dynamic> notification)? onOpen;

  /// Marquage individuel comme lu.
  final void Function(Map<String, dynamic> notification)? onMarkRead;

  /// Indique si la notification conduit vers une page.
  final bool Function(Map<String, dynamic> notification)? hasDestination;

  const NotificationList({
    super.key,
    required this.notifications,
    this.onOpen,
    this.onMarkRead,
    this.hasDestination,
  });

  IconData _icon(String? type) {
    switch (type) {
      case "payment":
        return Icons.payments_rounded;

      case "schedule":
        return Icons.calendar_month_rounded;

      case "card":
        return Icons.badge_rounded;

      case "exam":
        return Icons.school_rounded;

      case "session":
        return Icons.event_available_rounded;

      case "reconciliation":
        return Icons.currency_exchange_rounded;

      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _color(String? type) {
    switch (type) {
      case "payment":
        return AppColors.success;

      case "schedule":
        return AppColors.info;

      case "card":
        return AppColors.primary;

      case "exam":
        return AppColors.info;

      case "session":
        return AppColors.primary;

      case "reconciliation":
        return AppColors.warning;

      default:
        return AppColors.primary;
    }
  }

  String _formatDate(String? value) {
    if (value == null) return "";

    final date = DateTime.parse(value).toLocal();
    final now = DateTime.now();

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return "Aujourd'hui";
    }

    final yesterday = now.subtract(const Duration(days: 1));

    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return "Hier";
    }

    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            "Aucune notification disponible.",
          ),
        ),
      );
    }

    return Column(
      children: notifications.map((notification) {
        return NotificationItem(
          icon: _icon(notification['type']),
          color: _color(notification['type']),
          title: notification['title'] ?? "",
          message: notification['message'] ?? "",
          time: _formatDate(notification['created_at']),
          unread: !(notification['is_read'] ?? false),
          onTap: onOpen == null ? null : () => onOpen!(notification),
          onMarkRead:
              onMarkRead == null ? null : () => onMarkRead!(notification),
          hasDestination: hasDestination?.call(notification) ?? false,
        );
      }).toList(),
    );
  }
}
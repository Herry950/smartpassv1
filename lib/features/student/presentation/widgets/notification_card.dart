import 'package:flutter/material.dart';

import 'package:myprojectflut/app/theme/app_colors.dart';

import 'notification_list.dart';

class NotificationsCard extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;

  const NotificationsCard({
    super.key,
    required this.notifications,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.primary,
                ),
                SizedBox(width: 12),
                Text(
                  "Notifications",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            NotificationList(
              notifications: notifications,
            ),
          ],
        ),
      ),
    );
  }
}
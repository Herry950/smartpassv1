import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:myprojectflut/features/student/data/repositories/notification_repository.dart';

import '../widgets/notification_list.dart';

class StudentNotificationsPage extends StatelessWidget {
  const StudentNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: NotificationRepository.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          final notifications =
              snapshot.data ?? [];

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: NotificationList(
                notifications: notifications,
              )
                  .animate()
                  .fadeIn()
                  .slideY(begin: .15),
            ),
          );
        },
      ),
    );
  }
}
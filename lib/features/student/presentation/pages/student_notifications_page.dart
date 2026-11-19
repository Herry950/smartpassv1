import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:myprojectflut/features/student/data/repositories/notification_repository.dart';
import 'package:myprojectflut/shared/widgets/home_button.dart';

import '../widgets/notification_list.dart';

/// Historique des notifications de l'étudiant connecté (RLS).
/// Les notifications affichées sont marquées comme lues ; leur état
/// « non lu » reste visible pendant la consultation en cours.
class StudentNotificationsPage extends StatefulWidget {
  const StudentNotificationsPage({super.key});

  @override
  State<StudentNotificationsPage> createState() =>
      _StudentNotificationsPageState();
}

class _StudentNotificationsPageState extends State<StudentNotificationsPage> {
  late Future<List<Map<String, dynamic>>> _future = _load();

  Future<List<Map<String, dynamic>>> _load() async {
    final notifications = await NotificationRepository.getNotifications();

    final unreadIds = notifications
        .where((n) => n['is_read'] != true)
        .map((n) => n['id'].toString())
        .toList();

    try {
      await NotificationRepository.markAsRead(unreadIds);
    } catch (error) {
      // Marquage indisponible : l'affichage reste correct.
      debugPrint('Notifications : marquage « lu » impossible ($error).');
    }

    return notifications;
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const HomeButton(),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Impossible de charger les notifications : '
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          return SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: NotificationList(
                  notifications: notifications,
                )
                    .animate()
                    .fadeIn()
                    .slideY(begin: .15),
              ),
            ),
          );
        },
      ),
    );
  }
}

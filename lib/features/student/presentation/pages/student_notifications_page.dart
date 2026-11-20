import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:myprojectflut/features/student/data/repositories/notification_repository.dart';
import 'package:myprojectflut/shared/widgets/home_button.dart';

import '../widgets/notification_list.dart';

/// Historique des notifications de l'étudiant connecté (RLS).
///
/// - Chaque notification est cliquable : elle est marquée comme lue puis
///   conduit vers la page concernée (paiement, reçus, carte, examens…).
/// - Marquage individuel « Marquer comme lu » et « Tout marquer comme lu ».
/// - L'état lu / non lu est enregistré dans Supabase (conservé après
///   actualisation et reconnexion).
class StudentNotificationsPage extends StatefulWidget {
  const StudentNotificationsPage({super.key});

  @override
  State<StudentNotificationsPage> createState() =>
      _StudentNotificationsPageState();
}

class _StudentNotificationsPageState extends State<StudentNotificationsPage> {
  late Future<List<Map<String, dynamic>>> _future =
      NotificationRepository.getNotifications();

  bool _busy = false;

  void _refresh() {
    setState(() {
      _future = NotificationRepository.getNotifications();
    });
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Action impossible : ${error.toString().replaceFirst('Exception: ', '')}',
        ),
      ),
    );
  }

  Future<void> _markRead(Map<String, dynamic> notification) async {
    if (notification['is_read'] == true) return;
    try {
      await NotificationRepository.markAsRead([notification['id'].toString()]);
      _refresh();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _open(Map<String, dynamic> notification) async {
    if (notification['is_read'] != true) {
      try {
        await NotificationRepository.markAsRead(
          [notification['id'].toString()],
        );
      } catch (error) {
        debugPrint('Notifications : marquage « lu » impossible ($error).');
      }
    }

    final destination = NotificationRepository.destinationFor(notification);

    if (!mounted) return;

    if (destination == null) {
      _refresh();
      return;
    }

    await context.push(destination);

    if (mounted) _refresh();
  }

  Future<void> _markAllRead() async {
    setState(() => _busy = true);
    try {
      await NotificationRepository.markAllAsRead();
      _refresh();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
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
          final unreadCount =
              notifications.where((n) => n['is_read'] != true).length;

          return SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (notifications.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            Text(
                              unreadCount == 0
                                  ? 'Toutes les notifications sont lues.'
                                  : '$unreadCount notification(s) non lue(s)',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (unreadCount > 0)
                              OutlinedButton.icon(
                                onPressed: _busy ? null : _markAllRead,
                                icon: const Icon(Icons.done_all_rounded),
                                label: const Text('Tout marquer comme lu'),
                              ),
                          ],
                        ),
                      ),
                    NotificationList(
                      notifications: notifications,
                      onOpen: _open,
                      onMarkRead: _markRead,
                      hasDestination: (n) =>
                          NotificationRepository.destinationFor(n) != null,
                    ),
                  ],
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

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:myprojectflut/core/models/student.dart';

import 'package:myprojectflut/features/student/data/repositories/student_dashboard_repository.dart';

import 'package:myprojectflut/features/student/presentation/widgets/dashboard_stats_grid.dart';
import 'package:myprojectflut/features/student/presentation/widgets/notification_card.dart';
import 'package:myprojectflut/features/student/presentation/widgets/payment_card.dart';
import 'package:myprojectflut/features/student/presentation/widgets/payment_history_card.dart';
import 'package:myprojectflut/features/student/presentation/widgets/quick_actions_card.dart';
import 'package:myprojectflut/features/student/presentation/widgets/student_dashboard_header.dart';
import 'package:myprojectflut/features/student/presentation/widgets/student_identity_card.dart';
import 'package:myprojectflut/features/student/presentation/widgets/student_status_card.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  late Future<Map<String, dynamic>?> _future =
      StudentDashboardRepository.loadDashboard();

  void _refresh() {
    setState(() {
      _future = StudentDashboardRepository.loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Espace Étudiant"),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
              ),
            );
          }

          final dashboard = snapshot.data;

          if (dashboard == null) {
            return const Center(
              child: Text(
                "Aucune donnée trouvée.",
              ),
            );
          }

          final Student student =
              dashboard['student'];

          final payment =
              dashboard['payment'];
          final payments =
              dashboard['payments'];

          final notifications =
              dashboard['notifications'];

          //final studentCard =
              dashboard['studentCard'];

          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 80 : 24,
                vertical: 30,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  StudentDashboardHeader(
                    student: student,
                    nextExamDate:
                        dashboard['nextExamDate'] as DateTime?,
                    nextExamLabel:
                        dashboard['nextExamLabel'] as String?,
                  )
                      .animate()
                      .fadeIn()
                      .slideY(begin: .15),

                  const SizedBox(height: 30),

                  DashboardStatsGrid(
                    examAuthorized: student.examAuthorized,
                    paymentValidated: student.paymentValidated,
                    upcomingExamCount:
                        dashboard['upcomingExamCount'] as int? ?? 0,
                    unreadNotificationCount:
                        dashboard['unreadNotificationCount'] as int? ?? 0,
                  )
                      .animate()
                      .fadeIn(delay: 220.ms)
                      .slideY(begin: .15),

                  const SizedBox(height: 24),

                  const QuickActionsCard()
                      .animate()
                      .fadeIn(delay: 260.ms)
                      .slideY(begin: .15),

                  const SizedBox(height: 30),

                  StudentStatusCard(
                    paymentValidated:
                        student.paymentValidated,
                    examAuthorized:
                        student.examAuthorized,
                  )
                      .animate()
                      .fadeIn(delay: 320.ms)
                      .slideY(begin: .15),

                  const SizedBox(height: 24),

                  PaymentCard(
                    payment: payment,
                  )
                      .animate()
                      .fadeIn(delay: 420.ms)
                      .slideY(begin: .15),

                  const SizedBox(height: 24),

                  StudentIdentityCard(
                    student: student,
                  )
                      .animate()
                      .fadeIn(delay: 550.ms)
                      .slideY(begin: .15),

                  const SizedBox(height: 24),

                  PaymentHistoryCard(
                    student: student,
                    payments: payments,
                  )
                      .animate()
                      .fadeIn(delay: 700.ms)
                      .slideY(begin: .15),

                  const SizedBox(height: 24),

                  NotificationsCard(
                    notifications: notifications,
                  )
                      .animate()
                      .fadeIn(delay: 850.ms)
                      .slideY(begin: .15),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
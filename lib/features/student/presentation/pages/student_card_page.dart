import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:myprojectflut/core/models/student.dart';

import 'package:myprojectflut/features/student/data/repositories/student_card_page_repository.dart';

import '../widgets/student_identity_card.dart';

class StudentCardPage extends StatelessWidget {
  const StudentCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ma carte étudiante"),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: StudentCardPageRepository.load(),
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

          final data = snapshot.data;

          if (data == null) {
            return const Center(
              child: Text(
                "Carte étudiante introuvable.",
              ),
            );
          }

          final Student student = data['student'];
          final card = data['card'];

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    StudentIdentityCard(
                      student: student,
                    )
                        .animate()
                        .fadeIn()
                        .scale(
                          begin: const Offset(.92, .92),
                        ),

                    const SizedBox(height: 24),

                    Card(
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(
                                Icons.qr_code_rounded,
                              ),
                              title: const Text(
                                "QR Code",
                              ),
                              subtitle: Text(
                                card?['qr_code'] ?? "-",
                              ),
                            ),

                            const Divider(),

                            ListTile(
                              leading: const Icon(
                                Icons.calendar_month_rounded,
                              ),
                              title: const Text(
                                "Date d'expiration",
                              ),
                              subtitle: Text(
                                card?['expires_at']
                                        ?.toString() ??
                                    "-",
                              ),
                            ),

                            const Divider(),

                            ListTile(
                              leading: Icon(
                                card?['is_active'] == true
                                    ? Icons.verified
                                    : Icons.cancel,
                                color: card?['is_active'] == true
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              title: const Text(
                                "Statut",
                              ),
                              subtitle: Text(
                                card?['is_active'] == true
                                    ? "Carte active"
                                    : "Carte inactive",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
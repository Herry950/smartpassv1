import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:myprojectflut/core/models/student.dart';

import 'package:myprojectflut/features/student/data/repositories/payment_repository.dart';
import 'package:myprojectflut/features/student/data/repositories/student_repository.dart';

import '../widgets/payment_history_card.dart';

class StudentReceiptsPage extends StatelessWidget {
  const StudentReceiptsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes reçus"),
      ),
      body: FutureBuilder<Student?>(
        future: StudentRepository.getCurrentStudent(),
        builder: (context, studentSnapshot) {
          if (studentSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (studentSnapshot.hasError) {
            return Center(
              child: Text(
                studentSnapshot.error.toString(),
              ),
            );
          }

          final student = studentSnapshot.data;

          if (student == null) {
            return const Center(
              child: Text(
                "Étudiant introuvable.",
              ),
            );
          }

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: PaymentRepository.getPayments(student.id),
            builder: (context, paymentSnapshot) {
              if (paymentSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (paymentSnapshot.hasError) {
                return Center(
                  child: Text(
                    paymentSnapshot.error.toString(),
                  ),
                );
              }

              final payments =
                  paymentSnapshot.data ?? [];

              if (payments.isEmpty) {
                return const Center(
                  child: Text(
                    "Aucun reçu disponible.",
                  ),
                );
              }

              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: PaymentHistoryCard(
                    student: student,
                    payments: payments,
                  )
                      .animate()
                      .fadeIn()
                      .slideY(begin: .15),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
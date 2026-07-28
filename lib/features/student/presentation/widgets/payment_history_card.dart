import 'package:flutter/material.dart';

import 'package:myprojectflut/core/models/student.dart';

import 'payment_history_list.dart';

class PaymentHistoryCard extends StatelessWidget {
  final Student student;
  final List<Map<String, dynamic>> payments;

  const PaymentHistoryCard({
    super.key,
    required this.student,
    required this.payments,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(
                      alpha: .12,
                    ),
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: Colors.indigo,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Text(
                    "Historique des paiements",
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge,
                  ),
                ),

                TextButton(
                  onPressed: () {},
                  child: const Text("Voir tout"),
                ),
              ],
            ),

            const SizedBox(height: 24),

            PaymentHistoryList(
              student: student,
              payments: payments,
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

import 'package:myprojectflut/core/models/student.dart';

import 'payment_history_item.dart';

class PaymentHistoryList extends StatelessWidget {
  final Student student;
  final List<Map<String, dynamic>> payments;

  const PaymentHistoryList({
    super.key,
    required this.student,
    required this.payments,
  });

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            "Aucun paiement trouvé.",
          ),
        ),
      );
    }

    return Column(
      children: payments.map((payment) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: PaymentHistoryItem(
            title: payment['transaction_id'] ?? "Paiement",

            amount:
                "${payment['amount']} ${payment['currency']}",

            method:
                payment['payment_method'] ?? "Inconnu",

            date: payment['paid_at'] == null
                ? ""
                : DateTime.parse(
                    payment['paid_at'],
                  )
                    .toLocal()
                    .toString()
                    .substring(0, 16),

            student: student.fullName,
            matricule: student.matricule,
            faculty: student.faculty,
            department: student.department,
            promotion: student.promotion,

            provider:
                payment['provider'] ??
                payment['payment_method'] ??
                "Inconnu",

            transaction:
                payment['transaction_id'] ?? "",

            receiptNumber:
                payment['receipt_number'] ?? "N/A",

            success:
                payment['status'] == "validated",
          ),
        );
      }).toList(),
    );
  }
}
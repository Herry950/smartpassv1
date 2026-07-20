import 'package:flutter/material.dart';

import 'payment_history_item.dart';

class PaymentHistoryList extends StatelessWidget {
  final List<Map<String, dynamic>> payments;

  const PaymentHistoryList({
    super.key,
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
            title: "Frais d'accès aux examens",
            amount:
                "${payment['amount']} ${payment['currency']}",
            method:
                payment['payment_method'] ?? "Inconnu",
            date: payment['paid_at']
                    ?.toString()
                    .substring(0, 10) ??
                "",
            success:
                payment['status'] == "validated",
          ),
        );
      }).toList(),
    );
  }
}
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class PaymentAmountCard extends StatelessWidget {
  final String amount;
  final String currency;

  const PaymentAmountCard({
    super.key,
    required this.amount,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Montant à payer",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            "$amount $currency",
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 10),

          const Divider(),

          const SizedBox(height: 8),

          const Text(
            "Le montant est fixé par l'administration universitaire.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
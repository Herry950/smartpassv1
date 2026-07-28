import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class PaymentHeader extends StatelessWidget {
  const PaymentHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.white,
            size: 54,
          ),

          const SizedBox(height: 16),

          const Text(
            "ULPGL",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "Paiement sécurisé des frais d'accès aux examens",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .90),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
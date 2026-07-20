import 'package:flutter/material.dart';

import 'package:myprojectflut/app/theme/app_colors.dart';

class PaymentCard extends StatelessWidget {
  final Map<String, dynamic>? payment;

  const PaymentCard({
    super.key,
    required this.payment,
  });

  @override
  Widget build(BuildContext context) {
    final bool validated =
        payment?['status'] == 'validated';

    final amount =
        payment?['amount']?.toString() ?? "--";

    final currency =
        payment?['currency'] ?? "USD";

    final status =
        validated ? "VALIDÉ" : "EN ATTENTE";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .28),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),

              const SizedBox(width: 18),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Paiement des examens",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      "Dernier paiement",
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: validated
                      ? AppColors.success
                      : AppColors.warning,
                  borderRadius:
                      BorderRadius.circular(30),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Montant",
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
              Text(
                "$amount $currency",
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          const Divider(
            color: Colors.white24,
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () {
                // À connecter plus tard au receipt_url
              },
              icon: const Icon(
                Icons.receipt_long_rounded,
              ),
              label: const Text(
                "Voir le reçu",
              ),
            ),
          ),
        ],
      ),
    );
  }
}
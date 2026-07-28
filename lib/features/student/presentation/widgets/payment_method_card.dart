import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class PaymentMethodCard extends StatelessWidget {
  final String selectedMethod;
  final ValueChanged<String> onChanged;

  const PaymentMethodCard({
    super.key,
    required this.selectedMethod,
    required this.onChanged,
  });

  Widget _buildMethod({
    required BuildContext context,
    required String title,
    required IconData icon,
  }) {
    final bool selected = selectedMethod == title;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => onChanged(title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: .08)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected
                  ? AppColors.primary
                  : Colors.grey,
              size: 30,
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.primary
                      : Colors.black87,
                ),
              ),
            ),

            if (selected)
              const Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
          ],
        ),
      ),
    );
  }

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
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            "Choisissez un moyen de paiement",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          _buildMethod(
            context: context,
            title: "Orange Money",
            icon: Icons.phone_android,
          ),

          _buildMethod(
            context: context,
            title: "Airtel Money",
            icon: Icons.sim_card,
          ),

          _buildMethod(
            context: context,
            title: "M-Pesa",
            icon: Icons.account_balance_wallet,
          ),

          _buildMethod(
            context: context,
            title: "Carte bancaire",
            icon: Icons.credit_card,
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class PaymentButton extends StatelessWidget {
  final bool isLoading;
  final bool paymentOpen;
  final VoidCallback onPressed;

  const PaymentButton({
    super.key,
    required this.isLoading,
    required this.paymentOpen,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: (!paymentOpen || isLoading)
            ? null
            : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.lock_outline),
        label: Text(
          !paymentOpen
              ? "Paiements fermés"
              : isLoading
                  ? "Traitement du paiement..."
                  : "Payer maintenant",
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 4,
        ),
      ),
    );
  }
}
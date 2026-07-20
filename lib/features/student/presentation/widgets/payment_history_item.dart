import 'package:flutter/material.dart';

class PaymentHistoryItem extends StatelessWidget {
  final String title;
  final String amount;
  final String method;
  final String date;
  final bool success;

  const PaymentHistoryItem({
    super.key,
    required this.title,
    required this.amount,
    required this.method,
    required this.date,
    this.success = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: success
                ? Colors.green.withValues(alpha: .12)
                : Colors.red.withValues(alpha: .12),
            child: Icon(
              success
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              color: success ? Colors.green : Colors.red,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  method,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  date,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Colors.green,
                ),
              ),

              const SizedBox(height: 10),

              IconButton(
                tooltip: "Télécharger le reçu",
                onPressed: () {},
                icon: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
import 'package:myprojectflut/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

import 'package:myprojectflut/core/models/payment_receipt.dart';
import '../../data/repositories/pdf_receipt_repository.dart';

class PaymentHistoryItem extends StatelessWidget {
  final String title;
  final String amount;
  final String method;
  final String date;

  final String student;
  final String matricule;
  final String faculty;
  final String department;
  final String promotion;

  final String sessionName;
  final String semester;

  final String provider;
  final String transaction;
  final String receiptNumber;

  final String currency;
  final String signature;

  final bool success;

  const PaymentHistoryItem({
    super.key,
    required this.title,
    required this.amount,
    required this.method,
    required this.date,
    required this.student,
    required this.matricule,
    required this.faculty,
    required this.department,
    required this.promotion,
    this.sessionName = 'N/A',
    this.semester = 'N/A',
    required this.provider,
    required this.transaction,
    required this.receiptNumber,
    this.currency = 'USD',
    this.signature = '',
    this.success = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
                ? AppColors.success.withValues(alpha: .12)
                : AppColors.error.withValues(alpha: .12),
            child: Icon(
              success
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              color: success ? AppColors.success : AppColors.error,
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
                  style: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  date,
                  style: TextStyle(
                    color: AppColors.textSecondary,
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
                  color: AppColors.success,
                ),
              ),

              const SizedBox(height: 10),

              IconButton(
                tooltip: "Télécharger le reçu",
                icon: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppColors.error,
                ),
                onPressed: () async {
                  final receipt = PaymentReceipt(
                    paymentId: '',
                    receiptNumber: receiptNumber,
                    student: student,
                    matricule: matricule,
                    faculty: faculty,
                    department: department,
                    promotion: promotion,
                    sessionName: sessionName,
                    semester: semester,
                    amount: amount,
                    currency: currency,
                    method: method,
                    provider: provider,
                    transaction: transaction,
                    date: date,
                    validated: success,
                    signature: signature,
                  );

                  await PdfReceiptRepository.downloadReceipt(
                    receipt: receipt,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
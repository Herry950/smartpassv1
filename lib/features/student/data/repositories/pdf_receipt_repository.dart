import 'package:printing/printing.dart';

import 'package:myprojectflut/core/services/pdf_receipt_service.dart';

class PdfReceiptRepository {
  PdfReceiptRepository._();

  static Future<void> downloadReceipt({
    required String receiptNumber,
    required String student,
    required String matricule,
    required String faculty,
    required String department,
    required String promotion,
    required String amount,
    required String method,
    required String provider,
    required String transaction,
    required String date,
    required bool validated,
  }) async {
    final pdf = await PdfReceiptService.generateReceipt(
      receiptNumber: receiptNumber,
      student: student,
      matricule: matricule,
      faculty: faculty,
      department: department,
      promotion: promotion,
      amount: amount,
      method: method,
      provider: provider,
      transaction: transaction,
      date: date,
      validated: validated,
    );

    await Printing.layoutPdf(
      name: "Recu_$receiptNumber.pdf",
      onLayout: (_) async => pdf,
    );
  }
}
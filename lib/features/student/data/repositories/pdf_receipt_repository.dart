import 'package:printing/printing.dart';

import 'package:myprojectflut/core/models/payment_receipt.dart';
import 'package:myprojectflut/core/services/pdf_receipt_service.dart';

class PdfReceiptRepository {
  PdfReceiptRepository._();

  static Future<void> downloadReceipt({
    required PaymentReceipt receipt,
  }) async {
    final pdf =
        await PdfReceiptService.generateReceipt(
      receipt: receipt,
    );

    await Printing.layoutPdf(
      name:
          "Recu_${receipt.receiptNumber}.pdf",
      onLayout: (_) async => pdf,
    );
  }
}
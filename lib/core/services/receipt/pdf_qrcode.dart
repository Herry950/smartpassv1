import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

pw.Widget buildReceiptQrCode({
  required String receiptNumber,
}) {
  return pw.Center(
    child: pw.Column(
      children: [
        pw.BarcodeWidget(
          barcode: pw.Barcode.qrCode(),
          data: receiptNumber,
          width: 95,
          height: 95,
          color: PdfColors.black,
        ),

        pw.SizedBox(height: 8),

        pw.Text(
          "Scanner pour vérifier l'authenticité",
          style: const pw.TextStyle(
            fontSize: 10,
          ),
        ),

        pw.SizedBox(height: 4),

        pw.Text(
          receiptNumber,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
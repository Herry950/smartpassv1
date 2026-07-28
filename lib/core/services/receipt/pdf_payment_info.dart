import 'package:pdf/widgets.dart' as pw;

import 'pdf_styles.dart';

pw.Widget buildPaymentInfo({
  required String amount,
  required String method,
  required String provider,
  required String transaction,
  required String date,
}) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(16),
    decoration: PdfStyles.boxDecoration,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          "Informations du paiement",
          style: PdfStyles.subTitle,
        ),

        pw.SizedBox(height: 12),

        pw.Text(
          "Montant : $amount",
          style: PdfStyles.body,
        ),

        pw.SizedBox(height: PdfStyles.itemSpacing),

        pw.Text(
          "Méthode : $method",
          style: PdfStyles.body,
        ),

        pw.SizedBox(height: PdfStyles.itemSpacing),

        pw.Text(
          "Fournisseur : $provider",
          style: PdfStyles.body,
        ),

        pw.SizedBox(height: PdfStyles.itemSpacing),

        pw.Text(
          "Transaction : $transaction",
          style: PdfStyles.body,
        ),

        pw.SizedBox(height: PdfStyles.itemSpacing),

        pw.Text(
          "Date : $date",
          style: PdfStyles.body,
        ),
      ],
    ),
  );
}
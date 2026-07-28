import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'pdf_styles.dart';

pw.Widget buildValidationSection({
  required bool validated,
}) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(16),
    decoration: PdfStyles.boxDecoration,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          "Validation",
          style: PdfStyles.subTitle,
        ),

        pw.SizedBox(height: 15),

        pw.Container(
          padding: const pw.EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          decoration: pw.BoxDecoration(
            color: validated
                ? PdfColors.green100
                : PdfColors.red100,
            borderRadius:
                pw.BorderRadius.circular(8),
            border: pw.Border.all(
              color: validated
                  ? PdfColors.green700
                  : PdfColors.red700,
            ),
          ),
          child: pw.Row(
            children: [
              pw.Text(
                validated
                    ? "✓ Paiement validé"
                    : "✗ Paiement non validé",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: validated
                      ? PdfColors.green900
                      : PdfColors.red900,
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 20),

        pw.Text(
          "Ce reçu est généré automatiquement par SmartPass.",
          style: PdfStyles.small,
        ),

        pw.SizedBox(height: 8),

        pw.Text(
          "Toute modification rend ce document invalide.",
          style: PdfStyles.small,
        ),
      ],
    ),
  );
}
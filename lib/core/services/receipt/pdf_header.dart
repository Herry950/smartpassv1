import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'pdf_styles.dart';

pw.Widget buildPdfHeader({
  required String receiptNumber,
  pw.MemoryImage? ulpglLogo,
  pw.MemoryImage? smartPassLogo,
}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Row(
        mainAxisAlignment:
            pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment:
            pw.CrossAxisAlignment.start,
        children: [
          ulpglLogo != null
              ? pw.Image(
                  ulpglLogo,
                  width: 70,
                  height: 70,
                )
              : pw.Container(
                  width: 70,
                  height: 70,
                ),

          pw.Expanded(
            child: pw.Column(
              children: [
                pw.Text(
                  "Université Libre des Pays des Grands Lacs",
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 17,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 4),

                pw.Text(
                  "Section Facultaire",
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(
                    fontSize: 12,
                  ),
                ),

                pw.SizedBox(height: 12),

                pw.Text(
                  "REÇU OFFICIEL DE PAIEMENT",
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    color: PdfColors.green800,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                pw.SizedBox(height: 6),

                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius:
                        pw.BorderRadius.circular(20),
                  ),
                  child: pw.Text(
                    "N° $receiptNumber",
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          smartPassLogo != null
              ? pw.Image(
                  smartPassLogo,
                  width: 70,
                  height: 70,
                )
              : pw.Container(
                  width: 70,
                  height: 70,
                ),
        ],
      ),

      pw.SizedBox(
        height: PdfStyles.sectionSpacing,
      ),

      pw.Divider(
        thickness: 1.2,
        color: PdfColors.grey600,
      ),
    ],
  );
}
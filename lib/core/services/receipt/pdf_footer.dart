import 'package:pdf/pdf.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

pw.Widget buildPdfFooter(pw.Context context) {
  return pw.Column(
    children: [
      pw.Divider(
        color: PdfColors.grey400,
      ),

      pw.SizedBox(height: 6),

      pw.Row(
        mainAxisAlignment:
            pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            "Service Section-Facultaire ULPGL",
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey700,
            ),
          ),

          pw.Text(
            "Page ${context.pageNumber} / ${context.pagesCount}",
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),

      pw.SizedBox(height: 4),

      pw.Center(
        child: pw.Text(
          "SmartPass © 2026 - Tous droits réservés",
          style: const pw.TextStyle(
            fontSize: 8,
            color: PdfColors.grey600,
          ),
        ),
      ),
    ],
  );
}
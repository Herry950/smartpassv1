import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'pdf_styles.dart';
import 'pdf_watermark.dart';

pw.PageTheme buildPdfPageTheme({
  required pw.MemoryImage watermark,
}) {
  return pw.PageTheme(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(
      PdfStyles.pagePadding,
    ),

    buildBackground: (context) {
      return pw.FullPage(
        ignoreMargins: true,
        child: buildPdfWatermark(
          logo: watermark,
        ),
      );
    },
  );
}
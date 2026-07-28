import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

pw.Widget buildPdfWatermark({
  required pw.MemoryImage logo,
}) {
  return pw.Center(
    child: pw.Opacity(
      opacity: 0.08,
      child: pw.Image(
        logo,
        width: 260,
        height: 260,
        fit: pw.BoxFit.contain,
      ),
    ),
  );
}
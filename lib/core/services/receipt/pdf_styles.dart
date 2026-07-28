import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfStyles {
  PdfStyles._();

  // =========================
  // Couleurs SmartPass
  // =========================

  static const PdfColor primary =
      PdfColor.fromInt(0xFF556B2F);

  static const PdfColor secondary =
      PdfColor.fromInt(0xFF6B8E23);

  static const PdfColor success =
      PdfColors.green700;

  static const PdfColor danger =
      PdfColors.red700;

  static const PdfColor warning =
      PdfColors.orange700;

  static const PdfColor grey =
      PdfColors.grey700;

  static const PdfColor lightGrey =
      PdfColors.grey300;

  // =========================
  // Titres
  // =========================

  static final title = pw.TextStyle(
    fontSize: 24,
    fontWeight: pw.FontWeight.bold,
    color: primary,
  );

  static final subTitle = pw.TextStyle(
    fontSize: 16,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.black,
  );

  // =========================
  // Texte
  // =========================

  static const body = pw.TextStyle(
    fontSize: 12,
  );

  static final bodyBold = pw.TextStyle(
    fontSize: 12,
    fontWeight: pw.FontWeight.bold,
  );

  static const small = pw.TextStyle(
    fontSize: 10,
    color: grey,
  );

  // =========================
  // Espacements
  // =========================

  static const double pagePadding = 30;

  static const double sectionSpacing = 20;

  static const double itemSpacing = 8;

  // =========================
  // Bordures
  // =========================

  static final boxDecoration = pw.BoxDecoration(
    border: pw.Border.all(
      color: lightGrey,
      width: 1,
    ),
    borderRadius: pw.BorderRadius.circular(8),
  );
}
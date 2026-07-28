import 'package:pdf/widgets.dart' as pw;

import 'pdf_styles.dart';

pw.Widget buildStudentInfo({
  required String fullName,
  required String matricule,
  required String faculty,
  required String department,
  required String promotion,
}) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(16),
    decoration: PdfStyles.boxDecoration,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          "Informations de l'étudiant",
          style: PdfStyles.subTitle,
        ),

        pw.SizedBox(height: 12),

        pw.Text(
          "Nom : $fullName",
          style: PdfStyles.body,
        ),

        pw.SizedBox(height: PdfStyles.itemSpacing),

        pw.Text(
          "Matricule : $matricule",
          style: PdfStyles.body,
        ),

        pw.SizedBox(height: PdfStyles.itemSpacing),

        pw.Text(
          "Faculté : $faculty",
          style: PdfStyles.body,
        ),

        pw.SizedBox(height: PdfStyles.itemSpacing),

        pw.Text(
          "Département : $department",
          style: PdfStyles.body,
        ),

        pw.SizedBox(height: PdfStyles.itemSpacing),

        pw.Text(
          "Promotion : $promotion",
          style: PdfStyles.body,
        ),
      ],
    ),
  );
}
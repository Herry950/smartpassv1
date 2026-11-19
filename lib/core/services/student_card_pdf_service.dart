import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/student.dart';
import 'student_card_qr.dart';

/// Carte étudiante physique imprimable (format CR80 : 85,6 × 54 mm),
/// avec les mêmes informations et la même identité visuelle que la
/// carte numérique. Toutes les données proviennent de Supabase.
class StudentCardPdfService {
  StudentCardPdfService._();

  static const PdfColor _navy = PdfColor.fromInt(0xFF071A4C);
  static const PdfColor _navyLight = PdfColor.fromInt(0xFF0B2261);
  static const PdfColor _accent = PdfColor.fromInt(0xFF2563EB);
  static const PdfColor _gold = PdfColor.fromInt(0xFFE0C15A);
  static const PdfColor _amber = PdfColor.fromInt(0xFFFFC107);
  static const PdfColor _white70 = PdfColor(1, 1, 1, .75);

  static String cardNumber(Student student) {
    final parts = student.academicYear.split(RegExp(r'[-/]'));
    final endYear = parts.isNotEmpty ? parts.last.trim() : '';
    return endYear.isEmpty
        ? 'SP-${student.matricule}'
        : 'SP-$endYear-${student.matricule}';
  }

  static String _initials(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2);
    final letters = parts.map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  /// Génère le PDF d'une ou plusieurs cartes (une carte par page A4).
  static Future<Uint8List> generate(List<Student> students) async {
    final pdf = pw.Document(
      title: 'Cartes étudiantes SmartPass',
      author: 'ULPGL SmartPass',
    );

    final ulpglLogo = pw.MemoryImage(
      (await rootBundle.load('assets/images/ulpgl_logo.png'))
          .buffer
          .asUint8List(),
    );
    final smartPassLogo = pw.MemoryImage(
      (await rootBundle.load('assets/images/smartpass_logo.png'))
          .buffer
          .asUint8List(),
    );
    for (final student in students) {
      // Sans photo enregistrée : emplacement avec les initiales
      // (l'ancien fichier student_placeholder.png est vide et faisait
      // échouer toute génération de carte).
      pw.ImageProvider? photo;

      final photoUrl = student.photoUrl;
      if (photoUrl != null && photoUrl.isNotEmpty) {
        try {
          photo = await networkImage(photoUrl);
        } catch (error) {
          debugPrint('Photo indisponible pour la carte : $error');
        }
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'Carte étudiante SmartPass - ${student.fullName}',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Imprimer à 100 % (taille réelle), puis découper '
                'le recto et le verso.',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Text('RECTO', style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 4),
              _front(student, photo, ulpglLogo, smartPassLogo),
              pw.SizedBox(height: 24),
              pw.Text('VERSO', style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 4),
              _back(student, smartPassLogo),
            ],
          ),
        ),
      );
    }

    return pdf.save();
  }

  /// Ouvre la boîte de dialogue d'impression du navigateur / système.
  static Future<void> printCards(List<Student> students) async {
    await Printing.layoutPdf(
      name: students.length == 1
          ? 'carte_${students.first.matricule}.pdf'
          : 'cartes_smartpass.pdf',
      onLayout: (_) => generate(students),
    );
  }

  /// Télécharge / partage le PDF.
  static Future<void> downloadCards(List<Student> students) async {
    final bytes = await generate(students);
    await Printing.sharePdf(
      bytes: bytes,
      filename: students.length == 1
          ? 'carte_${students.first.matricule}.pdf'
          : 'cartes_smartpass.pdf',
    );
  }

  static pw.Widget _cardFrame(pw.Widget child) {
    return pw.Container(
      width: 85.6 * PdfPageFormat.mm,
      height: 54 * PdfPageFormat.mm,
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(8),
        gradient: const pw.LinearGradient(
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
          colors: [_navy, _navyLight, _accent],
        ),
      ),
      child: pw.ClipRRect(
        horizontalRadius: 8,
        verticalRadius: 8,
        child: child,
      ),
    );
  }

  static pw.Widget _front(
    Student student,
    pw.ImageProvider? photo,
    pw.ImageProvider ulpglLogo,
    pw.ImageProvider smartPassLogo,
  ) {
    const label = pw.TextStyle(fontSize: 5.6, color: _white70);
    const value = pw.TextStyle(fontSize: 5.6, color: PdfColors.white);

    pw.Widget info(String name, String data) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 1.2),
          child: pw.RichText(
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
            text: pw.TextSpan(
              children: [
                pw.TextSpan(text: '$name : ', style: label),
                pw.TextSpan(text: data, style: value),
              ],
            ),
          ),
        );

    return _cardFrame(
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(width: 4, color: _gold),
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(6, 5, 6, 5),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // En-tête
                  pw.Row(
                    children: [
                      pw.Image(ulpglLogo, width: 14, height: 14),
                      pw.SizedBox(width: 4),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'UNIVERSITÉ LIBRE DES PAYS DES GRANDS LACS',
                              style: pw.TextStyle(
                                fontSize: 5,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                            pw.Text(
                              'Carte étudiante - SmartPass',
                              style: const pw.TextStyle(
                                fontSize: 5,
                                color: _white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Image(smartPassLogo, width: 14, height: 14),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Expanded(
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Photo + promotion
                        pw.Column(
                          children: [
                            pw.Container(
                              width: 15 * PdfPageFormat.mm,
                              height: 19 * PdfPageFormat.mm,
                              decoration: pw.BoxDecoration(
                                color: PdfColors.white,
                                borderRadius: pw.BorderRadius.circular(3),
                              ),
                              child: pw.ClipRRect(
                                horizontalRadius: 3,
                                verticalRadius: 3,
                                child: photo != null
                                    ? pw.Image(photo, fit: pw.BoxFit.cover)
                                    : pw.Center(
                                        child: pw.Text(
                                          _initials(student.fullName),
                                          style: pw.TextStyle(
                                            fontSize: 14,
                                            fontWeight: pw.FontWeight.bold,
                                            color: _navy,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            pw.SizedBox(height: 3),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1.5,
                              ),
                              decoration: pw.BoxDecoration(
                                color: const PdfColor(1, 1, 1, .2),
                                borderRadius: pw.BorderRadius.circular(6),
                              ),
                              child: pw.Text(
                                student.promotion,
                                style: pw.TextStyle(
                                  fontSize: 6,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(width: 5),
                        // Identité
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                student.fullName,
                                maxLines: 2,
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.white,
                                ),
                              ),
                              pw.SizedBox(height: 1.5),
                              pw.Text(
                                'N° ${cardNumber(student)}',
                                style: pw.TextStyle(
                                  fontSize: 6.2,
                                  fontWeight: pw.FontWeight.bold,
                                  color: _amber,
                                ),
                              ),
                              pw.SizedBox(height: 3),
                              info('Matricule', student.matricule),
                              info('Faculté', student.faculty),
                              if (student.department.trim().isNotEmpty)
                                info('Département', student.department),
                              info('Année', student.academicYear),
                              if (student.expiryDate != null)
                                info(
                                  'Expire le',
                                  _date(student.expiryDate!),
                                ),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 4),
                        // QR code (même contenu que la carte numérique)
                        pw.Container(
                          padding: const pw.EdgeInsets.all(2),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(3),
                          ),
                          child: pw.BarcodeWidget(
                            barcode: pw.Barcode.qrCode(),
                            data: StudentCardQrData.encode(
                              studentId: student.id,
                              matricule: student.matricule,
                              academicYear: student.academicYear,
                            ),
                            width: 19 * PdfPageFormat.mm,
                            height: 19 * PdfPageFormat.mm,
                            color: PdfColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _back(Student student, pw.ImageProvider smartPassLogo) {
    const text = pw.TextStyle(fontSize: 5.6, color: _white70);

    return _cardFrame(
      pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                pw.Image(smartPassLogo, width: 16, height: 16),
                pw.SizedBox(width: 5),
                pw.Text(
                  'SmartPass - ULPGL Goma',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              "Le QR code permet à l'assistant de retrouver l'étudiant "
              "dans SmartPass. L'accès aux examens dépend de la "
              'validation du paiement de la session, vérifiée en ligne.',
              style: text,
            ),
            pw.Spacer(),
            pw.Container(height: 8, color: PdfColors.black),
            pw.SizedBox(height: 4),
            pw.Text(
              'Titulaire : ${student.fullName} - ${student.matricule}',
              style: const pw.TextStyle(
                fontSize: 5.6,
                color: PdfColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

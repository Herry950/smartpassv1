import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'receipt/pdf_footer.dart';
import 'receipt/pdf_header.dart';
import 'receipt/pdf_page_theme.dart';
import 'receipt/pdf_payment_info.dart';
import 'receipt/pdf_qrcode.dart';
import 'receipt/pdf_stamp.dart';
import 'receipt/pdf_student_info.dart';
import 'receipt/pdf_styles.dart';
import 'receipt/pdf_validation.dart';

class PdfReceiptService {
  PdfReceiptService._();

  static Future<Uint8List> generateReceipt({
    required String receiptNumber,
    required String student,
    required String matricule,
    required String faculty,
    required String department,
    required String promotion,
    required String amount,
    required String method,
    required String provider,
    required String transaction,
    required String date,
    required bool validated,
  }) async {
    final pdf = pw.Document();

    final ulpglLogo = pw.MemoryImage(
      (await rootBundle
              .load('assets/images/ulpgl_logo.png'))
          .buffer
          .asUint8List(),
    );

    final smartPassLogo = pw.MemoryImage(
      (await rootBundle
              .load('assets/images/smartpass_logo.png'))
          .buffer
          .asUint8List(),
    );

    final officialStamp = await buildOfficialStamp();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: buildPdfPageTheme(
          watermark: smartPassLogo,
        ),

        build: (context) => [
          /// ===========================
          /// EN-TÊTE
          /// ===========================
          buildPdfHeader(
            receiptNumber: receiptNumber,
            ulpglLogo: ulpglLogo,
            smartPassLogo: smartPassLogo,
          ),

          pw.SizedBox(height: 18),

          /// ===========================
          /// INFORMATIONS ÉTUDIANT
          /// ===========================
          buildStudentInfo(
            fullName: student,
            matricule: matricule,
            faculty: faculty,
            department: department,
            promotion: promotion,
          ),

          pw.SizedBox(height: 24),

          /// ===========================
          /// INFORMATIONS PAIEMENT
          /// ===========================
          buildPaymentInfo(
            amount: amount,
            method: method,
            provider: provider,
            transaction: transaction,
            date: date,
          ),

          pw.SizedBox(height: 24),

          /// ===========================
          /// VALIDATION
          /// ===========================
          buildValidationSection(
            validated: validated,
          ),

          pw.SizedBox(height: 28),

          /// ===========================
          /// QR CODE
          /// ===========================
          buildReceiptQrCode(
            receiptNumber: receiptNumber,
          ),

          pw.SizedBox(height: 28),

          /// ===========================
          /// INFORMATIONS IMPORTANTES
          /// ===========================
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: PdfColors.grey600,
              ),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment:
                  pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "Informations importantes",
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                pw.SizedBox(height: 8),

                pw.Bullet(
                  text:
                      "Ce reçu est généré automatiquement par SmartPass.",
                ),

                pw.Bullet(
                  text:
                      "Le numéro de reçu est unique et ne peut être modifié.",
                ),

                pw.Bullet(
                  text:
                      "Conservez ce document comme preuve officielle de paiement.",
                ),

                pw.Bullet(
                  text:
                      "Toute falsification de ce reçu est passible de sanctions disciplinaires.",
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 16),

          /// ===========================
          /// CACHET OFFICIEL
          /// ===========================
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: officialStamp,
          ),
        ],

        footer: (context) => buildPdfFooter(context),
      ),
    );

    return pdf.save();
  }
}
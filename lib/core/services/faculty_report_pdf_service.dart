import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Données d'un rapport de session (faculté de l'administrateur connecté).
class SessionReportData {
  SessionReportData({
    required this.facultyName,
    required this.session,
    required this.payments,
    required this.targetedPromotions,
    this.carriedOverPayments = const [],
  });

  final String facultyName;
  final Map<String, dynamic> session;

  /// Paiements VALIDÉS uniquement (en attente / annulés exclus).
  final List<Map<String, dynamic>> payments;

  /// Paiements validés d'une session archivée remplacée par celle-ci :
  /// même obligation, droit d'accès reconnu (non comptés dans les
  /// montants de cette session, déjà comptabilisés dans leur session).
  final List<Map<String, dynamic>> carriedOverPayments;

  /// Promotions ciblées par les examens programmés de la session.
  final Set<String> targetedPromotions;

  String get sessionLabel =>
      '${session['session_name']} - ${session['semester']}';

  String get yearName {
    final year = session['academic_years'];
    return year is Map ? (year['name'] ?? '').toString() : '';
  }

  String get currency => (session['currency'] ?? 'USD').toString();

  static bool isCash(Map<String, dynamic> p) =>
      p['payment_channel'] == 'manual' || p['payment_method'] == 'Espèces';

  Map<String, dynamic> studentOf(Map<String, dynamic> p) {
    final s = p['students'];
    return s is Map ? Map<String, dynamic>.from(s) : const {};
  }

  /// Règle d'accès : paiement validé de la session, même année académique
  /// et promotion ciblée par un examen programmé de la session.
  String accessStatus(Map<String, dynamic> p) {
    final student = studentOf(p);
    if ((student['academic_year'] ?? '').toString().trim() != yearName.trim()) {
      return 'Non autorisé (année académique différente)';
    }
    if (targetedPromotions.isEmpty) {
      return 'Autorisé (aucun examen encore programmé)';
    }
    final promotion = (student['promotion'] ?? '').toString().toUpperCase();
    return targetedPromotions.contains(promotion)
        ? 'Autorisé'
        : 'Non concerné par les examens programmés';
  }
}

/// Rapports PDF facultaires : paiements et étudiants autorisés.
/// Lecture filtrée par RLS (faculté de l'administrateur uniquement).
class FacultyReportPdfService {
  FacultyReportPdfService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static final _money = NumberFormat('#,##0.00', 'fr_FR');
  static final _dateTime = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

  Future<SessionReportData> loadSession({
    required String sessionId,
    required String facultyName,
  }) async {
    final results = await Future.wait([
      _client
          .from('exam_sessions')
          .select(
            'id, session_name, semester, fee_amount, currency, payment_open, '
            'status, academic_years(name)',
          )
          .eq('id', sessionId)
          .single(),
      _client
          .from('payments')
          .select(
            'id, amount, currency, payment_method, payment_channel, '
            'receipt_number, paid_at, cash_remitted, '
            'students(full_name, matricule, promotion, department, academic_year)',
          )
          .eq('exam_session_id', sessionId)
          .eq('status', 'validated')
          .order('paid_at', ascending: true),
      _client
          .from('exam_schedule_items')
          .select('id, exam_schedule_targets(promotion_code)')
          .eq('exam_session_id', sessionId),
      // Sessions de la faculté (colonnes complètes : replaced_by_session_id).
      _client.from('exam_sessions').select('*'),
    ]);

    final replacedIds = List<Map<String, dynamic>>.from(results[3] as List)
        .where((s) => s['replaced_by_session_id']?.toString() == sessionId)
        .map((s) => s['id'].toString())
        .toList();

    final carried = replacedIds.isEmpty
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(
            await _client
                .from('payments')
                .select(
                  'id, amount, currency, payment_method, payment_channel, '
                  'receipt_number, paid_at, cash_remitted, '
                  'students(full_name, matricule, promotion, department, academic_year)',
                )
                .inFilter('exam_session_id', replacedIds)
                .eq('status', 'validated'),
          );

    final targets = <String>{};
    for (final item in List<Map<String, dynamic>>.from(results[2] as List)) {
      for (final t in (item['exam_schedule_targets'] as List? ?? const [])) {
        if (t is Map && t['promotion_code'] != null) {
          targets.add(t['promotion_code'].toString().toUpperCase());
        }
      }
    }

    return SessionReportData(
      facultyName: facultyName,
      session: Map<String, dynamic>.from(results[0] as Map),
      payments: List<Map<String, dynamic>>.from(results[1] as List),
      targetedPromotions: targets,
      carriedOverPayments: carried,
    );
  }

  Future<pw.MemoryImage> _logo() async => pw.MemoryImage(
        (await rootBundle.load('assets/images/ulpgl_logo.png'))
            .buffer
            .asUint8List(),
      );

  pw.Widget _header(
    SessionReportData data,
    String title,
    pw.MemoryImage logo,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Image(logo, width: 42, height: 42),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'UNIVERSITE LIBRE DES PAYS DES GRANDS LACS - SmartPass',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                  pw.Text(
                    title,
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey500),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Faculté : ${data.facultyName}'),
              pw.Text('Session : ${data.sessionLabel}'),
              pw.Text('Année académique : ${data.yearName}'),
              pw.Text(
                'Frais de la session : ${_money.format(num.tryParse('${data.session['fee_amount']}') ?? 0)} ${data.currency}',
              ),
              pw.Text('Généré le : ${_dateTime.format(DateTime.now())}'),
            ],
          ),
        ),
        pw.SizedBox(height: 14),
      ],
    );
  }

  pw.Widget _footer(pw.Context context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Page ${context.pageNumber} / ${context.pagesCount} - '
          'Document généré par SmartPass à partir des données enregistrées.',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      );

  /// Rapport des paiements validés (en ligne et espèces).
  Future<Uint8List> buildPaymentsReport(SessionReportData data) async {
    final logo = await _logo();
    final doc = pw.Document(title: 'Rapport des paiements - ${data.sessionLabel}');

    num total(Iterable<Map<String, dynamic>> list) =>
        list.fold<num>(0, (sum, p) => sum + (num.tryParse('${p['amount']}') ?? 0));

    final online = data.payments.where((p) => !SessionReportData.isCash(p)).toList();
    final cash = data.payments.where(SessionReportData.isCash).toList();
    final cashRemitted = cash.where((p) => p['cash_remitted'] == true).toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: _footer,
        build: (context) => [
          _header(data, 'Rapport des paiements validés', logo),
          pw.Text('Synthèse', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['Mode de paiement', 'Nombre', 'Montant (${data.currency})'],
            data: [
              ['En ligne (Flutterwave)', '${online.length}', _money.format(total(online))],
              ['Espèces (assistants)', '${cash.length}', _money.format(total(cash))],
              ['   dont espèces remises', '${cashRemitted.length}', _money.format(total(cashRemitted))],
              ['TOTAL VALIDÉ', '${data.payments.length}', _money.format(total(data.payments))],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF071A4C)),
            cellAlignments: {1: pw.Alignment.centerRight, 2: pw.Alignment.centerRight},
          ),
          pw.SizedBox(height: 16),
          pw.Text('Détail des paiements validés', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          if (data.payments.isEmpty)
            pw.Text('Aucun paiement validé pour cette session.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['N°', 'Matricule', 'Étudiant', 'Promotion', 'Mode', 'Reçu', 'Date', 'Montant'],
              data: [
                for (var i = 0; i < data.payments.length; i++)
                  () {
                    final p = data.payments[i];
                    final s = data.studentOf(p);
                    final paidAt = DateTime.tryParse('${p['paid_at']}')?.toLocal();
                    return [
                      '${i + 1}',
                      '${s['matricule'] ?? ''}',
                      '${s['full_name'] ?? ''}',
                      '${s['promotion'] ?? ''}',
                      SessionReportData.isCash(p) ? 'Espèces' : 'En ligne',
                      '${p['receipt_number'] ?? ''}',
                      paidAt == null ? '' : _dateTime.format(paidAt),
                      _money.format(num.tryParse('${p['amount']}') ?? 0),
                    ];
                  }(),
              ],
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF071A4C)),
              cellAlignments: {7: pw.Alignment.centerRight},
            ),
        ],
      ),
    );

    return doc.save();
  }

  /// Rapport des étudiants autorisés (paiement validé et règles d'accès).
  Future<Uint8List> buildAuthorizedStudentsReport(SessionReportData data) async {
    final logo = await _logo();
    final doc = pw.Document(title: 'Étudiants autorisés - ${data.sessionLabel}');

    final rows = [...data.payments, ...data.carriedOverPayments]
      ..sort((a, b) {
        final sa = data.studentOf(a);
        final sb = data.studentOf(b);
        final byPromo = '${sa['promotion']}'.compareTo('${sb['promotion']}');
        return byPromo != 0 ? byPromo : '${sa['full_name']}'.compareTo('${sb['full_name']}');
      });

    final authorized = rows.where((p) => data.accessStatus(p).startsWith('Autorisé')).toList();

    Map<String, int> countBy(String key) {
      final result = <String, int>{};
      for (final p in authorized) {
        final value = '${data.studentOf(p)[key] ?? ''}'.trim();
        final label = value.isEmpty ? '(non précisé)' : value;
        result[label] = (result[label] ?? 0) + 1;
      }
      return Map.fromEntries(result.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
    }

    final byPromotion = countBy('promotion');
    final byDepartment = countBy('department');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: _footer,
        build: (context) => [
          _header(data, 'Liste des étudiants autorisés', logo),
          pw.Text(
            'Règle appliquée : paiement de la session validé par le serveur, '
            'même année académique, promotion ciblée par les examens programmés '
            '(${data.targetedPromotions.isEmpty ? 'aucun examen programmé' : data.targetedPromotions.join(', ')}).',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Étudiants autorisés : ${authorized.length} / ${rows.length} paiement(s) validé(s)',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.TableHelper.fromTextArray(
                  headers: ['Promotion', 'Autorisés'],
                  data: byPromotion.entries.map((e) => [e.key, '${e.value}']).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF071A4C)),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.TableHelper.fromTextArray(
                  headers: ['Département', 'Autorisés'],
                  data: byDepartment.entries.map((e) => [e.key, '${e.value}']).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF071A4C)),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          if (rows.isEmpty)
            pw.Text('Aucun paiement validé pour cette session.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['N°', 'Matricule', 'Étudiant', 'Promotion', 'Département', 'Statut d\'autorisation'],
              data: [
                for (var i = 0; i < rows.length; i++)
                  () {
                    final s = data.studentOf(rows[i]);
                    final carried = data.carriedOverPayments.contains(rows[i]);
                    return [
                      '${i + 1}',
                      '${s['matricule'] ?? ''}',
                      '${s['full_name'] ?? ''}',
                      '${s['promotion'] ?? ''}',
                      '${s['department'] ?? ''}',
                      carried
                          ? '${data.accessStatus(rows[i])} (payé via session remplacée, reçu ${rows[i]['receipt_number'] ?? ''})'
                          : data.accessStatus(rows[i]),
                    ];
                  }(),
              ],
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF071A4C)),
            ),
        ],
      ),
    );

    return doc.save();
  }

  /// Téléchargement (sur le Web : fichier PDF téléchargé par le navigateur).
  static Future<void> download(Uint8List bytes, String filename) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }
}

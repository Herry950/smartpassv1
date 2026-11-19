import 'package:myprojectflut/shared/widgets/home_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/admin_context_service.dart';
import '../../../../core/services/faculty_report_pdf_service.dart';

/// Rapports et contrôle de la faculté : paiements validés par session
/// et journal des contrôles d'accès. Lecture seule, filtrée par RLS.
class FacultyReportsPage extends StatefulWidget {
  const FacultyReportsPage({super.key});

  @override
  State<FacultyReportsPage> createState() => _FacultyReportsPageState();
}

class _FacultyReportsPageState extends State<FacultyReportsPage> {
  final SupabaseClient _client = Supabase.instance.client;

  bool _isLoading = true;
  String? _error;

  AdminContext? _context;
  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _accessLogs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final adminContext = await AdminContextService(client: _client).load();
      final facultyId = adminContext.facultyId;

      if (facultyId == null) {
        throw Exception(
          'Ce module est réservé aux administrateurs facultaires.',
        );
      }

      final results = await Future.wait([
        _client
            .from('exam_sessions')
            .select('id, session_name, semester, academic_years(name)')
            .eq('faculty_id', facultyId)
            .order('created_at', ascending: false),
        _client
            .from('payments')
            .select(
              'id, amount, currency, payment_method, payment_channel, '
              'cash_remitted, exam_session_id, '
              'exam_sessions!inner(faculty_id)',
            )
            .eq('status', 'validated')
            .eq('exam_sessions.faculty_id', facultyId),
        _client
            .from('access_logs')
            .select(
              'id, access_granted, reason, checked_at, exam_session_id, '
              'students(full_name, matricule), assistants(full_name), '
              'exam_sessions!inner(session_name, faculty_id)',
            )
            .eq('exam_sessions.faculty_id', facultyId)
            .order('checked_at', ascending: false)
            .limit(100),
      ]);

      if (!mounted) return;

      setState(() {
        _context = adminContext;
        _sessions = List<Map<String, dynamic>>.from(results[0]);
        _payments = List<Map<String, dynamic>>.from(results[1]);
        _accessLogs = List<Map<String, dynamic>>.from(results[2]);
        _isLoading = false;
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les rapports : ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  final Set<String> _generating = {};

  /// Génère et télécharge un rapport PDF pour la session.
  Future<void> _downloadReport(
    Map<String, dynamic> session, {
    required bool authorizedStudents,
  }) async {
    final sessionId = session['id'].toString();
    final key = '$sessionId:$authorizedStudents';
    if (_generating.contains(key)) return;

    setState(() => _generating.add(key));

    try {
      final service = FacultyReportPdfService(client: _client);
      final data = await service.loadSession(
        sessionId: sessionId,
        facultyName: _context?.facultyName ?? 'Faculté',
      );

      final bytes = authorizedStudents
          ? await service.buildAuthorizedStudentsReport(data)
          : await service.buildPaymentsReport(data);

      final slug = '${session['session_name']}_${session['semester']}'
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_');

      await FacultyReportPdfService.download(
        bytes,
        authorizedStudents
            ? 'etudiants_autorises_$slug.pdf'
            : 'rapport_paiements_$slug.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Génération du rapport impossible : $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _generating.remove(key));
    }
  }

  bool _isCash(Map<String, dynamic> payment) =>
      payment['payment_channel'] == 'manual' ||
      payment['payment_method'] == 'Espèces';

  String _formatAmount(num value, String currency) =>
      '${NumberFormat('#,##0.00', 'fr_FR').format(value)} $currency';

  String _formatDate(dynamic raw) {
    final date = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    if (date == null) return '—';
    return DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Rapports et Contrôle',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          const HomeButton(),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _isLoading ? null : _loadData,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final granted = _accessLogs.where((l) => l['access_granted'] == true).length;
    final denied = _accessLogs.length - granted;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 40),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _kpi(
                        'Paiements validés',
                        '${_payments.length}',
                        Icons.verified_rounded,
                      ),
                      _kpi(
                        'En ligne (Visa)',
                        '${_payments.where((p) => !_isCash(p)).length}',
                        Icons.credit_card_rounded,
                      ),
                      _kpi(
                        'En espèces',
                        '${_payments.where(_isCash).length}',
                        Icons.payments_outlined,
                      ),
                      _kpi(
                        'Accès autorisés / refusés',
                        '$granted / $denied',
                        Icons.how_to_reg_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _sectionTitle('Paiements validés par session'),
                  const SizedBox(height: 12),
                  if (_sessions.isEmpty)
                    _emptyCard('Aucune session d’évaluation dans la faculté.')
                  else
                    ..._sessions.map(_buildSessionRow),
                  const SizedBox(height: 28),
                  _sectionTitle('Derniers contrôles d’accès'),
                  const SizedBox(height: 12),
                  if (_accessLogs.isEmpty)
                    _emptyCard('Aucun contrôle d’accès enregistré.')
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: _accessLogs.map(_buildLogTile).toList(),
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (_context?.facultyName ?? 'Faculté').toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Suivi des paiements et du contrôle d’accès',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      );

  Widget _emptyCard(String message) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          message,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );

  Widget _kpi(String title, String value, IconData icon) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: .12),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionRow(Map<String, dynamic> session) {
    final payments = _payments
        .where((p) => p['exam_session_id'] == session['id'])
        .toList();

    final totals = <String, num>{};
    for (final p in payments) {
      final currency = (p['currency'] ?? 'USD').toString();
      totals[currency] =
          (totals[currency] ?? 0) + (num.tryParse('${p['amount']}') ?? 0);
    }

    final cash = payments.where(_isCash).toList();
    final cashNotRemitted =
        cash.where((p) => p['cash_remitted'] != true).length;

    final year = session['academic_years'];
    final yearName = year is Map ? year['name']?.toString() : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              session['session_name']?.toString(),
              session['semester']?.toString(),
              yearName,
            ].whereType<String>().join(' • '),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              Text(
                '${payments.length} paiement(s) validé(s)',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              Text(
                totals.isEmpty
                    ? 'Montant : 0'
                    : 'Montant : ${totals.entries.map((e) => _formatAmount(e.value, e.key)).join(' + ')}',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              Text(
                'Espèces non remises : $cashNotRemitted',
                style: TextStyle(
                  color: cashNotRemitted > 0
                      ? AppColors.warning
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _generating.contains('${session['id']}:false')
                    ? null
                    : () => _downloadReport(session, authorizedStudents: false),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: const Text('Rapport des paiements (PDF)'),
              ),
              OutlinedButton.icon(
                onPressed: _generating.contains('${session['id']}:true')
                    ? null
                    : () => _downloadReport(session, authorizedStudents: true),
                icon: const Icon(Icons.how_to_reg_rounded, size: 18),
                label: const Text('Étudiants autorisés (PDF)'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogTile(Map<String, dynamic> log) {
    final granted = log['access_granted'] == true;
    final student = log['students'];
    final assistant = log['assistants'];
    final session = log['exam_sessions'];

    final studentLabel = student is Map
        ? '${student['full_name'] ?? '—'} (${student['matricule'] ?? '—'})'
        : 'Étudiant';

    return ListTile(
      leading: Icon(
        granted ? Icons.check_circle_rounded : Icons.block_rounded,
        color: granted ? AppColors.success : AppColors.error,
      ),
      title: Text(studentLabel),
      subtitle: Text(
        [
          session is Map ? session['session_name']?.toString() : null,
          assistant is Map ? 'Contrôlé par ${assistant['full_name']}' : null,
          if ((log['reason'] ?? '').toString().isNotEmpty)
            log['reason'].toString(),
        ].whereType<String>().join(' • '),
      ),
      trailing: Text(
        _formatDate(log['checked_at']),
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    );
  }
}

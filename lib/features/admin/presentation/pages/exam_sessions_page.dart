import 'package:myprojectflut/shared/widgets/home_button.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/exam_session_management_service.dart';

class ExamSessionsPage extends StatefulWidget {
  const ExamSessionsPage({super.key});

  @override
  State<ExamSessionsPage> createState() => _ExamSessionsPageState();
}

class _ExamSessionsPageState extends State<ExamSessionsPage> {
  final ExamSessionManagementService _service =
      ExamSessionManagementService();

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _academicYear;
  List<Map<String, dynamic>> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        _service.getCurrentAcademicYear(),
        _service.getFacultySessions(),
      ]);

      if (!mounted) return;

      setState(() {
        _academicYear = results[0] as Map<String, dynamic>;
        _sessions = results[1] as List<Map<String, dynamic>>;
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

  Future<void> _createSession() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CreateSessionDialog(service: _service),
    );

    if (result == true && mounted) {
      await _loadData();
    }
  }

  void _openExamSchedule(Map<String, dynamic> session) {
    final sessionId = session['id'] as String;

    context.push('/admin/sessions/$sessionId/schedule');
  }

  Future<void> _changePaymentStatus(
    Map<String, dynamic> session,
    bool isOpen,
  ) async {
    final sessionId = session['id'] as String;
    final sessionName = session['session_name'] as String? ?? 'Session';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          isOpen ? 'Ouvrir les paiements ?' : 'Clôturer les paiements ?',
        ),
        content: Text(
          isOpen
              ? 'Les étudiants pourront effectuer leurs paiements pour "$sessionName".'
              : 'Les étudiants ne pourront plus effectuer de nouveaux paiements pour "$sessionName". Les paiements et reçus existants seront conservés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(isOpen ? 'Ouvrir' : 'Clôturer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _service.setPaymentStatus(
        sessionId: sessionId,
        isOpen: isOpen,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          content: Text(
            isOpen
                ? 'Les paiements sont maintenant ouverts.'
                : 'Les paiements ont été clôturés.',
          ),
        ),
      );

      await _loadData();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Sessions d’Évaluation',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _createSession,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle session'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
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
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
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

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 100),
        children: [
          _buildAcademicYearCard(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Sessions de la faculté',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${_sessions.length} session(s)',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_sessions.isEmpty)
            _buildEmptyState()
          else
            ..._buildGroupedSessions(),
        ],
      ),
    );
  }

  /// Année d'une session (jointure academic_years).
  Map<String, dynamic>? _yearOf(Map<String, dynamic> session) {
    final year = session['academic_years'];
    return year is Map ? Map<String, dynamic>.from(year) : null;
  }

  /// Session d'une année antérieure à l'année courante : historique,
  /// consultable mais non réouvrable (règle également appliquée en base).
  bool _isHistorical(Map<String, dynamic> session) {
    final currentStart =
        DateTime.tryParse(_academicYear?['start_date']?.toString() ?? '');
    final yearStart =
        DateTime.tryParse(_yearOf(session)?['start_date']?.toString() ?? '');
    if (currentStart == null || yearStart == null) return false;
    return yearStart.isBefore(currentStart);
  }

  List<Widget> _buildGroupedSessions() {
    final currentId = _academicYear?['id']?.toString();

    final current = <Map<String, dynamic>>[];
    final otherYears = <Map<String, dynamic>>[];
    final historical = <Map<String, dynamic>>[];

    for (final session in _sessions) {
      if (session['academic_year_id']?.toString() == currentId) {
        current.add(session);
      } else if (_isHistorical(session)) {
        historical.add(session);
      } else {
        otherYears.add(session);
      }
    }

    final widgets = <Widget>[];

    void addGroup(
      String title,
      String subtitle,
      List<Map<String, dynamic>> items,
    ) {
      if (items.isEmpty) return;
      widgets
        ..add(_buildGroupHeader(title, subtitle, items.length))
        ..addAll(items.map(_buildSessionCard));
    }

    addGroup(
      'Année courante (${_academicYear?['name'] ?? '—'})',
      'Sessions de l’année académique en cours.',
      current,
    );
    addGroup(
      'Autres années en cours',
      'Sessions d’années non antérieures à l’année courante.',
      otherYears,
    );
    addGroup(
      'Historique — années antérieures',
      'Consultation uniquement : les paiements ne peuvent plus être rouverts.',
      historical,
    );

    return widgets;
  }

  Widget _buildGroupHeader(String title, String subtitle, int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title • $count',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicYearCard() {
    final year = _academicYear;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                color: Colors.white70,
              ),
              SizedBox(width: 8),
              Text(
                'ANNÉE ACADÉMIQUE COURANTE',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            year?['name']?.toString() ?? 'Non disponible',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (year != null) ...[
            const SizedBox(height: 6),
            Text(
              '${year['start_date']}  →  ${year['end_date']}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 40,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_note_rounded,
            size: 52,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'Aucune session créée',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Créez une session d’évaluation pour commencer à organiser les examens de votre faculté.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final isOpen = session['payment_open'] == true;
    // Session archivée (doublon remplacé) : historique conservé,
    // paiements définitivement fermés.
    final isArchived = session['status'] == 'archived';
    final isHistorical = _isHistorical(session);
    final sessionName = session['session_name']?.toString() ?? 'Session';
    final yearName = _yearOf(session)?['name']?.toString();
    final semester = [
      session['semester']?.toString() ?? 'Semestre non défini',
      ?yearName,
    ].join(' • ');
    final amount = session['fee_amount']?.toString() ?? '0';
    final currency = session['currency']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    sessionName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _paymentBadge(isOpen),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              semester,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: 19,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '$amount $currency',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // PROGRAMMATION DES EXAMENS
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openExamSchedule(session),
                icon: const Icon(Icons.calendar_month_rounded),
                label: const Text('Programmer les examens'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // OUVERTURE / CLÔTURE DES PAIEMENTS
            if (isArchived)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Session archivée : remplacée par la session de référence. '
                  'Son historique (paiements, reçus, examens) est conservé ; '
                  'elle n’accepte plus de paiements.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else if (isHistorical && !isOpen)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Session d’une année académique antérieure : historique '
                  'conservé, les paiements ne peuvent plus être rouverts.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _changePaymentStatus(
                  session,
                  !isOpen,
                ),
                icon: Icon(
                  isOpen
                      ? Icons.lock_outline_rounded
                      : Icons.lock_open_rounded,
                ),
                label: Text(
                  isOpen
                      ? 'Clôturer les paiements'
                      : 'Ouvrir les paiements',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentBadge(bool isOpen) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: isOpen
            ? AppColors.primary.withValues(alpha: 0.10)
            : AppColors.textSecondary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        isOpen ? 'Paiements ouverts' : 'Paiements fermés',
        style: TextStyle(
          color: isOpen
              ? AppColors.primaryDark
              : AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _CreateSessionDialog extends StatefulWidget {
  const _CreateSessionDialog({
    required this.service,
  });

  final ExamSessionManagementService service;

  @override
  State<_CreateSessionDialog> createState() =>
      _CreateSessionDialogState();
}

class _CreateSessionDialogState extends State<_CreateSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _feeController = TextEditingController();

  String _sessionName =
      ExamSessionManagementService.sessionTypes.first;

  String _semester =
      ExamSessionManagementService.semesters.first;

  bool _isSaving = false;

  @override
  void dispose() {
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final fee = double.parse(
        _feeController.text.trim().replaceAll(',', '.'),
      );

      await widget.service.createSession(
        sessionName: _sessionName,
        semester: _semester,
        feeAmount: fee,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouvelle session'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _sessionName,
                decoration: const InputDecoration(
                  labelText: 'Type de session',
                  border: OutlineInputBorder(),
                ),
                items: ExamSessionManagementService.sessionTypes
                    .map(
                      (type) => DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      ),
                    )
                    .toList(),
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _sessionName = value);
                        }
                      },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _semester,
                decoration: const InputDecoration(
                  labelText: 'Semestre',
                  border: OutlineInputBorder(),
                ),
                items: ExamSessionManagementService.semesters
                    .map(
                      (semester) => DropdownMenuItem<String>(
                        value: semester,
                        child: Text(semester),
                      ),
                    )
                    .toList(),
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _semester = value);
                        }
                      },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _feeController,
                enabled: !_isSaving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Frais de participation',
                  hintText: 'Ex. : 25',
                  suffixText: 'USD',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final text =
                      value?.trim().replaceAll(',', '.') ?? '';
                  final amount = double.tryParse(text);

                  if (text.isEmpty) {
                    return 'Veuillez saisir les frais.';
                  }

                  if (amount == null ||
                      !amount.isFinite ||
                      amount <= 0) {
                    return 'Saisissez un montant valide supérieur à zéro.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text(
                'La session sera créée avec les paiements fermés. Vous pourrez les ouvrir ensuite.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving
              ? null
              : () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Text('Créer la session'),
        ),
      ],
    );
  }
}

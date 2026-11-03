import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/feedback/smartpass_feedback.dart';
import '../../../../core/feedback/smartpass_messages.dart';
import '../../../../core/services/cash_payment_validation_service.dart';

class CashPaymentValidationPage extends StatefulWidget {
  const CashPaymentValidationPage({super.key});

  @override
  State<CashPaymentValidationPage> createState() =>
      _CashPaymentValidationPageState();
}

class _CashPaymentValidationPageState extends State<CashPaymentValidationPage> {
  final _supabase = Supabase.instance.client;
  final _matriculeController = TextEditingController();
  final _service = CashPaymentValidationService();

  Map<String, dynamic>? _student;
  List<Map<String, dynamic>> _sessions = [];
  Map<String, dynamic>? _selectedSession;
  CashPaymentValidationResult? _result;

  bool _searching = false;
  bool _loadingSessions = false;
  bool _processing = false;

  String? _error;
  String? _idempotencyKey;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void dispose() {
    _matriculeController.dispose();
    super.dispose();
  }

  String _newUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));

    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();

    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  Future<void> _loadSessions() async {
    setState(() {
      _loadingSessions = true;
      _error = null;
    });

    try {
      final data = await _supabase
          .from('exam_sessions')
          .select(
            'id, fee_amount, currency, session_name, semester, '
            'academic_years(name)',
          )
          .eq('payment_open', true)
          .order('session_name');

      if (!mounted) return;

      setState(() {
        _sessions = List<Map<String, dynamic>>.from(data);
        _loadingSessions = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingSessions = false;
        _error = 'Impossible de charger les sessions d’examen.';
      });
    }
  }

  Future<void> _searchStudent() async {
    final matricule = _matriculeController.text.trim();

    if (matricule.isEmpty) {
      setState(() {
        _error = 'Saisissez le matricule de l’étudiant.';
      });
      return;
    }

    setState(() {
      _searching = true;
      _error = null;
      _student = null;
      _selectedSession = null;
      _result = null;
      _idempotencyKey = null;
    });

    try {
      final data = await _supabase
          .from('students')
          .select(
            'id, full_name, matricule, faculty, department, '
            'promotion, academic_year, photo_url',
          )
          .eq('matricule', matricule)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _student = data;
        _searching = false;

        if (data == null) {
          _error = 'Aucun étudiant trouvé pour ce matricule.';
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _searching = false;
        _error = 'La recherche a échoué. Vérifiez la connexion.';
      });
    }
  }

  void _selectSession(Map<String, dynamic>? session) {
    setState(() {
      _selectedSession = session;
      _result = null;
      _idempotencyKey = null;
      _error = null;
    });
  }

  Future<void> _showPaymentError(
    CashPaymentValidationException exception,
  ) async {
    if (!mounted) return;

    final SmartPassMessageCode code;

    switch (exception.code) {
      case 'PAYMENT_ALREADY_EXISTS':
        code = SmartPassMessageCode.paymentAlreadyValidated;
        break;

      case 'PAYMENT_PENDING':
        code = SmartPassMessageCode.paymentPending;
        break;

      case 'CASH_PAYMENT_VALIDATION_FAILED':
        code = SmartPassMessageCode.paymentFailed;
        break;

      default:
        code = exception.status == 409
            ? SmartPassMessageCode.paymentConflict
            : SmartPassMessageCode.genericError;
    }

    await SmartPassFeedback.showDialogMessage(
      context,
      code: code,
      role: SmartPassRole.assistant,
      details: exception.message,
    );
  }

  Future<void> _confirmPayment() async {
    final student = _student;
    final session = _selectedSession;

    if (student == null || session == null) {
      setState(() {
        _error = 'Sélectionnez un étudiant et une session d’examen.';
      });
      return;
    }

    final amount = num.tryParse('${session['fee_amount']}');

    if (amount == null || amount <= 0) {
      setState(() {
        _error = 'Le montant de cette session est invalide.';
      });
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmer le paiement'),
        content: Text(
          'Étudiant : ${student['full_name'] ?? 'Non renseigné'}\n'
          'Matricule : ${student['matricule'] ?? ''}\n'
          'Session : ${session['session_name'] ?? ''}\n'
          'Montant : ${amount.toStringAsFixed(2)} '
          '${session['currency'] ?? ''}\n\n'
          'Confirmez-vous avoir réellement reçu cette somme en espèces ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Conserver la même clé pour les nouvelles tentatives
    // de la même opération.
    final key = _idempotencyKey ??= _newUuid();

    setState(() {
      _processing = true;
      _error = null;
      _result = null;
    });

    try {
      final result = await _service.validateCashPayment(
        studentId: student['id'] as String,
        examSessionId: session['id'] as String,
        idempotencyKey: key,
      );

      if (!mounted) return;

      setState(() {
        _result = result;
        _processing = false;
      });

      if (result.signaturePending) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Paiement enregistré. La signature du reçu reste en attente. '
              'Vérifiez le résultat avant toute nouvelle opération.',
            ),
          ),
        );
      }
    } on CashPaymentValidationException catch (exception) {
      if (!mounted) return;

      setState(() {
        _processing = false;
        _error = null;
      });

      await _showPaymentError(exception);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _processing = false;
        _error =
            'Résultat incertain. Vérifiez le paiement avant toute nouvelle opération.';
      });
    }
  }

  String _formatAmount(dynamic value) {
    final amount = num.tryParse('$value');
    if (amount == null) return '$value';
    return amount.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final student = _student;
    final session = _selectedSession;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation manuelle'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Icon(
                  Icons.payments_outlined,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Paiement en espèces',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Recherchez l’étudiant et vérifiez les informations '
                  'avant de confirmer le paiement.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),

                // 1. Recherche de l’étudiant.
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1. Identifier l’étudiant',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _matriculeController,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _searchStudent(),
                          decoration: const InputDecoration(
                            labelText: 'Matricule',
                            hintText: 'Ex. : ULPGL-...',
                            prefixIcon: Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _searching ? null : _searchStudent,
                            icon: _searching
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.search),
                            label: const Text('Rechercher'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (student != null) ...[
                  const SizedBox(height: 12),

                  // 2. Identité de l’étudiant.
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '2. Identité de l’étudiant',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: AppColors.primaryLight
                                    .withValues(alpha: 0.15),
                                backgroundImage:
                                    student['photo_url'] is String &&
                                        (student['photo_url'] as String)
                                            .isNotEmpty
                                    ? NetworkImage(
                                        student['photo_url'] as String,
                                      )
                                    : null,
                                child:
                                    student['photo_url'] == null ||
                                        (student['photo_url'] as String?)
                                                ?.isEmpty ==
                                            true
                                    ? const Icon(
                                        Icons.person,
                                        color: AppColors.primary,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${student['full_name'] ?? 'Nom indisponible'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                      ),
                                    ),
                                    Text(
                                      'Matricule : ${student['matricule'] ?? '—'}',
                                    ),
                                    Text(
                                      '${student['faculty'] ?? ''}'
                                      '${student['department'] == null ? '' : ' • ${student['department']}'}',
                                    ),
                                    Text(
                                      'Promotion : ${student['promotion'] ?? student['academic_year'] ?? '—'}',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 3. Session d’examen.
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '3. Session d’examen',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          if (_loadingSessions)
                            const Center(child: CircularProgressIndicator())
                          else if (_sessions.isEmpty)
                            const Text('Aucune session ouverte au paiement.')
                          else
                            DropdownButtonFormField<String>(
                              initialValue: session?['id'] as String?,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Session ouverte',
                                border: OutlineInputBorder(),
                              ),
                              items: _sessions.map((item) {
                                final academicYear = item['academic_years'];
                                final yearName = academicYear is Map
                                    ? academicYear['name']?.toString()
                                    : null;

                                final label = [
                                  item['session_name']?.toString() ?? '',
                                  if (item['semester'] != null)
                                    '${item['semester']}',
                                  if (yearName != null && yearName.isNotEmpty)
                                    yearName,
                                ].where((part) => part.isNotEmpty).join(' • ');

                                return DropdownMenuItem<String>(
                                  value: item['id'] as String,
                                  child: Text(
                                    label,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (id) {
                                Map<String, dynamic>? selected;

                                for (final item in _sessions) {
                                  if (item['id'] == id) {
                                    selected = item;
                                    break;
                                  }
                                }

                                _selectSession(selected);
                              },
                            ),
                          if (session != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Montant à recevoir'),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_formatAmount(session['fee_amount'])} '
                                    '${session['currency'] ?? ''}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  _MessagePanel(message: _error!, isError: true),
                ],

                if (student != null && session != null) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _processing ? null : _confirmPayment,
                    icon: _processing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.verified_outlined),
                    label: Text(
                      _processing
                          ? 'Validation en cours…'
                          : 'Confirmer le paiement en espèces',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],

                if (_result != null) ...[
                  const SizedBox(height: 16),
                  _MessagePanel(
                    message: _result!.signaturePending
                        ? 'Le paiement est enregistré, mais la signature du reçu reste en attente. Vérifiez son état avant toute nouvelle opération.'
                        : _result!.alreadyProcessed
                        ? 'Cette opération a déjà été traitée.'
                        : 'Paiement validé avec succès.',
                    isError: false,
                  ),
                  if (_result!.receiptNumber != null)
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.receipt_long_outlined,
                          color: AppColors.primary,
                        ),
                        title: const Text('Numéro du reçu'),
                        subtitle: Text(_result!.receiptNumber!),
                      ),
                    ),
                  if (_result!.payment?['receipt_signature'] != null &&
                      !_result!.signaturePending)
                    const ListTile(
                      leading: Icon(Icons.verified, color: AppColors.primary),
                      title: Text('Signature du reçu disponible'),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? Colors.red.shade700 : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }
}

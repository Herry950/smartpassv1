import 'package:myprojectflut/shared/widgets/home_button.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/theme/app_colors.dart';

/// Page de retour après le paiement Flutterwave.
///
/// Les paramètres d'URL envoyés par Flutterwave (status, tx_ref,
/// transaction_id) ne sont PAS une preuve de paiement : seul le statut
/// enregistré en base, validé côté serveur par le webhook après
/// vérification auprès de Flutterwave, fait foi.
class StudentPaymentResultPage extends StatefulWidget {
  const StudentPaymentResultPage({
    super.key,
    this.txRef,
    this.providerStatus,
  });

  final String? txRef;
  final String? providerStatus;

  @override
  State<StudentPaymentResultPage> createState() =>
      _StudentPaymentResultPageState();
}

class _StudentPaymentResultPageState extends State<StudentPaymentResultPage> {
  static const Duration _pollInterval = Duration(seconds: 3);
  static const int _maxAttempts = 20;

  final SupabaseClient _client = Supabase.instance.client;

  Timer? _timer;
  int _attempts = 0;
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _payment;

  bool get _providerCancelled {
    final status = widget.providerStatus?.toLowerCase();
    return status == 'cancelled' || status == 'failed';
  }

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    final txRef = widget.txRef?.trim();

    if (txRef == null || txRef.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Référence de paiement absente.';
      });
      return;
    }

    try {
      // RLS : l'étudiant ne lit que ses propres paiements.
      final payment = await _client
          .from('payments')
          .select(
            'id, status, amount, currency, receipt_number, paid_at, '
            'exam_sessions(session_name, semester)',
          )
          .eq('flutterwave_tx_ref', txRef)
          .maybeSingle();

      if (!mounted) return;

      _attempts++;

      setState(() {
        _payment = payment;
        _error = payment == null
            ? 'Aucun paiement correspondant à cette référence '
                'n’a été trouvé pour votre compte.'
            : null;
      });

      final status = payment?['status'];
      final waiting = payment != null &&
          status == 'pending' &&
          !_providerCancelled &&
          _attempts < _maxAttempts;

      if (waiting) {
        _timer?.cancel();
        _timer = Timer(_pollInterval, _check);
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de vérifier le paiement : $e';
      });
    }
  }

  void _retry() {
    setState(() {
      _attempts = 0;
      _loading = true;
      _error = null;
    });
    _check();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultat du paiement'),
        leading: IconButton(
          tooltip: 'Retour à mon espace',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/student'),
        ),
        actions: [
          const HomeButton(),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loading ? null : _retry,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final status = _payment?['status']?.toString();

    late final IconData icon;
    late final Color color;
    late final String title;
    late final String message;

    if (status == 'validated') {
      icon = Icons.verified_rounded;
      color = AppColors.success;
      title = 'Paiement confirmé';
      message = 'Votre paiement a été vérifié par le serveur SmartPass. '
          'Votre reçu est disponible dans « Mes reçus ».';
    } else if (status == 'pending' && _loading) {
      icon = Icons.hourglass_top_rounded;
      color = AppColors.info;
      title = 'Vérification en cours…';
      message = 'Nous attendons la confirmation de Flutterwave. '
          'Cette opération prend généralement quelques secondes.';
    } else if (status == 'pending' && _providerCancelled) {
      icon = Icons.cancel_outlined;
      color = AppColors.textSecondary;
      title = 'Paiement non effectué';
      message = 'Le paiement a été annulé ou refusé sur Flutterwave. '
          'La tentative en attente expirera automatiquement après '
          '15 minutes ; vous pourrez alors relancer le paiement.';
    } else if (status == 'pending') {
      icon = Icons.schedule_rounded;
      color = AppColors.warning;
      title = 'Confirmation en attente';
      message = 'La confirmation n’est pas encore parvenue. '
          'Actualisez dans quelques instants ou consultez votre espace : '
          'le statut sera mis à jour dès la confirmation du serveur.';
    } else if (status == 'cancelled') {
      icon = Icons.cancel_outlined;
      color = AppColors.textSecondary;
      title = 'Paiement expiré';
      message = 'Cette tentative de paiement a expiré. '
          'Vous pouvez relancer un paiement depuis votre espace.';
    } else {
      icon = Icons.error_outline_rounded;
      color = AppColors.error;
      title = 'Paiement introuvable';
      message = _error ?? 'Le statut du paiement est inconnu.';
    }

    final session = _payment?['exam_sessions'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            if (_loading && status != 'validated')
              const Padding(
                padding: EdgeInsets.only(bottom: 18),
                child: CircularProgressIndicator(),
              )
            else
              CircleAvatar(
                radius: 36,
                backgroundColor: color.withValues(alpha: .12),
                child: Icon(icon, color: color, size: 40),
              ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            if (_payment != null) ...[
              const SizedBox(height: 20),
              Divider(color: AppColors.border),
              _row('Montant', '${_payment!['amount']} ${_payment!['currency']}'),
              if (session is Map)
                _row(
                  'Session',
                  [session['session_name'], session['semester']]
                      .whereType<String>()
                      .join(' • '),
                ),
              if (_payment!['receipt_number'] != null)
                _row('N° de reçu', _payment!['receipt_number'].toString()),
            ],
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                if (status == 'validated')
                  FilledButton.icon(
                    onPressed: () => context.go('/student/receipts'),
                    icon: const Icon(Icons.receipt_long_rounded),
                    label: const Text('Mes reçus'),
                  ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/student'),
                  icon: const Icon(Icons.dashboard_rounded),
                  label: const Text('Mon espace'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

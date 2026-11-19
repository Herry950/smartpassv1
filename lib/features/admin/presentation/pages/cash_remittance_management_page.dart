import 'package:myprojectflut/shared/widgets/home_button.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:myprojectflut/core/services/cash_remittance_service.dart';

class CashRemittanceManagementPage extends StatefulWidget {
  const CashRemittanceManagementPage({super.key});

  @override
  State<CashRemittanceManagementPage> createState() =>
      _CashRemittanceManagementPageState();
}

class _CashRemittanceManagementPageState
    extends State<CashRemittanceManagementPage> {
  final CashRemittanceService _service = CashRemittanceService();

  CashRemittancePendingResult? _pendingResult;
  CashRemittanceHistoryResult? _historyResult;

  bool _isLoading = true;
  String? _pendingError;
  String? _historyError;
  String? _confirmingAssistantId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final result = await _service.getPendingRemittances();

      if (!mounted) return;

      setState(() {
        _pendingResult = result;
        _pendingError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _pendingError = _errorMessage(e);
      });
    }

    try {
      final result = await _service.getRemittanceHistory();

      if (!mounted) return;

      setState(() {
        _historyResult = result;
        _historyError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _historyError = _errorMessage(e);
      });
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _errorMessage(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  String _formatAmount(double amount) {
    return '${amount.toStringAsFixed(2)} USD';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date indisponible';

    final local = date.toLocal();

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();

    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day/$month/$year à $hour:$minute';
  }

  Future<void> _confirmRemittance(
    CashRemittanceAssistant assistant,
  ) async {
    if (_confirmingAssistantId != null) return;

    final controller = TextEditingController(
      text: assistant.outstandingAmount.toStringAsFixed(2),
    );

    final actualAmount = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmer la remise'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                assistant.assistantName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Montant attendu :'),
              const SizedBox(height: 4),
              Text(
                _formatAmount(assistant.outstandingAmount),
                style: Theme.of(dialogContext)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(dialogContext).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Saisissez le montant réellement reçu en espèces :',
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d{0,2}'),
                  ),
                ],
                decoration: const InputDecoration(
                  labelText: 'Montant reçu',
                  suffixText: 'USD',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Le montant saisi doit correspondre exactement au montant attendu. '
                'Toute différence sera refusée.',
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(
                  controller.text.trim(),
                );

                if (value == null || value <= 0) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Saisissez un montant valide.'),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext, value);
              },
              child: const Text('Continuer'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (actualAmount == null || !mounted) return;

    setState(() {
      _confirmingAssistantId = assistant.assistantId;
    });

    try {
      final result = await _service.confirmRemittance(
        assistantId: assistant.assistantId,
        actualAmount: actualAmount,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Remise de ${_formatAmount(result.amount)} confirmée '
            'pour ${result.assistantName}.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _loadData(showLoader: false);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage(e)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _confirmingAssistantId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Remises des paiements'),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.pending_actions),
                text: 'En attente',
              ),
              Tab(
                icon: Icon(Icons.history),
                text: 'Historique',
              ),
            ],
          ),
          actions: [
          const HomeButton(),
            IconButton(
              tooltip: 'Actualiser',
              onPressed: _isLoading
                  ? null
                  : () => _loadData(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: _isLoading && _pendingResult == null
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : TabBarView(
                children: [
                  _buildPendingTab(colorScheme),
                  _buildHistoryTab(colorScheme),
                ],
              ),
      ),
    );
  }

  Widget _buildPendingTab(ColorScheme colorScheme) {
    if (_pendingError != null && _pendingResult == null) {
      return _buildError(
        _pendingError!,
        () => _loadData(),
      );
    }

    final assistants = _pendingResult?.assistants ?? [];

    final totalOutstanding = assistants.fold<double>(
      0,
      (sum, assistant) => sum + assistant.outstandingAmount,
    );

    final totalPayments = assistants.fold<int>(
      0,
      (sum, assistant) => sum + assistant.outstandingCount,
    );

    return RefreshIndicator(
      onRefresh: () => _loadData(showLoader: false),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(
            title: 'Total des remises en attente',
            amount: _formatAmount(totalOutstanding),
            subtitle:
                '$totalPayments paiement(s) en attente',
            icon: Icons.account_balance_wallet_outlined,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Assistants',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Text(
                '${assistants.length}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_pendingError != null)
            _inlineError(_pendingError!),
          if (assistants.isEmpty)
            _buildEmptyState(
              icon: Icons.check_circle_outline,
              title: 'Aucune remise en attente',
              message:
                  'Tous les paiements en espèces sont à jour.',
            )
          else
            ...assistants.map(
              (assistant) => _buildAssistantCard(assistant),
            ),
        ],
      ),
    );
  }

  Widget _buildAssistantCard(
    CashRemittanceAssistant assistant,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isConfirming =
        _confirmingAssistantId == assistant.assistantId;

    final hasPendingPayments =
        assistant.outstandingCount > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: assistant.isActive
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.person_outline,
            color: assistant.isActive
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          assistant.assistantName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _formatAmount(assistant.outstandingAmount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _smallLabel(
                  assistant.isActive ? 'Actif' : 'Désactivé',
                  assistant.isActive
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                ),
                _smallLabel(
                  '${assistant.outstandingCount} paiement(s)',
                  colorScheme.surfaceContainerHighest,
                ),
                if (assistant.blockedCount > 0)
                  _smallLabel(
                    '${assistant.blockedCount} bloqué(s)',
                    colorScheme.errorContainer,
                  ),
              ],
            ),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(),
          if (assistant.employeeNumber != null &&
              assistant.employeeNumber!.isNotEmpty)
            _detailLine(
              'Matricule',
              assistant.employeeNumber!,
            ),
          if (assistant.payments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Aucun paiement en attente.'),
            )
          else ...[
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Détail des paiements',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...assistant.payments.map(
              (payment) => _buildPaymentLine(payment),
            ),
          ],
          const SizedBox(height: 16),
          if (hasPendingPayments)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: assistant.canConfirm && !isConfirming
                    ? () => _confirmRemittance(assistant)
                    : null,
                icon: isConfirming
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  isConfirming
                      ? 'Confirmation en cours...'
                      : 'Confirmer la remise',
                ),
              ),
            ),
          if (hasPendingPayments && !assistant.canConfirm)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                assistant.blockedCount > 0
                    ? 'Confirmation impossible : certains paiements nécessitent une vérification.'
                    : 'Aucun paiement admissible à confirmer.',
                style: TextStyle(
                  color: colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentLine(CashRemittancePayment payment) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            payment.blocked
                ? Icons.warning_amber_rounded
                : Icons.receipt_long_outlined,
            size: 20,
            color: payment.blocked
                ? colorScheme.error
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.receiptNumber ?? 'Reçu indisponible',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (payment.paidAt != null)
                  Text(
                    _formatDate(payment.paidAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (payment.blocked)
                  Text(
                    'Paiement bloqué',
                    style: TextStyle(
                      color: colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatAmount(payment.amount),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(ColorScheme colorScheme) {
    if (_historyError != null && _historyResult == null) {
      return _buildError(
        _historyError!,
        () => _loadData(),
      );
    }

    final remittances = _historyResult?.remittances ?? [];

    return RefreshIndicator(
      onRefresh: () => _loadData(showLoader: false),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_historyError != null)
            _inlineError(_historyError!),
          if (remittances.isEmpty)
            _buildEmptyState(
              icon: Icons.history,
              title: 'Aucune remise enregistrée',
              message:
                  'Les remises confirmées apparaîtront ici.',
            )
          else
            ...remittances.map(
              (remittance) => _buildHistoryCard(remittance),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(CashRemittanceRecord remittance) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(
            Icons.verified_outlined,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          _formatAmount(remittance.amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (remittance.assistantName != null)
              Text('Assistant : ${remittance.assistantName}'),
            Text(_formatDate(remittance.remittedAt)),
            if (remittance.adminName != null)
              Text('Reçu par : ${remittance.adminName}'),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(),
          _detailLine(
            'Nombre de paiements',
            '${remittance.payments.length}',
          ),
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Reçus associés',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...remittance.payments.map(
            (payment) => _buildPaymentLine(payment),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
    required ColorScheme colorScheme,
  }) {
    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              icon,
              size: 36,
              color: colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    amount,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallLabel(String text, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11),
      ),
    );
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 70),
      child: Column(
        children: [
          Icon(
            icon,
            size: 54,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _inlineError(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        message,
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }

  Widget _buildError(
    String message,
    VoidCallback onRetry,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:myprojectflut/shared/widgets/home_button.dart';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:myprojectflut/app/theme/app_colors.dart';
import 'package:myprojectflut/core/services/cash_remittance_service.dart';

class AssistantCashRemittanceHistoryPage extends StatefulWidget {
  const AssistantCashRemittanceHistoryPage({super.key});

  @override
  State<AssistantCashRemittanceHistoryPage> createState() =>
      _AssistantCashRemittanceHistoryPageState();
}

class _AssistantCashRemittanceHistoryPageState
    extends State<AssistantCashRemittanceHistoryPage> {
  final CashRemittanceService _service = CashRemittanceService();

  late Future<CashRemittanceHistoryResult> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    _historyFuture = _service.getRemittanceHistory();
  }

  Future<void> _refreshHistory() async {
    final future = _service.getRemittanceHistory();

    setState(() {
      _historyFuture = future;
    });

    try {
      await future;
    } catch (_) {
      // L'erreur est traitée dans FutureBuilder.
    }
  }

  /// Transforme les erreurs techniques en messages compréhensibles.
  ({
    IconData icon,
    String title,
    String description,
  }) _getHistoryError(Object error) {
    if (error is AuthException) {
      return (
        icon: Icons.lock_outline_rounded,
        title: 'Session expirée',
        description:
            'Votre session n’est plus valide. Veuillez vous reconnecter '
            'pour consulter vos remises.',
      );
    }

    if (error is PostgrestException) {
      final message = error.message.toLowerCase();

      if (error.code == '42501') {
        if (message.contains('authentification requise')) {
          return (
            icon: Icons.lock_outline_rounded,
            title: 'Authentification requise',
            description:
                'Votre session n’est plus disponible. '
                'Veuillez vous reconnecter pour accéder à votre historique.',
          );
        }

        return (
          icon: Icons.no_accounts_outlined,
          title: 'Accès non autorisé',
          description:
              'Vous ne pouvez pas consulter cet historique. '
              'Vérifiez que votre compte assistant est toujours actif. '
              'Si le problème persiste, contactez l’administration.',
        );
      }

      if (error.code == 'PGRST301' ||
          error.code == 'PGRST303') {
        return (
          icon: Icons.lock_outline_rounded,
          title: 'Session expirée',
          description:
              'Votre authentification a expiré. '
              'Veuillez vous reconnecter avant de réessayer.',
        );
      }
    }

    return (
      icon: Icons.cloud_off_outlined,
      title: 'Historique indisponible',
      description:
          'Nous ne parvenons pas à récupérer vos remises pour le moment. '
          'Vérifiez votre connexion Internet puis réessayez.',
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date non disponible';

    final localDate = date.toLocal();

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year.toString();

    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');

    return '$day/$month/$year à $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                tooltip: 'Retour à la page précédente',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  Navigator.of(context).maybePop();
                },
              )
            : null,
        title: const Text('Mes remises'),
        centerTitle: true,
        actions: [
          const HomeButton(),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _refreshHistory,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<CashRemittanceHistoryResult>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            final error = _getHistoryError(snapshot.error!);

            return _buildHistoryMessage(
              icon: error.icon,
              title: error.title,
              description: error.description,
              action: TextButton.icon(
                onPressed: _refreshHistory,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
              ),
            );
          }

          final history = snapshot.data;

          if (history == null || !history.success) {
            return _buildHistoryMessage(
              icon: Icons.info_outline_rounded,
              title: 'Historique indisponible',
              description:
                  'Les informations de vos remises ne sont pas disponibles '
                  'pour le moment. Veuillez réessayer.',
              action: TextButton.icon(
                onPressed: _refreshHistory,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
              ),
            );
          }

          final remittances = history.remittances;

          if (remittances.isEmpty) {
            return _buildHistoryMessage(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Aucune remise enregistrée',
              description:
                  'Vous n’avez encore aucune remise confirmée par '
                  'l’administration. Vos remises apparaîtront ici '
                  'après leur confirmation.',
            );
          }

          final totalAmount = remittances.fold<double>(
            0,
            (total, item) => total + item.amount,
          );

          final totalPayments = remittances.fold<int>(
            0,
            (total, item) => total + item.payments.length,
          );

          return RefreshIndicator(
            onRefresh: _refreshHistory,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSummaryCard(
                  totalAmount: totalAmount,
                  remittanceCount: remittances.length,
                  paymentCount: totalPayments,
                ),
                const SizedBox(height: 24),
                Text(
                  'Mes remises (${remittances.length})',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...remittances.map(_buildRemittanceCard),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required double totalAmount,
    required int remittanceCount,
    required int paymentCount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total des remises confirmées',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${totalAmount.toStringAsFixed(2)} USD',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildSummaryItem(
                icon: Icons.receipt_long_rounded,
                value: '$remittanceCount',
                label: 'Remises',
              ),
              const SizedBox(width: 28),
              _buildSummaryItem(
                icon: Icons.payments_outlined,
                value: '$paymentCount',
                label: 'Paiements remis',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 20,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRemittanceCard(
    CashRemittanceRecord remittance,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.success,
          ),
        ),
        title: Text(
          '${remittance.amount.toStringAsFixed(2)} '
          '${remittance.currency}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.primaryDark,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            'Remise confirmée le ${_formatDate(remittance.remittedAt)}',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        children: [
          const Divider(),
          _buildRemittanceDetail(
            'Administrateur',
            remittance.adminName ?? 'Administration',
            Icons.person_outline_rounded,
          ),
          const SizedBox(height: 10),
          _buildRemittanceDetail(
            'Nombre de paiements',
            '${remittance.payments.length}',
            Icons.receipt_long_outlined,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Reçus concernés',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (remittance.payments.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Aucun détail de paiement disponible.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            )
          else
            ...remittance.payments.map((payment) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.receipt_outlined,
                      color: AppColors.primary,
                      size: 19,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        payment.receiptNumber ?? 'Reçu non renseigné',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${payment.amount.toStringAsFixed(2)} '
                      '${remittance.currency}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildRemittanceDetail(
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Text(
          '$label : ',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryMessage({
    required IconData icon,
    required String title,
    required String description,
    Widget? action,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 32,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 42,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              if (action != null) ...[
                const SizedBox(height: 12),
                action,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

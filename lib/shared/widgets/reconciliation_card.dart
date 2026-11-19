import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_colors.dart';
import '../../core/services/reconciliation_service.dart';

/// Présentation d'un dossier de réconciliation (administrateur ou étudiant).
class ReconciliationCard extends StatelessWidget {
  const ReconciliationCard({
    super.key,
    required this.item,
    this.actions = const [],
    this.showStudent = false,
  });

  final Map<String, dynamic> item;
  final List<Widget> actions;
  final bool showStudent;

  static String formatDate(dynamic raw) {
    final date = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    return date == null ? '—' : DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(date);
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'refund_confirmed':
        return AppColors.success;
      case 'rejected':
        return AppColors.textSecondary;
      case 'refund_contested':
        return AppColors.error;
      case 'awaiting_funds':
      case 'suspected':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = item['status']?.toString();
    final color = _statusColor(status);
    final currency = (item['currency'] ?? 'USD').toString();
    final student = item['student'];
    final transactions = (item['transactions'] as List? ?? const []).whereType<Map>();
    final events = (item['events'] as List? ?? const []).whereType<Map>();

    Widget line(String label, String? value) => value == null || value.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label : ',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                (item['session'] ?? 'Session').toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  ReconciliationService.label(status),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (showStudent && student is Map)
            line('Étudiant', '${student['full_name']} (${student['matricule']})'),
          line('Montant encaissé en trop', '${item['excess_amount']} $currency'),
          if (item['refund_amount'] != null)
            line('Montant à rembourser', '${item['refund_amount']} $currency'),
          line('Moyen de remboursement', item['refund_method']?.toString()),
          line('Référence / preuve', item['refund_reference']?.toString()),
          if (item['refund_declared_at'] != null)
            line('Remboursement déclaré le', formatDate(item['refund_declared_at'])),
          line('Décision de la faculté', item['decision_note']?.toString()),
          line('Réponse de l’étudiant', item['student_comment']?.toString()),
          line('Ouvert le', formatDate(item['created_at'])),
          if (transactions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Transactions concernées',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            ...transactions.map(
              (t) => Text(
                '• ${t['kind'] == 'kept' ? 'Paiement reconnu' : 'Encaissement en trop'} — '
                '${t['amount']} ${t['currency']} — ${t['channel'] ?? ''}'
                '${t['receipt_number'] != null ? ' — reçu ${t['receipt_number']}' : ''}'
                '${t['transaction_id'] != null ? ' — transaction ${t['transaction_id']}' : ''}',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
          if (events.isNotEmpty)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Historique (${events.length})',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                children: events
                    .map(
                      (e) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${e['action']} — ${ReconciliationService.label(e['new_status']?.toString())}',
                        ),
                        subtitle: Text(
                          '${formatDate(e['created_at'])} • ${e['actor_type']}'
                          '${e['reference'] != null ? ' • ${e['reference']}' : ''}',
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 10, runSpacing: 8, children: actions),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/reconciliation_service.dart';
import '../../../../shared/widgets/home_button.dart';
import '../../../../shared/widgets/reconciliation_card.dart';

/// Doubles encaissements et remboursements manuels de la faculté.
/// Toutes les règles (périmètre facultaire, fonds physiques disponibles,
/// statuts) sont appliquées côté serveur.
class ReconciliationManagementPage extends StatefulWidget {
  const ReconciliationManagementPage({super.key});

  @override
  State<ReconciliationManagementPage> createState() =>
      _ReconciliationManagementPageState();
}

class _ReconciliationManagementPageState
    extends State<ReconciliationManagementPage> {
  final ReconciliationService _service = ReconciliationService();

  bool _loading = true;
  bool _busy = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  num? _availableFunds;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _service.list();
      if (!mounted) return;
      setState(() {
        _items = (data['items'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _availableFunds = num.tryParse('${data['available_funds']}');
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error ? AppColors.error : AppColors.success,
        content: Text(message),
      ),
    );
  }

  Future<void> _run(Future<Map<String, dynamic>> Function() action) async {
    setState(() => _busy = true);
    try {
      final result = await action();
      if (!mounted) return;
      _toast(
        result['message']?.toString() ??
            'Dossier mis à jour : ${ReconciliationService.label(result['status']?.toString())}.',
        error: result['status'] == 'awaiting_funds',
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Map<String, String>?> _form({
    required String title,
    required List<(String key, String label, String initial)> fields,
    String? help,
  }) {
    final controllers = {
      for (final f in fields) f.$1: TextEditingController(text: f.$3),
    };

    return showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (help != null) ...[
                Text(help, style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
              ],
              for (final f in fields) ...[
                TextField(
                  controller: controllers[f.$1],
                  decoration: InputDecoration(labelText: f.$2),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final values = {
                for (final e in controllers.entries) e.key: e.value.text.trim(),
              };
              if (values.values.any((v) => v.isEmpty)) return;
              Navigator.pop(dialogContext, values);
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  List<Widget> _actionsFor(Map<String, dynamic> item) {
    final id = item['id'].toString();
    final status = item['status']?.toString();

    if (status == 'suspected') {
      return [
        FilledButton.icon(
          onPressed: _busy
              ? null
              : () async {
                  final values = await _form(
                    title: 'Confirmer le doublon',
                    help: 'Vérifiez les transactions avant de confirmer. '
                        'Montant maximum : ${item['excess_amount']} ${item['currency']}.',
                    fields: [
                      ('amount', 'Montant à rembourser', '${item['excess_amount']}'),
                      ('note', 'Observation', 'Double encaissement vérifié'),
                    ],
                  );
                  final amount =
                      double.tryParse(values?['amount']?.replaceAll(',', '.') ?? '');
                  if (values == null || amount == null) return;
                  await _run(() => _service.confirmDuplicate(id, amount, note: values['note']));
                },
          icon: const Icon(Icons.check_rounded),
          label: const Text('Confirmer'),
        ),
        OutlinedButton.icon(
          onPressed: _busy
              ? null
              : () async {
                  final values = await _form(
                    title: 'Rejeter le doublon',
                    fields: [('note', 'Motif du rejet', '')],
                  );
                  if (values == null) return;
                  await _run(() => _service.rejectDuplicate(id, values['note']!));
                },
          icon: const Icon(Icons.close_rounded),
          label: const Text('Rejeter'),
        ),
      ];
    }

    if (status == 'confirmed' || status == 'awaiting_funds') {
      return [
        FilledButton.icon(
          onPressed: _busy
              ? null
              : () async {
                  final values = await _form(
                    title: 'Déclarer le remboursement effectué',
                    help: 'Remboursement manuel de ${item['refund_amount']} '
                        '${item['currency']} sur les fonds physiques de la faculté. '
                        'Les fonds disponibles sont vérifiés par le serveur.',
                    fields: [
                      ('method', 'Moyen (espèces, mobile money…)', 'Espèces'),
                      ('reference', 'Référence ou preuve', ''),
                    ],
                  );
                  if (values == null) return;
                  await _run(() => _service.declareRefund(
                        id,
                        method: values['method']!,
                        reference: values['reference']!,
                      ));
                },
          icon: const Icon(Icons.payments_outlined),
          label: const Text('Déclarer le remboursement'),
        ),
      ];
    }

    return const [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Doubles paiements et remboursements',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const HomeButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'FONDS PHYSIQUES DISPONIBLES',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${(_availableFunds ?? 0).toStringAsFixed(2)} USD',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Remises d’espèces confirmées moins '
                                      'remboursements déjà déclarés.',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (_items.isEmpty)
                                Text(
                                  'Aucun double encaissement détecté pour votre faculté.',
                                  style: TextStyle(color: AppColors.textSecondary),
                                )
                              else
                                ..._items.map(
                                  (item) => ReconciliationCard(
                                    item: item,
                                    showStudent: true,
                                    actions: _actionsFor(item),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

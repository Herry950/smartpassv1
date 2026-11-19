import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/reconciliation_service.dart';
import '../../../../shared/widgets/home_button.dart';
import '../../../../shared/widgets/reconciliation_card.dart';

/// Dossiers de double paiement de l'étudiant connecté.
/// Lui seul peut confirmer la réception du remboursement ou le contester.
class StudentReconciliationsPage extends StatefulWidget {
  const StudentReconciliationsPage({super.key});

  @override
  State<StudentReconciliationsPage> createState() =>
      _StudentReconciliationsPageState();
}

class _StudentReconciliationsPageState
    extends State<StudentReconciliationsPage> {
  final ReconciliationService _service = ReconciliationService();

  bool _loading = true;
  bool _busy = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];

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

  Future<void> _respond(String id, {required bool confirm}) async {
    final controller = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(confirm ? 'Confirmer la réception' : 'Contester le remboursement'),
        content: SizedBox(
          width: 420,
          child: confirm
              ? const Text(
                  'Je confirme avoir reçu la totalité du montant annoncé. '
                  'Cette confirmation clôture le dossier.',
                )
              : TextField(
                  controller: controller,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Motif de la contestation',
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (!confirm && controller.text.trim().isEmpty) return;
              Navigator.pop(dialogContext, true);
            },
            child: Text(confirm ? 'Je confirme' : 'Contester'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _busy = true);
    try {
      if (confirm) {
        await _service.studentConfirm(id);
      } else {
        await _service.studentContest(id, controller.text.trim());
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(confirm ? 'Réception confirmée.' : 'Contestation transmise à votre faculté.'),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remboursements'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const HomeButton(),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: _items.isEmpty
                                ? [
                                    Text(
                                      'Aucun dossier de double paiement vous concernant.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: AppColors.textSecondary),
                                    ),
                                  ]
                                : _items.map((item) {
                                    final declared = item['status'] == 'refund_declared';
                                    return ReconciliationCard(
                                      item: item,
                                      actions: declared
                                          ? [
                                              FilledButton.icon(
                                                onPressed: _busy
                                                    ? null
                                                    : () => _respond(item['id'].toString(), confirm: true),
                                                icon: const Icon(Icons.check_circle_rounded),
                                                label: const Text('J’ai reçu le remboursement'),
                                              ),
                                              OutlinedButton.icon(
                                                onPressed: _busy
                                                    ? null
                                                    : () => _respond(item['id'].toString(), confirm: false),
                                                icon: const Icon(Icons.report_problem_outlined),
                                                label: const Text('Contester'),
                                              ),
                                            ]
                                          : const [],
                                    );
                                  }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

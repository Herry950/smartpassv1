import 'package:supabase_flutter/supabase_flutter.dart';

/// Accès aux dossiers de réconciliation via l'Edge Function
/// `payment-reconciliation` (JWT vérifié ; rôle, faculté et droits
/// déterminés côté serveur). Flutter n'envoie jamais de rôle ni de faculté.
class ReconciliationService {
  ReconciliationService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const Map<String, String> statusLabels = {
    'suspected': 'Doublon suspect',
    'confirmed': 'Doublon confirmé — remboursement à effectuer',
    'rejected': 'Doublon rejeté',
    'awaiting_funds': 'En attente de fonds disponibles',
    'refund_declared': 'Remboursement déclaré — attente de confirmation',
    'refund_confirmed': 'Remboursement confirmé par l’étudiant',
    'refund_contested': 'Remboursement contesté',
  };

  static String label(String? status) =>
      statusLabels[status] ?? (status ?? 'Inconnu');

  Future<Map<String, dynamic>> _call(Map<String, dynamic> body) async {
    try {
      final response = await _client.functions.invoke(
        'payment-reconciliation',
        body: body,
      );

      final data = response.data;
      if (data is Map && data['success'] == true) {
        return Map<String, dynamic>.from(data);
      }

      throw Exception(
        data is Map ? data['message'] ?? 'Opération impossible.' : 'Opération impossible.',
      );
    } on FunctionException catch (e) {
      if (e.status == 404) {
        throw Exception(
          'Le module de réconciliation n’est pas encore déployé sur Supabase.',
        );
      }
      final details = e.details;
      throw Exception(
        details is Map
            ? details['message']?.toString() ?? 'Opération impossible.'
            : 'Opération impossible (HTTP ${e.status}).',
      );
    }
  }

  Future<Map<String, dynamic>> list() => _call({'action': 'list'});

  Future<Map<String, dynamic>> confirmDuplicate(String id, double refundAmount,
          {String? note}) =>
      _call({
        'action': 'confirm',
        'reconciliation_id': id,
        'refund_amount': refundAmount,
        'note': ?note,
      });

  Future<Map<String, dynamic>> rejectDuplicate(String id, String note) =>
      _call({'action': 'reject', 'reconciliation_id': id, 'note': note});

  Future<Map<String, dynamic>> declareRefund(
    String id, {
    required String method,
    required String reference,
  }) =>
      _call({
        'action': 'declare_refund',
        'reconciliation_id': id,
        'refund_method': method,
        'reference': reference,
      });

  Future<Map<String, dynamic>> studentConfirm(String id) =>
      _call({'action': 'student_confirm', 'reconciliation_id': id});

  Future<Map<String, dynamic>> studentContest(String id, String comment) =>
      _call({
        'action': 'student_contest',
        'reconciliation_id': id,
        'comment': comment,
      });
}

import 'package:supabase_flutter/supabase_flutter.dart';

/// Convertit une réponse JSON en Map exploitable.
Map<String, dynamic> _toMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return <String, dynamic>{};
}

/// Convertit une valeur JSON en liste.
List<dynamic> _toList(dynamic value) {
  return value is List ? value : <dynamic>[];
}

String? _toNullableString(dynamic value) {
  if (value == null) return null;
  return value.toString();
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _toBool(dynamic value) {
  return value == true;
}

DateTime? _toDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

/// Représente un paiement associé à une remise.
class CashRemittancePayment {
  final String? paymentId;
  final String? receiptNumber;
  final double amount;
  final DateTime? paidAt;
  final bool blocked;

  const CashRemittancePayment({
    this.paymentId,
    this.receiptNumber,
    required this.amount,
    this.paidAt,
    this.blocked = false,
  });

  factory CashRemittancePayment.fromJson(
    Map<String, dynamic> json,
  ) {
    return CashRemittancePayment(
      paymentId: _toNullableString(json['payment_id']),
      receiptNumber: _toNullableString(json['receipt_number']),
      amount: _toDouble(json['amount']),
      paidAt: _toDateTime(json['paid_at']),
      blocked: _toBool(json['blocked']),
    );
  }
}

/// Représente un assistant et ses paiements en attente de remise.
class CashRemittanceAssistant {
  final String assistantId;
  final String assistantName;
  final String? employeeNumber;
  final bool isActive;
  final String? facultyId;
  final double outstandingAmount;
  final int outstandingCount;
  final int blockedCount;
  final bool canConfirm;
  final List<CashRemittancePayment> payments;

  const CashRemittanceAssistant({
    required this.assistantId,
    required this.assistantName,
    this.employeeNumber,
    required this.isActive,
    this.facultyId,
    required this.outstandingAmount,
    required this.outstandingCount,
    required this.blockedCount,
    required this.canConfirm,
    required this.payments,
  });

  factory CashRemittanceAssistant.fromJson(
    Map<String, dynamic> json,
  ) {
    return CashRemittanceAssistant(
      assistantId: json['assistant_id']?.toString() ?? '',
      assistantName: json['assistant_name']?.toString() ?? '',
      employeeNumber: _toNullableString(json['employee_number']),
      isActive: _toBool(json['is_active']),
      facultyId: _toNullableString(json['faculty_id']),
      outstandingAmount: _toDouble(json['outstanding_amount']),
      outstandingCount: _toInt(json['outstanding_count']),
      blockedCount: _toInt(json['blocked_count']),
      canConfirm: _toBool(json['can_confirm']),
      payments: _toList(json['payments'])
          .map((item) => CashRemittancePayment.fromJson(_toMap(item)))
          .toList(),
    );
  }
}

/// Résultat de la récupération des remises en attente.
class CashRemittancePendingResult {
  final bool success;
  final String? adminId;
  final String? facultyId;
  final List<CashRemittanceAssistant> assistants;

  const CashRemittancePendingResult({
    required this.success,
    this.adminId,
    this.facultyId,
    required this.assistants,
  });

  factory CashRemittancePendingResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return CashRemittancePendingResult(
      success: _toBool(json['success']),
      adminId: _toNullableString(json['admin_id']),
      facultyId: _toNullableString(json['faculty_id']),
      assistants: _toList(json['assistants'])
          .map((item) => CashRemittanceAssistant.fromJson(_toMap(item)))
          .toList(),
    );
  }
}

/// Historique d'une remise confirmée.
class CashRemittanceRecord {
  final String remittanceId;
  final String assistantId;
  final String? assistantName;
  final String? adminId;
  final String? adminName;
  final double amount;
  final String currency;
  final DateTime? remittedAt;
  final List<CashRemittancePayment> payments;

  const CashRemittanceRecord({
    required this.remittanceId,
    required this.assistantId,
    this.assistantName,
    this.adminId,
    this.adminName,
    required this.amount,
    required this.currency,
    this.remittedAt,
    required this.payments,
  });

  factory CashRemittanceRecord.fromJson(
    Map<String, dynamic> json,
  ) {
    return CashRemittanceRecord(
      remittanceId: json['remittance_id']?.toString() ?? '',
      assistantId: json['assistant_id']?.toString() ?? '',
      assistantName: _toNullableString(json['assistant_name']),
      adminId: _toNullableString(json['admin_id']),
      adminName: _toNullableString(json['admin_name']),
      amount: _toDouble(json['amount']),
      currency: json['currency']?.toString() ?? 'USD',
      remittedAt: _toDateTime(json['remitted_at']),
      payments: _toList(json['payments'])
          .map((item) => CashRemittancePayment.fromJson(_toMap(item)))
          .toList(),
    );
  }
}

/// Résultat de la récupération de l'historique.
class CashRemittanceHistoryResult {
  final bool success;
  final String? profile;
  final List<CashRemittanceRecord> remittances;

  const CashRemittanceHistoryResult({
    required this.success,
    this.profile,
    required this.remittances,
  });

  factory CashRemittanceHistoryResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return CashRemittanceHistoryResult(
      success: _toBool(json['success']),
      profile: _toNullableString(json['profile']),
      remittances: _toList(json['remittances'])
          .map((item) => CashRemittanceRecord.fromJson(_toMap(item)))
          .toList(),
    );
  }
}

/// Résultat de la confirmation d'une remise.
class CashRemittanceConfirmation {
  final bool success;
  final String remittanceId;
  final String assistantId;
  final String assistantName;
  final String? adminId;
  final double amount;
  final String currency;
  final int paymentCount;
  final DateTime? remittedAt;
  final List<CashRemittancePayment> payments;

  const CashRemittanceConfirmation({
    required this.success,
    required this.remittanceId,
    required this.assistantId,
    required this.assistantName,
    this.adminId,
    required this.amount,
    required this.currency,
    required this.paymentCount,
    this.remittedAt,
    required this.payments,
  });

  factory CashRemittanceConfirmation.fromJson(
    Map<String, dynamic> json,
  ) {
    return CashRemittanceConfirmation(
      success: _toBool(json['success']),
      remittanceId: json['remittance_id']?.toString() ?? '',
      assistantId: json['assistant_id']?.toString() ?? '',
      assistantName: json['assistant_name']?.toString() ?? '',
      adminId: _toNullableString(json['admin_id']),
      amount: _toDouble(json['amount']),
      currency: json['currency']?.toString() ?? 'USD',
      paymentCount: _toInt(json['payment_count']),
      remittedAt: _toDateTime(json['remitted_at']),
      payments: _toList(json['payments'])
          .map((item) => CashRemittancePayment.fromJson(_toMap(item)))
          .toList(),
    );
  }
}

/// Service de gestion des remises en espèces.
///
/// Toutes les opérations passent par les fonctions RPC sécurisées
/// de Supabase. Aucune écriture directe dans les tables protégées.
class CashRemittanceService {
  CashRemittanceService({
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Récupère les assistants et leurs paiements en attente.
  Future<CashRemittancePendingResult> getPendingRemittances() async {
    final response = await _client.rpc(
      'get_cash_remittance_pending',
    );

    final result = CashRemittancePendingResult.fromJson(
      _toMap(response),
    );

    if (!result.success) {
      throw Exception(
        'Impossible de récupérer les remises en attente.',
      );
    }

    return result;
  }

  /// Confirme une remise pour un assistant.
  ///
  /// Le backend vérifie lui-même que le montant réel correspond
  /// exactement au montant attendu.
  Future<CashRemittanceConfirmation> confirmRemittance({
    required String assistantId,
    required double actualAmount,
  }) async {
    final response = await _client.rpc(
      'confirm_cash_remittance',
      params: {
        'p_assistant_id': assistantId,
        'p_actual_amount': actualAmount,
      },
    );

    final result = CashRemittanceConfirmation.fromJson(
      _toMap(response),
    );

    if (!result.success) {
      throw Exception(
        'La confirmation de la remise a échoué.',
      );
    }

    return result;
  }

  /// Récupère l'historique des remises.
  ///
  /// Sans assistantId : historique autorisé pour le profil connecté.
  /// Avec assistantId : historique de cet assistant, si autorisé.
  Future<CashRemittanceHistoryResult> getRemittanceHistory({
    String? assistantId,
  }) async {
    final response = await _client.rpc(
      'get_cash_remittance_history',
      params: assistantId == null
          ? <String, dynamic>{}
          : {
              'p_assistant_id': assistantId,
            },
    );

    final result = CashRemittanceHistoryResult.fromJson(
      _toMap(response),
    );

    if (!result.success) {
      throw Exception(
        'Impossible de récupérer l’historique des remises.',
      );
    }

    return result;
  }
}
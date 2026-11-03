import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Résultat d'une validation de paiement en espèces.
class CashPaymentValidationResult {
  final bool success;
  final bool alreadyProcessed;
  final bool signaturePending;
  final String message;
  final Map<String, dynamic>? payment;
  final String? paymentId;
  final String? receiptNumber;

  const CashPaymentValidationResult({
    required this.success,
    required this.alreadyProcessed,
    required this.signaturePending,
    required this.message,
    this.payment,
    this.paymentId,
    this.receiptNumber,
  });

  factory CashPaymentValidationResult.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawPayment = json['payment'];
    final payment = rawPayment is Map
        ? Map<String, dynamic>.from(rawPayment)
        : null;

    return CashPaymentValidationResult(
      success: json['success'] == true,
      alreadyProcessed: json['already_processed'] == true,
      signaturePending: json['signature_pending'] == true,
      message: json['message'] as String? ??
          (json['success'] == true
              ? 'Validation du paiement terminée.'
              : 'La validation du paiement a échoué.'),
      payment: payment,
      paymentId: json['payment_id'] as String? ??
          payment?['id'] as String?,
      receiptNumber: json['receipt_number'] as String? ??
          payment?['receipt_number'] as String?,
    );
  }
}

/// Erreur présentable dans l'interface, avec son code métier.
class CashPaymentValidationException implements Exception {
  final String message;
  final String? code;
  final int? status;

  const CashPaymentValidationException(
    this.message, {
    this.code,
    this.status,
  });

  factory CashPaymentValidationException.fromResponse(
    Map<String, dynamic> json, {
    int? status,
  }) {
    return CashPaymentValidationException(
      json['message'] as String? ??
          'La validation du paiement a échoué.',
      code: json['code'] as String?,
      status: status,
    );
  }

  @override
  String toString() => message;
}

/// Service de validation des paiements en espèces.
class CashPaymentValidationService {
  CashPaymentValidationService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<CashPaymentValidationResult> validateCashPayment({
    required String studentId,
    required String examSessionId,
    required String idempotencyKey,
  }) async {
    if (_client.auth.currentUser == null) {
      throw const CashPaymentValidationException(
        'Votre session a expiré. Veuillez vous reconnecter.',
        code: 'SESSION_EXPIRED',
      );
    }

    try {
      final response = await _client.functions.invoke(
        'validate-cash-payment',
        body: {
          'student_id': studentId,
          'exam_session_id': examSessionId,
          'idempotency_key': idempotencyKey,
        },
      );

      final data = response.data;

      if (data is! Map) {
        throw CashPaymentValidationException(
          'Réponse invalide du serveur.',
          status: response.status,
        );
      }

      final json = Map<String, dynamic>.from(data);

      if (response.status < 200 || response.status >= 300) {
        throw CashPaymentValidationException.fromResponse(
          json,
          status: response.status,
        );
      }

      final result = CashPaymentValidationResult.fromJson(json);

      if (!result.success) {
        throw CashPaymentValidationException(
          result.message,
          status: response.status,
        );
      }

      return result;
    } on CashPaymentValidationException {
      rethrow;
    } on FunctionException catch (error) {
      debugPrint('Cash validation HTTP: ${error.status}');
      debugPrint('Cash validation details: ${error.details}');
      debugPrint('Cash validation reason: ${error.reasonPhrase}');

      final details = error.details;

      if (details is Map) {
        final json = Map<String, dynamic>.from(details);

        throw CashPaymentValidationException.fromResponse(
          json,
          status: error.status,
        );
      }

      throw CashPaymentValidationException(
        'Le serveur n’a pas pu traiter la validation. '
        'Vérifiez le paiement avant de réessayer.',
        status: error.status,
      );
    } catch (error, stackTrace) {
      debugPrint('Cash validation error: $error');
      debugPrintStack(stackTrace: stackTrace);

      throw const CashPaymentValidationException(
        'Erreur de connexion. Vérifiez le réseau et le résultat '
        'du paiement avant de réessayer.',
        code: 'NETWORK_ERROR',
      );
    }
  }
}
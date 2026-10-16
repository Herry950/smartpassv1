import 'package:supabase_flutter/supabase_flutter.dart';

class DocumentSignatureService {
  DocumentSignatureService._();

  static final _supabase = Supabase.instance.client;

  static Future<String> signReceipt({
    required String paymentId,
    required String receiptNumber,
    required String studentId,
    required double amount,
    required String currency,
    required String transactionId,
    required String paidAt,
  }) async {
    final response = await _supabase.functions.invoke(
      'sign-document',
      body: {
        'payment_id': paymentId,
        'receipt_number': receiptNumber,
        'student_id': studentId,
        'amount': amount,
        'currency': currency,
        'transaction_id': transactionId,
        'paid_at': paidAt,
      },
    );

    if (response.data == null) {
      throw Exception("Aucune réponse du serveur.");
    }

    final data = response.data;

    if (data['success'] != true) {
      throw Exception(
        data['message'] ?? "Signature impossible.",
      );
    }

    return data['signature'] as String;
  }

  static Future<Map<String, dynamic>> getReceipt({
    required String paymentId,
  }) async {
    final response = await _supabase.functions.invoke(
      'receipt',
      body: {
        'payment_id': paymentId,
      },
    );

    if (response.data == null) {
      throw Exception("Aucune réponse du serveur.");
    }

    final data = response.data;

    if (data['success'] != true) {
      throw Exception(
        data['message'] ?? "Impossible de récupérer le reçu.",
      );
    }

    return Map<String, dynamic>.from(data);
  }
}
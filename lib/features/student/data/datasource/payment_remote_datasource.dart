import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Erreur métier renvoyée par le service de paiement SmartPass.
class PaymentRemoteException implements Exception {
  const PaymentRemoteException({
    required this.message,
    this.code,
    this.statusCode,
  });

  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() => message;
}

class PaymentRemoteDataSource {
  PaymentRemoteDataSource._();

  static final SupabaseClient _client =
      Supabase.instance.client;

  static Future<String> createPayment({
    required String examSessionId,
    required String email,
    required String paymentMethod,
  }) async {
    final session = _client.auth.currentSession;

    if (session == null) {
      throw const PaymentRemoteException(
        message: 'Utilisateur non connecté.',
      );
    }

    const url =
        'https://jjbvpkdyliehgouinnav.supabase.co/functions/v1/create-payment';

    print('========== CREATE PAYMENT ==========');
    print('URL : $url');
    print('Exam Session : $examSessionId');
    print('Email : $email');
    print('Payment Method : $paymentMethod');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.accessToken}',
      },
      body: jsonEncode({
        'exam_session_id': examSessionId,
        'email': email,
        'payment_method': paymentMethod,
      }),
    );

    print('========== APRÈS LE POST ==========');
    print('Status Code : ${response.statusCode}');
    print('Response : ${response.body}');

    // Lecture sécurisée du JSON, même lorsque la requête échoue.
    Map<String, dynamic> data = {};

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        data = decoded;
      }
    } on FormatException {
      // La réponse n'est pas un JSON valide.
    }

    if (response.statusCode != 200) {
      final code = data['code'] as String?;
      final serverMessage = data['error'] as String?;

      if (response.statusCode == 409) {
        switch (code) {
          case 'PAYMENT_ALREADY_EXISTS':
            throw const PaymentRemoteException(
              code: 'PAYMENT_ALREADY_EXISTS',
              statusCode: 409,
              message:
                  'Cette session est déjà payée pour cet étudiant.',
            );

          case 'PAYMENT_PENDING':
            throw const PaymentRemoteException(
              code: 'PAYMENT_PENDING',
              statusCode: 409,
              message:
                  'Une tentative de paiement est déjà en attente pour cette session.',
            );
        }
      }

      throw PaymentRemoteException(
        code: code,
        statusCode: response.statusCode,
        message: serverMessage ??
            'Impossible de créer le paiement. '
                'Code HTTP : ${response.statusCode}.',
      );
    }

    print('========== PAYMENT RESPONSE ==========');
    print('Success : ${data['success']}');
    print('Payment ID : ${data['payment_id']}');
    print('TX Ref : ${data['tx_ref']}');
    print('Checkout URL : ${data['checkout_url']}');

    final checkoutUrl = data['checkout_url'];

    if (data['success'] != true ||
        checkoutUrl is! String ||
        checkoutUrl.isEmpty) {
      throw const PaymentRemoteException(
        message: 'URL de paiement introuvable.',
      );
    }

    return checkoutUrl;
  }
}
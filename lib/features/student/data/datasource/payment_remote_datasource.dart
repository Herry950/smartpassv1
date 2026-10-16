import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

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
      throw Exception(
        "Utilisateur non connecté.",
      );
    }

    const url =
        "https://jjbvpkdyliehgouinnav.supabase.co/functions/v1/create-payment";

    print(
      "========== CREATE PAYMENT ==========",
    );
    print("URL : $url");
    print("Exam Session : $examSessionId");
    print("Email : $email");
    print("Payment Method : $paymentMethod");

    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization":
            "Bearer ${session.accessToken}",
      },
      body: jsonEncode({
        "exam_session_id": examSessionId,
        "email": email,
        "payment_method": paymentMethod,
      }),
    );

    print(
      "========== APRÈS LE POST ==========",
    );
    print(
      "Status Code : ${response.statusCode}",
    );
    print(
      "Response : ${response.body}",
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Erreur création paiement : "
        "${response.body}",
      );
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    print(
      "========== PAYMENT RESPONSE ==========",
    );
    print("Success : ${data["success"]}");
    print(
      "Payment ID : ${data["payment_id"]}",
    );
    print("TX Ref : ${data["tx_ref"]}");
    print(
      "Checkout URL : ${data["checkout_url"]}",
    );

    final checkoutUrl =
        data["checkout_url"];

    if (checkoutUrl == null ||
        checkoutUrl is! String ||
        checkoutUrl.isEmpty) {
      throw Exception(
        "URL de paiement introuvable.",
      );
    }

    return checkoutUrl;
  }
}
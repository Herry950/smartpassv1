import '../datasource/payment_remote_datasource.dart';
import '../datasource/student_remote_datasource.dart';

class PaymentRepository {
  PaymentRepository._();

  /// Historique des paiements
  static Future<List<Map<String, dynamic>>> getPayments(
    String studentId,
  ) async {
    return StudentRemoteDataSource.getPayments(
      studentId,
    );
  }

  /// Dernier paiement
  static Future<Map<String, dynamic>?> getLastPayment(
    String studentId,
  ) async {
    return StudentRemoteDataSource.getLastPayment(
      studentId,
    );
  }

  /// Création d'un nouveau paiement
  static Future<String> createPayment({
    required String examSessionId,
    required String email,
    required String paymentMethod,
  }) async {
    print("========== PaymentRepository ==========");
    print("ExamSessionId : $examSessionId");
    print("Email : $email");
    print("PaymentMethod : $paymentMethod");

    final checkoutUrl =
        await PaymentRemoteDataSource.createPayment(
      examSessionId: examSessionId,
      email: email,
      paymentMethod: paymentMethod,
    );

    print("CheckoutUrl : $checkoutUrl");

    return checkoutUrl;
  }
}
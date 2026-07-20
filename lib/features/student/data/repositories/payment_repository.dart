import '../datasource/student_remote_datasource.dart';

class PaymentRepository {
  PaymentRepository._();

  static Future<Map<String, dynamic>?> getLastPayment(
    String studentId,
  ) async {
    return StudentRemoteDataSource.getLastPayment(
      studentId,
    );
  }

  static Future<List<Map<String, dynamic>>> getPayments(
    String studentId,
  ) async {
    return StudentRemoteDataSource.getPayments(
      studentId,
    );
  }
}
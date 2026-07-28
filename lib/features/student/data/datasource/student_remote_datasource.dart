import 'package:supabase_flutter/supabase_flutter.dart';

class StudentRemoteDataSource {
  StudentRemoteDataSource._();

  static final SupabaseClient _client =
      Supabase.instance.client;

  /// Étudiant connecté
  static Future<Map<String, dynamic>?> getCurrentStudent() async {
    print("========== REMOTE DATASOURCE ==========");

    final user = _client.auth.currentUser;

    if (user == null) {
      print("Aucun utilisateur connecté.");
      return null;
    }

    print("Email connecté : ${user.email}");
    print("User ID : ${user.id}");

    final response = await _client
        .from('students')
        .select()
        .eq('auth_user_id', user.id)
        .maybeSingle();

    print("Résultat students : $response");
    print("======================================");

    return response;
  }

  /// Dernier paiement
  static Future<Map<String, dynamic>?> getLastPayment(
    String studentId,
  ) async {
    return await _client
        .from('payments')
        .select()
        .eq('student_id', studentId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }

  /// Notifications de l'étudiant
  static Future<List<Map<String, dynamic>>> getNotifications(
    String studentId,
  ) async {
    final response = await _client
        .from('notifications')
        .select()
        .eq('student_id', studentId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Carte étudiant
  static Future<Map<String, dynamic>?> getStudentCard(
    String studentId,
  ) async {
    return await _client
        .from('student_cards')
        .select()
        .eq('student_id', studentId)
        .maybeSingle();
  }

  /// Vérifie si le dernier paiement est validé
  static Future<bool> isPaymentValidated(
    String studentId,
  ) async {
    final payment = await _client
        .from('payments')
        .select('status')
        .eq('student_id', studentId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (payment == null) {
      return false;
    }

    return payment['status'] == 'validated';
  }

  /// Vérifie si la carte étudiant est active
  static Future<bool> isExamAuthorized(
    String studentId,
  ) async {
    final card = await _client
        .from('student_cards')
        .select('is_active')
        .eq('student_id', studentId)
        .maybeSingle();

    if (card == null) {
      return false;
    }

    return card['is_active'] == true;
  }

  /// Historique des paiements
  static Future<List<Map<String, dynamic>>> getPayments(
    String studentId,
  ) async {
    final response = await _client
        .from('payments')
        .select()
        .eq('student_id', studentId)
        .order('paid_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Session d'examen actuellement ouverte
  static Future<Map<String, dynamic>?> getCurrentExamSession() async {
    final response = await _client
        .from('exam_sessions')
        .select('''
          id,
          fee_amount,
          currency,
          session_name,
          semester,
          payment_open,
          academic_years(name)
        ''')
        .eq('payment_open', true)
        .limit(1)
        .maybeSingle();

    print("========== EXAM SESSION ==========");
    print(response);
    print("Session ID : ${response?['id']}");
    print("==================================");

    return response;
  }
}
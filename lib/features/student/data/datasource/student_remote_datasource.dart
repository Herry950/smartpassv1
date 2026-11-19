
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

  /// Vérifie si l'étudiant possède un paiement validé pour une session.
  static Future<bool> hasValidatedPaymentForSession(
    String studentId,
    String examSessionId,
  ) async {
    // Inclut l'équivalence historique : un paiement validé d'une session
    // archivée remplacée par cette session (replaced_by_session_id)
    // couvre la même obligation.
    final payments = await _client
        .from('payments')
        .select('exam_session_id, exam_sessions(*)')
        .eq('student_id', studentId)
        .eq('status', 'validated');

    return List<Map<String, dynamic>>.from(payments).any((p) {
      final session = p['exam_sessions'];
      return p['exam_session_id'] == examSessionId ||
          (session is Map &&
              session['replaced_by_session_id'] == examSessionId);
    });
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

  /// Historique des paiements avec leurs sessions d'examens
  static Future<List<Map<String, dynamic>>> getPayments(
    String studentId,
  ) async {
    final response = await _client
        .from('payments')
        .select('''
          *,
          exam_sessions!payments_exam_session_fk(
            session_name,
            semester
          )
        ''')
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
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    print("========== EXAM SESSION ==========");
    print(response);
    print("Session ID : ${response?['id']}");
    print("==================================");

    return response;
  }

  /// Sessions ouvertes aux paiements visibles par l'étudiant connecté.
  /// La RLS (can_view_exam_session) limite la liste à sa faculté,
  /// son année académique et sa promotion.
  static Future<List<Map<String, dynamic>>> getOpenExamSessions() async {
    final response = await _client
        .from('exam_sessions')
        .select('''
          id,
          fee_amount,
          currency,
          session_name,
          semester,
          payment_open,
          status,
          academic_years(name)
        ''')
        .eq('payment_open', true)
        .neq('status', 'archived')
        .order('session_name', ascending: true)
        .order('semester', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Statuts des paiements de l'étudiant par session (validated, pending…).
  static Future<Map<String, Set<String>>> getPaymentStatusesBySession(
    String studentId,
  ) async {
    final response = await _client
        .from('payments')
        .select('exam_session_id, status, exam_sessions(*)')
        .eq('student_id', studentId);

    final result = <String, Set<String>>{};
    for (final row in List<Map<String, dynamic>>.from(response)) {
      final status = row['status'].toString();
      result
          .putIfAbsent(row['exam_session_id'].toString(), () => <String>{})
          .add(status);

      // Paiement validé d'une session archivée remplacée : la session
      // de référence est considérée comme payée (même obligation).
      final session = row['exam_sessions'];
      final replacedBy =
          session is Map ? session['replaced_by_session_id'] : null;
      if (status == 'validated' && replacedBy != null) {
        result
            .putIfAbsent(replacedBy.toString(), () => <String>{})
            .add('validated');
      }
    }
    return result;
  }

  /// Examens programmés accessibles à l'étudiant connecté.
  ///
  /// Les politiques RLS filtrent les examens selon la faculté,
  /// l'année académique et la promotion de l'étudiant.
  ///
  /// Cette méthode ne dépend pas de payment_open :
  /// un examen reste consultable même si les paiements sont fermés.
  static Future<List<Map<String, dynamic>>> getStudentExams() async {
    final response = await _client
        .from('exam_schedule_items')
        .select('''
          id,
          exam_date,
          start_time,
          end_time,
          exam_sessions!inner(
            id,
            session_name,
            semester,
            academic_year_id,
            academic_years(name)
          ),
          courses!inner(
            id,
            code,
            name,
            course_type,
            department,
            promotion
          ),
          exam_schedule_targets(
            promotion_code
          ),
          exam_schedule_rooms(
            rooms(
              id,
              code,
              name,
              building
            )
          )
        ''')
        .order('exam_date', ascending: true)
        .order('start_time', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }
}

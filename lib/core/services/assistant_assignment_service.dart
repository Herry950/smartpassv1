import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_context_service.dart';

/// Affectation des assistants aux sessions d'évaluation de la faculté.
///
/// Les contrôles sont assurés par Supabase :
/// - RLS : l'administrateur ne gère que les sessions de sa faculté ;
/// - trigger `check_assignment_faculty` : assistant et session
///   doivent appartenir à la même faculté ;
/// - contrainte unique (assistant, session).
class AssistantAssignmentService {
  AssistantAssignmentService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<Map<String, dynamic>> loadData() async {
    final context = await AdminContextService(client: _client).load();
    final facultyId = context.facultyId;

    if (facultyId == null) {
      throw Exception(
        'Ce module est réservé aux administrateurs facultaires.',
      );
    }

    final results = await Future.wait([
      _client
          .from('exam_sessions')
          .select(
            'id, session_name, semester, status, payment_open, '
            'academic_years(name)',
          )
          .eq('faculty_id', facultyId)
          .order('created_at', ascending: false),
      _client
          .from('assistants')
          .select('id, full_name, email, employee_number, is_active')
          .eq('faculty_id', facultyId)
          .order('full_name'),
      _client
          .from('assistant_assignments')
          .select(
            'id, assistant_id, exam_session_id, status, assigned_at, '
            'assistants(full_name, email, is_active), '
            'exam_sessions!inner(session_name, semester, faculty_id, '
            'academic_years(name))',
          )
          .eq('exam_sessions.faculty_id', facultyId)
          .order('assigned_at', ascending: false),
    ]);

    return {
      'context': context,
      'sessions': List<Map<String, dynamic>>.from(results[0]),
      'assistants': List<Map<String, dynamic>>.from(results[1]),
      'assignments': List<Map<String, dynamic>>.from(results[2]),
    };
  }

  Future<void> assign({
    required String adminId,
    required String assistantId,
    required String examSessionId,
  }) async {
    try {
      await _client.from('assistant_assignments').insert({
        'assistant_id': assistantId,
        'exam_session_id': examSessionId,
        'assigned_by_admin': adminId,
        'status': 'assigned',
      });
    } on PostgrestException catch (e) {
      throw Exception(_message(e));
    }
  }

  Future<void> remove(String assignmentId) async {
    try {
      await _client
          .from('assistant_assignments')
          .delete()
          .eq('id', assignmentId);
    } on PostgrestException catch (e) {
      throw Exception(_message(e));
    }
  }

  String _message(PostgrestException e) {
    switch (e.code) {
      case '23505':
        return 'Cet assistant est déjà affecté à cette session.';
      case '23514':
        return e.message;
      case '42501':
        return 'Vous n’êtes pas autorisé à gérer cette affectation.';
      default:
        return 'Opération impossible : ${e.message}';
    }
  }
}

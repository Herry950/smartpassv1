
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentSearchService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Récupère l'assistant connecté et vérifie que son compte est actif.
  ///
  /// La sécurité des données reste assurée par les politiques RLS.
  Future<Map<String, dynamic>> _getActiveAssistant() async {
    final authUserId = _supabase.auth.currentUser?.id;

    if (authUserId == null) {
      throw Exception('Aucun assistant connecté.');
    }

    debugPrint('Vérification du compte assistant : $authUserId');

    final assistantData = await _supabase
        .from('assistants')
        .select('id, is_active')
        .eq('auth_user_id', authUserId)
        .maybeSingle();

    if (assistantData == null) {
      throw Exception(
        'Compte assistant introuvable. '
        'Veuillez contacter l’administration de votre faculté.',
      );
    }

    if (assistantData['is_active'] != true) {
      throw Exception('Un compte assistant actif requis.');
    }

    return assistantData;
  }

  /// Recherche un étudiant par matricule et récupère
  /// ses paiements avec les sessions d'examen associées.
  Future<Map<String, dynamic>?> searchStudentByMatricule(
    String matricule,
  ) async {
    final normalizedMatricule = matricule.trim();

    if (normalizedMatricule.isEmpty) {
      throw ArgumentError('Le matricule est obligatoire.');
    }

    try {
      debugPrint('========== RECHERCHE MATRICULE ==========');
      debugPrint('Matricule recherché : $normalizedMatricule');

      await _getActiveAssistant();

      final studentResponse = await _supabase
          .from('students')
          .select()
          .eq('matricule', normalizedMatricule)
          .maybeSingle();

      debugPrint('Étudiant retourné : $studentResponse');

      if (studentResponse == null) {
        debugPrint('Aucun étudiant visible pour cette requête.');
        return null;
      }

      final studentId = studentResponse['id'];

      debugPrint('Student ID : $studentId');

      final paymentsResponse = await _supabase
          .from('payments')
          .select('*, exam_sessions(*)')
          .eq('student_id', studentId)
          .order('created_at', ascending: false);

      debugPrint(
        'Nombre de paiements récupérés : ${paymentsResponse.length}',
      );

      return {
        'student': studentResponse,
        'payments': paymentsResponse,
      };
    } catch (e, stackTrace) {
      debugPrint('ERREUR RECHERCHE MATRICULE : $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Sessions d'évaluation auxquelles l'assistant connecté est affecté.
  Future<List<Map<String, dynamic>>> getAssignedSessions() async {
    final assistantData = await _getActiveAssistant();

    final response = await _supabase
        .from('assistant_assignments')
        .select(
          'exam_session_id, status, '
          'exam_sessions(id, session_name, semester, academic_years(name))',
        )
        .eq('assistant_id', assistantData['id'])
        .eq('status', 'assigned');

    return List<Map<String, dynamic>>.from(response)
        .map((row) => row['exam_sessions'])
        .whereType<Map>()
        .map((session) => Map<String, dynamic>.from(session))
        .toList();
  }

  /// Enregistre une tentative de contrôle d'accès.
  Future<void> logAccessAttempt({
    required String studentId,
    required String examSessionId,
    required bool accessGranted,
    String? reason,
  }) async {
    try {
      final assistantData = await _getActiveAssistant();

      await _supabase.from('access_logs').insert({
        'student_id': studentId,
        'assistant_id': assistantData['id'],
        'exam_session_id': examSessionId,
        'access_granted': accessGranted,
        'reason': reason,
        'checked_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e, stackTrace) {
      debugPrint('Erreur journalisation accès : $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }
}

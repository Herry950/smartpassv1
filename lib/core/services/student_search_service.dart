import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentSearchService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Recherche un étudiant par matricule et récupère
  /// ses paiements avec les sessions d'examen associées.
  /*Future<Map<String, dynamic>?> searchStudentByMatricule(
    String matricule,
  ) async {
    final normalizedMatricule = matricule.trim();

    if (normalizedMatricule.isEmpty) {
      throw ArgumentError('Le matricule est obligatoire.');
    }

    try {
      final studentResponse = await _supabase
          .from('students')
          .select()
          .eq('matricule', normalizedMatricule)
          .maybeSingle();

      if (studentResponse == null) {
        return null;
      }

      final studentId = studentResponse['id'];

      final paymentsResponse = await _supabase
          .from('payments')
          .select(', exam_sessions()')
          .eq('student_id', studentId)
          .order('created_at', ascending: false);

      return {
        'student': studentResponse,
        'payments': paymentsResponse,
      };
    } catch (e, stackTrace) {
      debugPrint('Erreur recherche étudiant : $e');
      debugPrintStack(stackTrace: stackTrace);

      throw Exception(
        'Erreur lors de la recherche de l’étudiant. '
        'Vérifie la connexion et les autorisations.',
      );
    }
  }
*/
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
        .select(', exam_sessions()')
        .eq('student_id', studentId)
        .order('created_at', ascending: false);

    debugPrint('Nombre de paiements récupérés : '
        '${paymentsResponse.length}');
    debugPrint('Paiements récupérés : $paymentsResponse');

    return {
      'student': studentResponse,
      'payments': paymentsResponse,
    };
  } catch (e, stackTrace) {
    debugPrint('ERREUR SUPABASE : $e');
    debugPrintStack(stackTrace: stackTrace);
    rethrow;
  }
}
  /// Enregistre une tentative de contrôle d'accès.
  Future<void> logAccessAttempt({
    required String studentId,
    required String examSessionId,
    required bool accessGranted,
    String? reason,
  }) async {
    try {
      final authUserId = _supabase.auth.currentUser?.id;

      if (authUserId == null) {
        throw Exception('Aucun assistant connecté.');
      }

      final assistantData = await _supabase
          .from('assistants')
          .select('id')
          .eq('auth_user_id', authUserId)
          .eq('is_active', true)
          .maybeSingle();

      if (assistantData == null) {
        throw Exception(
          'Assistant introuvable ou compte désactivé.',
        );
      }

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
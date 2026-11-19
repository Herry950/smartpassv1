
import 'package:supabase_flutter/supabase_flutter.dart';

class ExamScheduleManagementService {
  ExamScheduleManagementService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  // ============================================================
  // NORMALISATION DES ERREURS
  // ============================================================

  String _cleanErrorMessage(Object error) {
    if (error is PostgrestException) {
      return error.message;
    }

    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('PostgrestException(message: ', '');
  }

  String _getScheduleErrorMessage(PostgrestException error) {
    final message = error.message.trim();
    final normalizedMessage = message.toLowerCase();

    // Erreurs liées aux dates et aux horaires.

    if (normalizedMessage.contains('date passée')) {
      return 'Impossible de programmer un examen à une date passée.';
    }

    if (normalizedMessage.contains('heure de début est déjà passée')) {
      return 'Impossible de programmer un examen dont l’heure de début est déjà passée.';
    }

    if (normalizedMessage.contains('heure de fin doit être postérieure')) {
      return 'L’heure de fin doit être postérieure à l’heure de début.';
    }

    // Erreurs liées aux salles.

    if (normalizedMessage.contains('au moins une salle')) {
      return 'Un examen doit être affecté à au moins une salle.';
    }

    if (normalizedMessage.contains('salles') &&
        (normalizedMessage.contains('invalides') ||
            normalizedMessage.contains('inactives'))) {
      return 'Une ou plusieurs salles sont inexistantes ou inactives.';
    }

    // Erreurs liées aux cours et aux promotions.

    if (normalizedMessage.contains('cours introuvable')) {
      return 'Le cours sélectionné est introuvable, inactif ou appartient à une autre faculté.';
    }

    if (normalizedMessage.contains('promotion')) {
      return message;
    }

    if (normalizedMessage.contains('département')) {
      return message;
    }

    // Conflits de programmation.

    if (error.code == '23505') {
      return 'Ce cours est déjà programmé dans cette session ou cette promotion possède déjà un examen à cette date.';
    }

    // Problèmes de droits et de sécurité.

    if (error.code == '42501') {
      return 'Vous n’êtes pas autorisé à programmer cet examen, ou la session est inaccessible.';
    }

    // Autres contraintes de la base de données.

    if (error.code == '23514') {
      return message.isNotEmpty
          ? message
          : 'Les conditions de programmation de cet examen ne sont pas respectées.';
    }

    return message.isNotEmpty
        ? message
        : 'Une erreur inattendue est survenue pendant la programmation.';
  }

  // ============================================================
  // AUTHENTIFICATION ET CONTEXTE FACULTAIRE
  // ============================================================

  void _checkSession() {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception(
        'Votre session a expiré. Veuillez vous reconnecter.',
      );
    }
  }

  Future<Map<String, dynamic>> _getFacultyContext() async {
    _checkSession();

    final userId = _client.auth.currentUser!.id;

    final admin = await _client
        .from('admins')
        .select('faculty_id, is_active')
        .eq('auth_user_id', userId)
        .maybeSingle();

    if (admin == null || admin['is_active'] != true) {
      throw Exception(
        'Aucun compte administrateur actif n’a été trouvé.',
      );
    }

    final facultyId = admin['faculty_id'] as String?;

    if (facultyId == null) {
      throw Exception(
        'Ce module est réservé aux administrateurs facultaires.',
      );
    }

    final faculty = await _client
        .from('academic_faculties')
        .select('id, name, is_active')
        .eq('id', facultyId)
        .maybeSingle();

    if (faculty == null || faculty['is_active'] != true) {
      throw Exception(
        'Votre faculté est introuvable ou inactive.',
      );
    }

    return {
      'faculty_id': faculty['id'] as String,
      'faculty_name': faculty['name'] as String,
    };
  }

  // ============================================================
  // VÉRIFICATION DE LA SESSION D'ÉVALUATION
  // ============================================================

  Future<void> _checkExamSession(String sessionId) async {
    if (sessionId.trim().isEmpty) {
      throw Exception('Identifiant de session invalide.');
    }

    final context = await _getFacultyContext();

    final session = await _client
        .from('exam_sessions')
        .select('id, faculty_id')
        .eq('id', sessionId)
        .eq('faculty_id', context['faculty_id'] as String)
        .maybeSingle();

    if (session == null) {
      throw Exception(
        'Session introuvable ou inaccessible pour votre faculté.',
      );
    }
  }

  // ============================================================
  // COURS DISPONIBLES POUR LA PROGRAMMATION
  // ============================================================

  Future<List<Map<String, dynamic>>> getAvailableCourses({
    required String sessionId,
  }) async {
    try {
      await _checkExamSession(sessionId);

      final context = await _getFacultyContext();
      final facultyName = context['faculty_name'] as String;

      final courses = await _client
          .from('courses')
          .select(
            'id, code, name, faculty, department, promotion, '
            'course_type, is_active',
          )
          .eq('faculty', facultyName)
          .eq('is_active', true)
          .order('code');

      final scheduledItems = await _client
          .from('exam_schedule_items')
          .select('course_id')
          .eq('exam_session_id', sessionId);

      final scheduledCourseIds = scheduledItems
          .map((item) => item['course_id'] as String)
          .toSet();

      return List<Map<String, dynamic>>.from(courses)
          .where(
            (course) =>
                !scheduledCourseIds.contains(course['id']),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(
        'Impossible de récupérer les cours disponibles : '
        '${e.message}',
      );
    }
  }

  // ============================================================
  // SALLES DISPONIBLES
  // ============================================================

  Future<List<Map<String, dynamic>>> getActiveRooms() async {
    try {
      await _getFacultyContext();

      final result = await _client
          .from('rooms')
          .select('id, code, name, building, capacity, is_active')
          .eq('is_active', true)
          .order('code');

      return List<Map<String, dynamic>>.from(result);
    } on PostgrestException catch (e) {
      throw Exception(
        'Impossible de récupérer les salles : ${e.message}',
      );
    }
  }

  // ============================================================
  // PROGRAMMATION D'UN EXAMEN AVEC PLUSIEURS SALLES
  // ============================================================

  Future<String> createExamSchedule({
    required String sessionId,
    required String courseId,
    required DateTime examDate,
    required String startTime,
    required String endTime,
    required List<String> roomIds,
  }) async {
    if (sessionId.trim().isEmpty) {
      throw Exception('Identifiant de session invalide.');
    }

    if (courseId.trim().isEmpty) {
      throw Exception('Veuillez sélectionner un cours.');
    }

    if (startTime.trim().isEmpty || endTime.trim().isEmpty) {
      throw Exception('Veuillez préciser les heures de l’examen.');
    }

    if (roomIds.isEmpty) {
      throw Exception(
        'Veuillez sélectionner au moins une salle.',
      );
    }

    final selectedRoomIds = roomIds
        .map((id) => id.trim())
        .toList();

    if (selectedRoomIds.any((id) => id.isEmpty)) {
      throw Exception('Identifiant de salle invalide.');
    }

    if (selectedRoomIds.toSet().length != selectedRoomIds.length) {
      throw Exception(
        'Une même salle ne peut pas être sélectionnée plusieurs fois.',
      );
    }

    try {
      await _checkExamSession(sessionId);

      final date = [
        examDate.year.toString().padLeft(4, '0'),
        examDate.month.toString().padLeft(2, '0'),
        examDate.day.toString().padLeft(2, '0'),
      ].join('-');

      final result = await _client.rpc(
        'create_exam_schedule_item_with_rooms',
        params: {
          'p_exam_session_id': sessionId,
          'p_course_id': courseId,
          'p_exam_date': date,
          'p_start_time': startTime,
          'p_end_time': endTime,
          'p_room_ids': selectedRoomIds,
        },
      );

      if (result == null || result.toString().isEmpty) {
        throw Exception(
          'La programmation a été exécutée sans retourner '
          'un identifiant valide.',
        );
      }

      return result.toString();
    } on PostgrestException catch (e) {
      throw Exception(_getScheduleErrorMessage(e));
    } catch (e) {
      throw Exception(_cleanErrorMessage(e));
    }
  }

  // ============================================================
  // EMPLOI DU TEMPS D'UNE SESSION
  // ============================================================

  Future<List<Map<String, dynamic>>> getSessionSchedule({
    required String sessionId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (endDate.isBefore(startDate)) {
      throw Exception('La période demandée est invalide.');
    }

    try {
      await _checkExamSession(sessionId);

      final firstDate = [
        startDate.year.toString().padLeft(4, '0'),
        startDate.month.toString().padLeft(2, '0'),
        startDate.day.toString().padLeft(2, '0'),
      ].join('-');

      final lastDate = [
        endDate.year.toString().padLeft(4, '0'),
        endDate.month.toString().padLeft(2, '0'),
        endDate.day.toString().padLeft(2, '0'),
      ].join('-');

      final result = await _client
          .from('exam_schedule_items')
          .select('''
            id,
            exam_session_id,
            course_id,
            exam_date,
            start_time,
            end_time,
            courses (
              id,
              code,
              name,
              promotion,
              course_type,
              department
            ),
            exam_schedule_rooms (
              id,
              room_id,
              rooms (
                id,
                code,
                name,
                building,
                capacity
              )
            ),
            exam_schedule_targets (
              id,
              promotion_code
            )
          ''')
          .eq('exam_session_id', sessionId)
          .gte('exam_date', firstDate)
          .lte('exam_date', lastDate)
          .order('exam_date')
          .order('start_time');

      return List<Map<String, dynamic>>.from(result);
    } on PostgrestException catch (e) {
      throw Exception(
        'Impossible de récupérer l’emploi du temps : ${e.message}',
      );
    }
  }
}

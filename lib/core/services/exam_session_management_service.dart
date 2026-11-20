
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

class ExamSessionManagementService {
  ExamSessionManagementService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const List<String> sessionTypes = [
    'Session ordinaire',
    'Session de rattrapage',
  ];

  static const List<String> semesters = [
    'Semestre 1',
    'Semestre 2',
  ];

  /// Génère un UUID version 4 côté Flutter.
  ///
  /// Cela permet de connaître l'identifiant avant l'insertion
  /// et de récupérer ensuite la session dans une requête séparée.
  String _generateUuidV4() {
    final random = Random.secure();

    final bytes = List<int>.generate(
      16,
      (_) => random.nextInt(256),
    );

    // Version 4.
    bytes[6] = (bytes[6] & 0x0f) | 0x40;

    // Variante RFC 4122.
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();

    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }

  void _checkSession() {
    final user = _client.auth.currentUser;

    print('========== VÉRIFICATION AUTH ==========');
    print('Utilisateur connecté : ${user?.id}');
    print('Email : ${user?.email}');
    print('Rôle JWT utilisateur : ${user?.role}');
    print('Session active : ${_client.auth.currentSession != null}');
    print('=======================================');

    if (user == null) {
      throw Exception(
        'Votre session a expiré. Veuillez vous reconnecter.',
      );
    }
  }

  /// Récupère le contexte de l'administrateur facultaire connecté.
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
      'faculty_id': faculty['id'],
      'faculty_name': faculty['name'],
    };
  }

  /// Récupère l'année académique marquée comme courante.
  Future<Map<String, dynamic>> getCurrentAcademicYear() async {
    _checkSession();

    try {
      final result = await _client
          .from('academic_years')
          .select('id, name, start_date, end_date, is_current')
          .eq('is_current', true)
          .maybeSingle();

      if (result == null) {
        throw Exception(
          'Aucune année académique n’est actuellement définie.',
        );
      }

      return result;
    } on PostgrestException catch (e) {
      print('ERREUR RÉCUPÉRATION ANNÉE ACADÉMIQUE');
      print('Code : ${e.code}');
      print('Message : ${e.message}');
      print('Details : ${e.details}');
      print('Hint : ${e.hint}');

      throw Exception(
        'Impossible de récupérer l’année académique : ${e.message}',
      );
    }
  }

  /// Récupère les sessions de la faculté de l'administrateur connecté.
  Future<List<Map<String, dynamic>>> getFacultySessions() async {
    try {
      final context = await _getFacultyContext();
      final facultyId = context['faculty_id'] as String;

      final result = await _client
          .from('exam_sessions')
          .select(
            'id, academic_year_id, faculty_id, fee_amount, currency, '
            'status, session_name, semester, payment_open, created_at, '
            'academic_years(name, start_date, is_current)',
          )
          .eq('faculty_id', facultyId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(result);
    } on PostgrestException catch (e) {
      print('ERREUR CHARGEMENT SESSIONS');
      print('Code : ${e.code}');
      print('Message : ${e.message}');
      print('Details : ${e.details}');
      print('Hint : ${e.hint}');

      throw Exception(
        'Impossible de récupérer les sessions : ${e.message}',
      );
    }
  }

  /// Crée une session fermée, rattachée à l'année académique courante.
  ///
  /// L'insertion et la lecture sont volontairement séparées :
  /// l'insertion ne demande pas de RETURNING.
  Future<Map<String, dynamic>> createSession({
    required String sessionName,
    required String semester,
    required double feeAmount,
  }) async {
    if (!sessionTypes.contains(sessionName)) {
      throw Exception('Type de session invalide.');
    }

    if (!semesters.contains(semester)) {
      throw Exception('Semestre invalide.');
    }

    if (!feeAmount.isFinite || feeAmount <= 0) {
      throw Exception(
        'Les frais de participation doivent être supérieurs à zéro.',
      );
    }

    try {
      // 1. Vérification de l'utilisateur connecté.
      _checkSession();

      final user = _client.auth.currentUser!;

      // 2. Récupération de la faculté de l'administrateur.
      final context = await _getFacultyContext();
      final facultyId = context['faculty_id'] as String;

      // 3. Récupération de l'année académique courante.
      final academicYear = await getCurrentAcademicYear();
      final academicYearId = academicYear['id'] as String;

      // 4. Génération de l'identifiant avant l'insertion.
      final sessionId = _generateUuidV4();

      // 5. Préparation des données.
      final payload = {
        'id': sessionId,
        'academic_year_id': academicYearId,
        'faculty_id': facultyId,
        'session_name': sessionName,
        'semester': semester,
        'fee_amount': feeAmount,
        'payment_open': false,
      };

      print('========== CRÉATION SESSION ==========');
      print('Utilisateur : ${user.id}');
      print('Faculté : $facultyId');
      print('Année académique : ${academicYear['name']}');
      print('Session : $sessionName');
      print('Semestre : $semester');
      print('Montant : $feeAmount');
      print('Identifiant généré : $sessionId');
      print('======================================');

      // 6. Insertion SANS RETURNING.
      await _client
          .from('exam_sessions')
          .insert(payload);

      print('INSERTION RÉUSSIE : $sessionId');

      // 7. Lecture séparée de la session créée.
      final result = await _client
          .from('exam_sessions')
          .select(
            'id, academic_year_id, faculty_id, fee_amount, currency, '
            'status, session_name, semester, payment_open, created_at',
          )
          .eq('id', sessionId)
          .eq('faculty_id', facultyId)
          .single();

      print('LECTURE SÉPARÉE RÉUSSIE');
      print('Session créée : $result');
      print('======================================');

      return result;
    } on PostgrestException catch (e, stackTrace) {
      print('========== ERREUR POSTGREST CRÉATION SESSION ==========');
      print('Code : ${e.code}');
      print('Message : ${e.message}');
      print('Details : ${e.details}');
      print('Hint : ${e.hint}');
      print('StackTrace : $stackTrace');
      print('=======================================================');

      // Index unique (faculté, année, type, semestre) : doublon refusé,
      // y compris en cas de créations simultanées.
      if (e.code == '23505') {
        throw Exception(
          'Cette session existe déjà pour votre faculté et l’année '
          'académique en cours (même type et même semestre).',
        );
      }

      throw Exception(
        'Impossible de créer ou récupérer la session.\n'
        'Code : ${e.code}\n'
        'Message : ${e.message}\n'
        'Details : ${e.details}\n'
        'Hint : ${e.hint}',
      );
    } catch (e, stackTrace) {
      print('========== ERREUR INATTENDUE CRÉATION SESSION ==========');
      print('Erreur : $e');
      print('Type : ${e.runtimeType}');
      print('StackTrace : $stackTrace');
      print('========================================================');

      rethrow;
    }
  }

  /// Ouvre ou ferme les paiements d'une session appartenant à la faculté.
  Future<void> setPaymentStatus({
    required String sessionId,
    required bool isOpen,
  }) async {
    if (sessionId.trim().isEmpty) {
      throw Exception('Identifiant de session invalide.');
    }

    try {
      final context = await _getFacultyContext();
      final facultyId = context['faculty_id'] as String;

      final result = await _client
          .from('exam_sessions')
          .update({
            'payment_open': isOpen,
          })
          .eq('id', sessionId)
          .eq('faculty_id', facultyId)
          .select('id, payment_open');

      if (result.isEmpty) {
        throw Exception(
          'Session introuvable ou vous n’avez pas la permission de la modifier.',
        );
      }
    } on PostgrestException catch (e) {
      print('ERREUR MODIFICATION PAIEMENT');
      print('Code : ${e.code}');
      print('Message : ${e.message}');
      print('Details : ${e.details}');
      print('Hint : ${e.hint}');

      throw Exception(
        'Impossible de modifier l’état des paiements : ${e.message}',
      );
    }
  }

  /// Ouvre les paiements d'une session.
  Future<void> openPayments(String sessionId) {
    return setPaymentStatus(
      sessionId: sessionId,
      isOpen: true,
    );
  }

  /// Ferme les paiements d'une session.
  Future<void> closePayments(String sessionId) {
    return setPaymentStatus(
      sessionId: sessionId,
      isOpen: false,
    );
  }
}

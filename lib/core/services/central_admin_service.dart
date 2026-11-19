import 'package:supabase_flutter/supabase_flutter.dart';

/// Opérations de l'espace administrateur central.
///
/// Les écritures sont autorisées par les politiques RLS basées sur
/// `is_central_admin()` (compte actif et `admins.faculty_id IS NULL`).
/// Les contrôles métier restent assurés par les triggers PostgreSQL
/// (protection des cours tronc commun, etc.).
class CentralAdminService {
  CentralAdminService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String _message(PostgrestException e) {
    switch (e.code) {
      case '23505':
        return 'Cet élément existe déjà.';
      case '23503':
        return 'Suppression impossible : cet élément est encore utilisé.';
      case '42501':
        return 'Action réservée à l’administrateur central.';
      default:
        return e.message;
    }
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      throw Exception(_message(e));
    }
  }

  // ===========================================================
  // STRUCTURE ACADÉMIQUE
  // ===========================================================

  /// Facultés avec leurs départements et promotions affectées.
  Future<List<Map<String, dynamic>>> loadFaculties() {
    return _guard(() async {
      final response = await _client
          .from('academic_faculties')
          .select(
            'id, name, is_active, created_at, '
            'academic_departments(id, name, minimum_promotion_rank, is_active), '
            'faculty_promotions(promotion_code)',
          )
          .order('name');

      return List<Map<String, dynamic>>.from(response);
    });
  }

  Future<List<Map<String, dynamic>>> loadPromotions() {
    return _guard(() async {
      final response = await _client
          .from('academic_promotions')
          .select('code, rank')
          .order('rank');

      return List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> createFaculty(String name) {
    return _guard(() async {
      await _client.from('academic_faculties').insert({
        'name': name.trim(),
        'is_active': true,
      });
    });
  }

  Future<void> renameFaculty(String facultyId, String name) {
    return _guard(() async {
      await _client
          .from('academic_faculties')
          .update({'name': name.trim()})
          .eq('id', facultyId);
    });
  }

  Future<void> createDepartment({
    required String facultyId,
    required String name,
    required int minimumPromotionRank,
  }) {
    return _guard(() async {
      await _client.from('academic_departments').insert({
        'faculty_id': facultyId,
        'name': name.trim(),
        'minimum_promotion_rank': minimumPromotionRank,
        'is_active': true,
      });
    });
  }

  Future<void> updateDepartment({
    required String departmentId,
    required String name,
    required int minimumPromotionRank,
  }) {
    return _guard(() async {
      await _client
          .from('academic_departments')
          .update({
            'name': name.trim(),
            'minimum_promotion_rank': minimumPromotionRank,
          })
          .eq('id', departmentId);
    });
  }

  /// Affecte ou retire une promotion à une faculté (faculty_promotions).
  Future<void> setFacultyPromotion({
    required String facultyId,
    required String promotionCode,
    required bool assigned,
  }) {
    return _guard(() async {
      if (assigned) {
        await _client.from('faculty_promotions').insert({
          'faculty_id': facultyId,
          'promotion_code': promotionCode,
        });
      } else {
        await _client
            .from('faculty_promotions')
            .delete()
            .eq('faculty_id', facultyId)
            .eq('promotion_code', promotionCode);
      }
    });
  }

  // ===========================================================
  // ÉTUDIANTS ET CARTES
  // ===========================================================

  Future<List<Map<String, dynamic>>> searchStudents({
    String query = '',
    String? faculty,
    int limit = 100,
  }) {
    return _guard(() async {
      var request = _client.from('students').select(
            'id, auth_user_id, matricule, full_name, faculty, department, '
            'promotion, academic_year, photo_url, created_at',
          );

      final text = query.trim();
      if (text.isNotEmpty) {
        final safe = text.replaceAll(RegExp(r'[,()%*]'), ' ');
        request = request.or(
          'matricule.ilike.%$safe%,full_name.ilike.%$safe%',
        );
      }

      if (faculty != null && faculty.isNotEmpty) {
        request = request.eq('faculty', faculty);
      }

      final response =
          await request.order('full_name').limit(limit);

      return List<Map<String, dynamic>>.from(response);
    });
  }

  /// Cartes enregistrées des étudiants (gestion administrative centrale).
  /// Retourne une carte vide tant que la politique RLS centrale n'existe pas.
  Future<Map<String, Map<String, dynamic>>> loadCards(List<String> studentIds) {
    return _guard(() async {
      if (studentIds.isEmpty) return {};
      final response = await _client
          .from('student_cards')
          .select('id, student_id, is_active, expires_at, academic_year_id')
          .inFilter('student_id', studentIds);

      final result = <String, Map<String, dynamic>>{};
      for (final row in List<Map<String, dynamic>>.from(response)) {
        result[row['student_id'].toString()] = row;
      }
      return result;
    });
  }

  /// Active ou désactive une carte (colonne is_active uniquement).
  Future<void> setCardActive(String cardId, bool active) {
    return _guard(() async {
      final updated = await _client
          .from('student_cards')
          .update({'is_active': active})
          .eq('id', cardId)
          .select('id');
      if (updated.isEmpty) {
        throw Exception('Modification de la carte refusée.');
      }
    });
  }

  /// Date de fin de chaque année académique (nom → end_date).
  /// La validité d'une carte est la date de fin de l'année de l'étudiant
  /// (même règle que student_cards.expires_at). Aucune donnée financière.
  Future<Map<String, DateTime>> academicYearEndDates() {
    return _guard(() async {
      final response =
          await _client.from('academic_years').select('name, end_date');

      final result = <String, DateTime>{};
      for (final row in List<Map<String, dynamic>>.from(response)) {
        final date = DateTime.tryParse(row['end_date']?.toString() ?? '');
        if (date != null) result[row['name'].toString()] = date;
      }
      return result;
    });
  }

  // ===========================================================
  // ADMINISTRATEURS FACULTAIRES
  // ===========================================================

  Future<List<Map<String, dynamic>>> loadAdmins() {
    return _guard(() async {
      final response = await _client
          .from('admins')
          .select(
            'id, full_name, email, is_active, faculty_id, created_at, '
            'academic_faculties(name)',
          )
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    });
  }

  /// Invitation d'un administrateur facultaire par l'Edge Function
  /// sécurisée `create-faculty-admin` (clé service_role côté serveur).
  Future<Map<String, dynamic>> inviteFacultyAdmin({
    required String fullName,
    required String email,
    required String facultyId,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'create-faculty-admin',
        body: {
          'action': 'create',
          'full_name': fullName.trim(),
          'email': email.trim().toLowerCase(),
          'faculty_id': facultyId,
        },
      );

      final data = response.data;
      if (data is Map && data['success'] == true) {
        return Map<String, dynamic>.from(data);
      }

      throw Exception(
        data is Map ? data['message'] ?? 'Création impossible.' : 'Création impossible.',
      );
    } on FunctionException catch (e) {
      final details = e.details;
      if (e.status == 404) {
        throw Exception(
          'La fonction « create-faculty-admin » n’est pas encore déployée '
          'sur Supabase.',
        );
      }
      throw Exception(
        details is Map
            ? details['message']?.toString() ?? 'Création impossible.'
            : 'Création impossible (HTTP ${e.status}).',
      );
    }
  }

  /// Activation / désactivation d'un administrateur facultaire.
  Future<void> setFacultyAdminActive({
    required String adminId,
    required bool active,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'create-faculty-admin',
        body: {
          'action': 'set_active',
          'admin_id': adminId,
          'is_active': active,
        },
      );

      final data = response.data;
      if (data is! Map || data['success'] != true) {
        throw Exception(
          data is Map ? data['message'] ?? 'Opération impossible.' : 'Opération impossible.',
        );
      }
    } on FunctionException catch (e) {
      final details = e.details;
      if (e.status == 404) {
        throw Exception(
          'La fonction « create-faculty-admin » n’est pas encore déployée '
          'sur Supabase.',
        );
      }
      throw Exception(
        details is Map
            ? details['message']?.toString() ?? 'Opération impossible.'
            : 'Opération impossible (HTTP ${e.status}).',
      );
    }
  }
}

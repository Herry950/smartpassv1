
import 'package:supabase_flutter/supabase_flutter.dart';

class CourseManagementService {
  CourseManagementService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Vérifie qu'une session utilisateur est active.
  void _checkSession() {
    if (_client.auth.currentUser == null) {
      throw Exception(
        'Votre session a expiré. Veuillez vous reconnecter.',
      );
    }
  }

  /// Récupère le profil de l'administrateur connecté.
  ///
  /// Administrateur facultaire :
  /// - facultyId et facultyName sont renseignés.
  /// - isCentralAdmin vaut false.
  ///
  /// Administrateur central :
  /// - facultyId et facultyName sont null.
  /// - isCentralAdmin vaut true.
  Future<Map<String, dynamic>> getCurrentAdminContext() async {
    _checkSession();

    try {
      final user = _client.auth.currentUser!;

      final admin = await _client
          .from('admins')
          .select('faculty_id, is_active')
          .eq('auth_user_id', user.id)
          .maybeSingle();

      if (admin == null || admin['is_active'] != true) {
        throw Exception(
          'Votre compte administrateur est introuvable ou désactivé.',
        );
      }

      final facultyId = admin['faculty_id']?.toString();

      if (facultyId == null || facultyId.isEmpty) {
        final isCentralAdmin =
            await _client.rpc('is_central_admin') as bool? ?? false;

        if (!isCentralAdmin) {
          throw Exception(
            'Votre profil administrateur ne possède aucune faculté affectée.',
          );
        }

        return {
          'isCentralAdmin': true,
          'facultyId': null,
          'facultyName': null,
        };
      }

      final faculty = await _client
          .from('academic_faculties')
          .select('id, name')
          .eq('id', facultyId)
          .eq('is_active', true)
          .maybeSingle();

      if (faculty == null) {
        throw Exception(
          'La faculté associée à votre compte est introuvable ou inactive.',
        );
      }

      return {
        'isCentralAdmin': false,
        'facultyId': faculty['id'].toString(),
        'facultyName': faculty['name'].toString(),
      };
    } on PostgrestException catch (error) {
      throw Exception(
        'Impossible de récupérer votre profil administrateur : '
        '${error.message}',
      );
    }
  }

  /// Détermine la faculté à utiliser pour une opération.
  ///
  /// Pour un administrateur facultaire, la faculté transmise par
  /// l'interface est ignorée : celle du profil Supabase est utilisée.
  ///
  /// Pour un administrateur central, la faculté choisie dans
  /// l'interface est conservée.
  Future<String> _resolveFacultyName(
    String requestedFaculty,
  ) async {
    final adminContext = await getCurrentAdminContext();

    if (adminContext['isCentralAdmin'] == true) {
      final facultyName = requestedFaculty.trim();

      if (facultyName.isEmpty) {
        throw Exception(
          'Veuillez sélectionner une faculté.',
        );
      }

      final faculty = await _client
          .from('academic_faculties')
          .select('name')
          .eq('name', facultyName)
          .eq('is_active', true)
          .maybeSingle();

      if (faculty == null) {
        throw Exception(
          'La faculté sélectionnée est introuvable ou inactive.',
        );
      }

      return faculty['name'].toString();
    }

    final facultyName = adminContext['facultyName']?.toString();

    if (facultyName == null || facultyName.isEmpty) {
      throw Exception(
        'Impossible de déterminer votre faculté.',
      );
    }

    return facultyName;
  }

  /// Récupère les facultés actives.
  ///
  /// Cette méthode reste disponible pour l'administrateur central.
  Future<List<Map<String, dynamic>>> getFaculties() async {
    _checkSession();

    try {
      final response = await _client
          .from('academic_faculties')
          .select('id, name')
          .eq('is_active', true)
          .order('name');

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (error) {
      throw Exception(
        'Impossible de récupérer les facultés : ${error.message}',
      );
    }
  }

  /// Récupère les départements actifs d'une faculté.
  Future<List<Map<String, dynamic>>> getDepartments(
    String facultyId,
  ) async {
    _checkSession();

    try {
      final response = await _client
          .from('academic_departments')
          .select(
            'id, faculty_id, name, minimum_promotion_rank',
          )
          .eq('faculty_id', facultyId)
          .eq('is_active', true)
          .order('name');

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (error) {
      throw Exception(
        'Impossible de récupérer les départements : ${error.message}',
      );
    }
  }

  /// Récupère les promotions affectées à une faculté.
  ///
  /// Contrairement à getPromotions(), cette méthode utilise
  /// faculty_promotions comme source des affectations.
  ///
  /// Le rang minimum permet de filtrer les promotions pour
  /// un département donné.
  Future<List<Map<String, dynamic>>> getFacultyPromotions({
    required String facultyId,
    int minimumRank = 0,
  }) async {
    _checkSession();

    final normalizedFacultyId = facultyId.trim();

    if (normalizedFacultyId.isEmpty) {
      throw Exception(
        'Impossible de déterminer la faculté des promotions.',
      );
    }

    try {
      final faculty = await _client
          .from('academic_faculties')
          .select('id')
          .eq('id', normalizedFacultyId)
          .eq('is_active', true)
          .maybeSingle();

      if (faculty == null) {
        throw Exception(
          'La faculté sélectionnée est introuvable ou inactive.',
        );
      }

      final assignments = await _client
          .from('faculty_promotions')
          .select('promotion_code')
          .eq('faculty_id', normalizedFacultyId);

      final promotionCodes = assignments
          .map((row) => row['promotion_code'].toString())
          .toSet()
          .toList();

      if (promotionCodes.isEmpty) {
        return [];
      }

      final response = await _client
          .from('academic_promotions')
          .select('code, rank')
          .inFilter('code', promotionCodes)
          .gte('rank', minimumRank)
          .order('rank');

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (error) {
      throw Exception(
        'Impossible de récupérer les promotions de la faculté : '
        '${error.message}',
      );
    }
  }

  /// Récupère les promotions à partir du rang minimum autorisé.
  ///
  /// Ancienne méthode conservée pour ne pas casser les appels
  /// existants dans les autres fichiers.
  Future<List<Map<String, dynamic>>> getPromotions({
    required int minimumRank,
  }) async {
    _checkSession();

    try {
      final response = await _client
          .from('academic_promotions')
          .select('code, rank')
          .gte('rank', minimumRank)
          .order('rank');

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (error) {
      throw Exception(
        'Impossible de récupérer les promotions : ${error.message}',
      );
    }
  }

  /// Récupère les cours accessibles à l'administrateur.
  ///
  /// L'administrateur facultaire ne récupère que les cours de sa faculté.
  /// L'administrateur central conserve la vue globale.
  Future<List<Map<String, dynamic>>> getCourses() async {
    _checkSession();

    try {
      final adminContext = await getCurrentAdminContext();

      var query = _client
          .from('courses')
          .select();

      if (adminContext['isCentralAdmin'] != true) {
        final facultyName =
            adminContext['facultyName']?.toString();

        if (facultyName == null || facultyName.isEmpty) {
          throw Exception(
            'Impossible de déterminer votre faculté.',
          );
        }

        query = query.eq('faculty', facultyName);
      }

      final response = await query.order(
        'created_at',
        ascending: false,
      );

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (error) {
      throw Exception(
        'Impossible de récupérer les cours : ${error.message}',
      );
    }
  }

  /// Crée un cours de faculté sans département.
  ///
  /// La fonction de vérification SQL contrôle notamment :
  /// - l'existence et l'activité de la faculté ;
  /// - l'affectation de la promotion à cette faculté ;
  /// - l'absence de département ;
  /// - l'absence d'associations dans course_departments.
  ///
  /// Pour un administrateur facultaire, la faculté est déterminée
  /// automatiquement depuis son profil Supabase.
  Future<Map<String, dynamic>> createFacultyCourse({
    required String code,
    required String name,
    required String faculty,
    required String promotion,
    int? credits,
  }) async {
    _checkSession();

    final normalizedCode = code.trim().toUpperCase();
    final normalizedName = name.trim();
    final normalizedPromotion = promotion.trim().toUpperCase();

    if (normalizedCode.isEmpty ||
        normalizedName.isEmpty ||
        normalizedPromotion.isEmpty) {
      throw Exception(
        'Le code, le nom et la promotion sont obligatoires.',
      );
    }

    if (credits != null && credits <= 0) {
      throw Exception(
        'Le nombre de crédits doit être supérieur à zéro.',
      );
    }

    try {
      final normalizedFaculty =
          await _resolveFacultyName(faculty);

      final response = await _client
          .from('courses')
          .insert({
            'code': normalizedCode,
            'name': normalizedName,
            'faculty': normalizedFaculty,
            'department': null,
            'promotion': normalizedPromotion,
            'credits': credits,
            'is_active': true,
            'course_type': 'faculty',
          })
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw Exception(
          'Ce code de cours existe déjà. Choisissez un autre code.',
        );
      }

      throw Exception(
        'Impossible de créer le cours de faculté : ${error.message}',
      );
    }
  }

  /// Crée un cours départemental.
  ///
  /// Pour un administrateur facultaire, la faculté est déterminée
  /// automatiquement depuis son profil Supabase.
  ///
  /// Pour un administrateur central, la faculté transmise est utilisée.
  Future<Map<String, dynamic>> createCourse({
    required String code,
    required String name,
    required String faculty,
    required String department,
    required String promotion,
    int? credits,
  }) async {
    _checkSession();

    final normalizedCode = code.trim().toUpperCase();
    final normalizedName = name.trim();
    final normalizedDepartment = department.trim();
    final normalizedPromotion = promotion.trim().toUpperCase();

    if (normalizedCode.isEmpty ||
        normalizedName.isEmpty ||
        normalizedDepartment.isEmpty ||
        normalizedPromotion.isEmpty) {
      throw Exception(
        'Le code, le nom, le département et la promotion sont obligatoires.',
      );
    }

    if (credits != null && credits <= 0) {
      throw Exception(
        'Le nombre de crédits doit être supérieur à zéro.',
      );
    }

    try {
      final normalizedFaculty =
          await _resolveFacultyName(faculty);

      final response = await _client
          .from('courses')
          .insert({
            'code': normalizedCode,
            'name': normalizedName,
            'faculty': normalizedFaculty,
            'department': normalizedDepartment,
            'promotion': normalizedPromotion,
            'credits': credits,
            'is_active': true,
            'course_type': 'departmental',
          })
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw Exception(
          'Ce code de cours existe déjà. Choisissez un autre code.',
        );
      }

      throw Exception(
        'Impossible de créer le cours : ${error.message}',
      );
    }
  }

  /// Crée un cours tronc-commun concernant plusieurs départements.
  ///
  /// La fonction SQL create_common_core_course :
  /// - vérifie les droits de l'administrateur ;
  /// - détermine automatiquement la faculté pour un administrateur
  ///   facultaire ;
  /// - conserve le choix de faculté pour l'administrateur central ;
  /// - vérifie les départements et le rang minimum ;
  /// - crée le cours et ses associations dans une transaction.
  Future<Map<String, dynamic>> createCommonCoreCourse({
    required String code,
    required String name,
    required String faculty,
    required String promotion,
    required List<String> departmentIds,
    int? credits,
  }) async {
    _checkSession();

    final normalizedCode = code.trim().toUpperCase();
    final normalizedName = name.trim();
    final normalizedFaculty = faculty.trim();
    final normalizedPromotion = promotion.trim().toUpperCase();

    if (normalizedCode.isEmpty ||
        normalizedName.isEmpty ||
        normalizedPromotion.isEmpty) {
      throw Exception(
        'Le code, le nom et la promotion sont obligatoires.',
      );
    }

    final adminContext = await getCurrentAdminContext();

    if (adminContext['isCentralAdmin'] == true &&
        normalizedFaculty.isEmpty) {
      throw Exception(
        'Veuillez sélectionner une faculté.',
      );
    }

    if (departmentIds.length < 2) {
      throw Exception(
        'Un cours tronc-commun doit concerner au moins deux départements.',
      );
    }

    final normalizedDepartmentIds = departmentIds
        .map((id) => id.trim())
        .toList();

    if (normalizedDepartmentIds.any((id) => id.isEmpty)) {
      throw Exception(
        'Un identifiant de département est invalide.',
      );
    }

    if (normalizedDepartmentIds.toSet().length !=
        normalizedDepartmentIds.length) {
      throw Exception(
        'Un même département ne peut pas être sélectionné plusieurs fois.',
      );
    }

    if (credits != null && credits <= 0) {
      throw Exception(
        'Le nombre de crédits doit être supérieur à zéro.',
      );
    }

    try {
      final courseId = await _client.rpc(
        'create_common_core_course',
        params: {
          'p_code': normalizedCode,
          'p_name': normalizedName,
          'p_faculty': normalizedFaculty,
          'p_promotion': normalizedPromotion,
          'p_department_ids': normalizedDepartmentIds,
          'p_credits': credits,
        },
      );

      if (courseId == null || courseId.toString().isEmpty) {
        throw Exception(
          'La création du cours commun n’a retourné aucun identifiant.',
        );
      }

      final response = await _client
          .from('courses')
          .select()
          .eq('id', courseId.toString())
          .single();

      return Map<String, dynamic>.from(response);
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw Exception(
          'Ce code de cours existe déjà. Choisissez un autre code.',
        );
      }

      throw Exception(
        'Impossible de créer le cours tronc-commun : ${error.message}',
      );
    }
  }

  /// Modifie les informations d'un cours.
  ///
  /// Pour un administrateur facultaire, la faculté du profil est utilisée.
  Future<Map<String, dynamic>> updateCourse({
    required String courseId,
    required String code,
    required String name,
    required String faculty,
    required String department,
    required String promotion,
    int? credits,
  }) async {
    _checkSession();

    final normalizedCode = code.trim().toUpperCase();
    final normalizedName = name.trim();
    final normalizedDepartment = department.trim();
    final normalizedPromotion = promotion.trim().toUpperCase();

    if (normalizedCode.isEmpty ||
        normalizedName.isEmpty ||
        normalizedDepartment.isEmpty ||
        normalizedPromotion.isEmpty) {
      throw Exception(
        'Le code, le nom, le département et la promotion sont obligatoires.',
      );
    }

    if (credits != null && credits <= 0) {
      throw Exception(
        'Le nombre de crédits doit être supérieur à zéro.',
      );
    }

    try {
      final normalizedFaculty =
          await _resolveFacultyName(faculty);

      final response = await _client
          .from('courses')
          .update({
            'code': normalizedCode,
            'name': normalizedName,
            'faculty': normalizedFaculty,
            'department': normalizedDepartment,
            'promotion': normalizedPromotion,
            'credits': credits,
          })
          .eq('id', courseId)
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw Exception(
          'Ce code de cours est déjà utilisé.',
        );
      }

      throw Exception(
        'Impossible de modifier le cours : ${error.message}',
      );
    }
  }

  /// Active ou désactive un cours.
  Future<void> setCourseStatus({
    required String courseId,
    required bool isActive,
  }) async {
    _checkSession();

    try {
      final response = await _client
          .from('courses')
          .update({'is_active': isActive})
          .eq('id', courseId)
          .select('id');

      if (response.isEmpty) {
        throw Exception(
          'Aucun cours modifié. Vérifiez vos droits ou le cours sélectionné.',
        );
      }
    } on PostgrestException catch (error) {
      throw Exception(
        'Impossible de modifier le statut : ${error.message}',
      );
    }
  }

  /// Supprime un cours.
  Future<void> deleteCourse(String courseId) async {
    _checkSession();

    try {
      final response = await _client
          .from('courses')
          .delete()
          .eq('id', courseId)
          .select('id');

      if (response.isEmpty) {
        throw Exception(
          'Aucun cours supprimé. Vérifiez vos droits ou le cours sélectionné.',
        );
      }
    } on PostgrestException catch (error) {
      if (error.code == '23503') {
        throw Exception(
          'Ce cours est utilisé par une session d’examen. '
          'Il ne peut pas être supprimé.',
        );
      }

      throw Exception(
        'Impossible de supprimer le cours : ${error.message}',
      );
    }
  }
}

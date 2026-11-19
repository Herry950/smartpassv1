
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AssistantAccessException implements Exception {
  final String message;

  const AssistantAccessException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  AuthService._();

  static final SupabaseClient _client =
      Supabase.instance.client;

  static const String assistantInactiveMessage =
      'Accès refusé : votre compte assistant est actuellement '
      'désactivé. Veuillez contacter l’administration de votre '
      'faculté pour réactiver votre compte.';

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Inscription d'un étudiant avec création automatique
  // de son profil par le déclencheur Supabase.
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String matricule,
    required String fullName,
    required String faculty,
    required String promotion,
    String department = '',
  }) async {
    final normalizedMatricule = matricule.trim();
    final normalizedFullName = fullName.trim();
    final normalizedFaculty = faculty.trim();
    final normalizedPromotion = promotion.trim();
    final normalizedDepartment = department.trim();

    if (normalizedMatricule.isEmpty ||
        normalizedFullName.isEmpty ||
        normalizedFaculty.isEmpty ||
        normalizedPromotion.isEmpty) {
      throw ArgumentError(
        'Veuillez compléter toutes les informations obligatoires.',
      );
    }

    return await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'account_type': 'student',
        'matricule': normalizedMatricule,
        'full_name': normalizedFullName,
        'faculty': normalizedFaculty,
        'promotion': normalizedPromotion,
        'department': normalizedDepartment,
      },
    );
  }

  static Future<void> signOut() async {
    clearRoleCache();
    await _client.auth.signOut();
  }

  // ===========================================================
  // RÔLES ET ESPACES
  // ===========================================================

  /// Rôles reconnus par l'application.
  static const String roleStudent = 'student';
  static const String roleAssistant = 'assistant';
  static const String roleFacultyAdmin = 'admin';
  static const String roleCentralAdmin = 'central_admin';
  static const String roleInactiveAdmin = 'admin_inactive';

  static String? _cachedRoleUserId;
  static String? _cachedRole;

  static void clearRoleCache() {
    _cachedRoleUserId = null;
    _cachedRole = null;
  }

  /// Rôle de l'utilisateur connecté, mis en cache pour la navigation.
  static Future<String?> getCachedUserRole() async {
    final user = currentUser;

    if (user == null) {
      clearRoleCache();
      return null;
    }

    if (_cachedRoleUserId == user.id && _cachedRole != null) {
      return _cachedRole;
    }

    final role = await getUserRole();
    _cachedRoleUserId = user.id;
    _cachedRole = role;
    return role;
  }

  /// Page d'accueil de chaque rôle.
  static String? homeRouteForRole(String? role) {
    switch (role) {
      case roleStudent:
        return '/student';
      case roleAssistant:
        return '/assistant';
      case roleFacultyAdmin:
        return '/admin';
      case roleCentralAdmin:
        return '/central';
      default:
        return null;
    }
  }

  static User? get currentUser =>
      _client.auth.currentUser;

  static Stream<AuthState> get authState =>
      _client.auth.onAuthStateChange;

  static Future<String?> getUserRole() async {
    final user = currentUser;

    if (user == null) return null;

    final uid = user.id;

    final student = await _client
        .from('students')
        .select('id')
        .eq('auth_user_id', uid)
        .maybeSingle();

    if (student != null) {
      return "student";
    }

    final assistant = await _client
        .from('assistants')
        .select('id')
        .eq('auth_user_id', uid)
        .maybeSingle();

    if (assistant != null) {
      return "assistant";
    }

    final admin = await _client
        .from('admins')
        .select('id, faculty_id, is_active')
        .eq('auth_user_id', uid)
        .maybeSingle();

    if (admin != null) {
      if (admin['is_active'] != true) {
        return roleInactiveAdmin;
      }

      // Le statut central est confirmé par le backend
      // (is_central_admin : compte actif et faculty_id IS NULL),
      // jamais par le libellé textuel du rôle.
      final isCentral =
          await _client.rpc('is_central_admin') as bool? ?? false;

      if (isCentral) {
        return roleCentralAdmin;
      }

      if (admin['faculty_id'] != null) {
        return roleFacultyAdmin;
      }

      return roleInactiveAdmin;
    }

    return null;
  }

  // Récupère le profil complet de l'assistant connecté,
  // y compris les informations de sa faculté.
  static Future<Map<String, dynamic>?> getAssistantProfile() async {
    final user = currentUser;

    if (user == null) {
      throw const AssistantAccessException(
        'Votre session a expiré. Veuillez vous reconnecter.',
      );
    }

    final assistant = await _client
        .from('assistants')
        .select('''
          id,
          employee_number,
          full_name,
          phone,
          email,
          is_active,
          faculty_id,
          faculty:academic_faculties(
            name,
            is_active
          )
        ''')
        .eq('auth_user_id', user.id)
        .maybeSingle();

    return assistant;
  }

  // Vérifie que l'assistant connecté possède un compte actif.
  // Cette méthode sera appelée avant les opérations réservées
  // aux assistants actifs.
  static Future<void> ensureAssistantIsActive() async {
    final user = currentUser;

    if (user == null) {
      throw const AssistantAccessException(
        'Votre session a expiré. Veuillez vous reconnecter.',
      );
    }

    final assistant = await _client
        .from('assistants')
        .select('is_active')
        .eq('auth_user_id', user.id)
        .maybeSingle();

    if (assistant == null) {
      throw const AssistantAccessException(
        'Profil assistant introuvable. Veuillez contacter '
        'l’administration de votre faculté.',
      );
    }

    final isActive = assistant['is_active'] == true;

    if (!isActive) {
      throw const AssistantAccessException(
        assistantInactiveMessage,
      );
    }
  }

  static Future<String?> getStudentId() async {
    final user = currentUser;

    if (user == null) return null;

    final result = await _client
        .from('students')
        .select('id')
        .eq('auth_user_id', user.id)
        .maybeSingle();

    return result?['id'];
  }

  // Vérification de la session JWT.
  static bool hasActiveSession() {
    return _client.auth.currentSession != null;
  }

  static Future<void> testReceiptVerification() async {
    final client = Supabase.instance.client;

    try {
      final response = await client.functions.invoke(
        'get-receipt',
        body: {
          'receipt_number': 'SP-2026-000003',
        },
      );

      debugPrint(
        'Résultat vérification reçu : ${response.data}',
      );
    } on FunctionException catch (e) {
      debugPrint('Erreur fonction : ${e.status}');
      debugPrint('Détails : ${e.details}');
    } catch (e) {
      debugPrint('Erreur test reçu : $e');
    }
  }

  // Méthode de diagnostic.
  static String getSessionStatus() {
    final session = _client.auth.currentSession;

    if (session == null) {
      return 'NO_SESSION';
    }

    return 'SESSION_ACTIVE';
  }
}

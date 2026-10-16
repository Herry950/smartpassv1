import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';//pour jwt

class AuthService {
  AuthService._();

  static final SupabaseClient _client =
      Supabase.instance.client;

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
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
        .select('id')
        .eq('auth_user_id', uid)
        .maybeSingle();

    if (admin != null) {
      return "admin";
    }

    return null;
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
//ajout pour tester les  jwt
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

    debugPrint('Résultat vérification reçu : ${response.data}');
  } on FunctionException catch (e) {
    debugPrint('Erreur fonction : ${e.status}');
    debugPrint('Détails : ${e.details}');
  } catch (e) {
    debugPrint('Erreur test reçu : $e');
  }
}//about jwt
}
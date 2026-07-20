import 'package:supabase_flutter/supabase_flutter.dart';

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
}
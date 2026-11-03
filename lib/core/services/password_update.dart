//le service pour la mise à jour du mot de passe
//il s'agit d'une réauthentification avant de modifier le mot de passe
import 'package:supabase_flutter/supabase_flutter.dart';

class PasswordUpdateService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Modifie le mot de passe de l'utilisateur actuellement connecté.
  /// 
  /// 1. Re-vérifie le mot de passe actuel en tentant une re-connexion.
  /// 2. Met à jour le mot de passe dans Supabase Auth.
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final userEmail = _supabase.auth.currentUser?.email;

    if (userEmail == null) {
      throw const AuthException('Aucun utilisateur connecté.');
    }

    // 1. Re-authentification de sécurité
    await _supabase.auth.signInWithPassword(
      email: userEmail,
      password: currentPassword,
    );

    // 2. Mise à jour du mot de passe dans Supabase Auth
    await _supabase.auth.updateUser(
      UserAttributes(
        password: newPassword,
      ),
    );
  }
}
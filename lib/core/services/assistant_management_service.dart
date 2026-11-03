import 'package:supabase_flutter/supabase_flutter.dart';

class AssistantManagementService {
  AssistantManagementService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  // Vérifier les droits de l'administrateur sans créer de compte.
  Future<Map<String, dynamic>> testAdminAuthorization() async {
    if (_client.auth.currentUser == null) {
      throw Exception(
        'Votre session a expiré. Veuillez vous reconnecter.',
      );
    }

    try {
      final response = await _client.functions.invoke(
        'create-assistant',
        body: {
          'full_name': 'Test SmartPass',
          'email': 'test-validation@example.com',
          'employee_number': 'TEST-DRY-RUN',
          'phone': '',
          'dry_run': true,
        },
      );

      final data = response.data;

      if (data is! Map) {
        throw Exception('Réponse invalide du serveur.');
      }

      final result = Map<String, dynamic>.from(data);

      if (response.status != 200 ||
          result['success'] != true ||
          result['code'] != 'ADMIN_AUTHORIZED') {
        throw Exception(
          result['message'] ?? 'Échec de la vérification.',
        );
      }

      return result;
    } on FunctionException catch (error) {
      throw Exception(
        'Erreur serveur (${error.status}) : ${error.details}',
      );
    }
  }

  // Créer un compte assistant et envoyer son invitation.
  Future<Map<String, dynamic>> createAssistant({
    required String fullName,
    required String email,
    String employeeNumber = '',
    String phone = '',
  }) async {
    if (_client.auth.currentUser == null) {
      throw Exception(
        'Votre session a expiré. Veuillez vous reconnecter.',
      );
    }

    try {
      final response = await _client.functions.invoke(
        'create-assistant',
        body: {
          'full_name': fullName.trim(),
          'email': email.trim().toLowerCase(),
          'employee_number': employeeNumber.trim(),
          'phone': phone.trim(),
        },
      );

      final data = response.data;

      if (data is! Map) {
        throw Exception('Réponse invalide du serveur.');
      }

      final result = Map<String, dynamic>.from(data);

      if (response.status != 201 ||
          result['success'] != true) {
        throw Exception(
          result['message'] ??
              'Impossible de créer le compte assistant.',
        );
      }

      return result;
    } on FunctionException catch (error) {
      throw Exception(
        'Erreur serveur (${error.status}) : ${error.details}',
      );
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

class RoomManagementService {
  RoomManagementService({SupabaseClient? client})
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

  /// Récupère toutes les salles.
  Future<List<Map<String, dynamic>>> getRooms() async {
    _checkSession();

    try {
      final response = await _client
          .from('rooms')
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (error) {
      throw Exception(
        'Impossible de récupérer les salles : ${error.message}',
      );
    }
  }

  /// Crée une nouvelle salle.
  Future<Map<String, dynamic>> createRoom({
    required String code,
    required String name,
    String? building,
    required int capacity,
  }) async {
    _checkSession();

    final normalizedCode = code.trim().toUpperCase();
    final normalizedName = name.trim();
    final normalizedBuilding = building?.trim();

    if (normalizedCode.isEmpty || normalizedName.isEmpty) {
      throw Exception(
        'Le code et le nom de la salle sont obligatoires.',
      );
    }

    if (capacity <= 0) {
      throw Exception(
        'La capacité doit être supérieure à zéro.',
      );
    }

    try {
      final response = await _client
          .from('rooms')
          .insert({
            'code': normalizedCode,
            'name': normalizedName,
            'building': normalizedBuilding == null ||
                    normalizedBuilding.isEmpty
                ? null
                : normalizedBuilding,
            'capacity': capacity,
            'is_active': true,
          })
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw Exception(
          'Ce code de salle existe déjà. Choisissez un autre code.',
        );
      }

      throw Exception(
        'Impossible de créer la salle : ${error.message}',
      );
    }
  }

  /// Modifie les informations d'une salle.
  Future<Map<String, dynamic>> updateRoom({
    required String roomId,
    required String code,
    required String name,
    String? building,
    required int capacity,
  }) async {
    _checkSession();

    final normalizedCode = code.trim().toUpperCase();
    final normalizedName = name.trim();
    final normalizedBuilding = building?.trim();

    if (normalizedCode.isEmpty || normalizedName.isEmpty) {
      throw Exception(
        'Le code et le nom de la salle sont obligatoires.',
      );
    }

    if (capacity <= 0) {
      throw Exception(
        'La capacité doit être supérieure à zéro.',
      );
    }

    try {
      final response = await _client
          .from('rooms')
          .update({
            'code': normalizedCode,
            'name': normalizedName,
            'building': normalizedBuilding == null ||
                    normalizedBuilding.isEmpty
                ? null
                : normalizedBuilding,
            'capacity': capacity,
          })
          .eq('id', roomId)
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw Exception(
          'Ce code de salle est déjà utilisé.',
        );
      }

      throw Exception(
        'Impossible de modifier la salle : ${error.message}',
      );
    }
  }

  /// Active ou désactive une salle.
  Future<void> setRoomStatus({
    required String roomId,
    required bool isActive,
  }) async {
    _checkSession();

    try {
      final response = await _client
          .from('rooms')
          .update({'is_active': isActive})
          .eq('id', roomId)
          .select('id');

      if (response.isEmpty) {
        throw Exception(
          'Aucune salle modifiée. Vérifiez vos droits ou la salle sélectionnée.',
        );
      }
    } on PostgrestException catch (error) {
      throw Exception(
        'Impossible de modifier le statut : ${error.message}',
      );
    }
  }

  /// Supprime une salle.
  Future<void> deleteRoom(String roomId) async {
    _checkSession();

    try {
      final response = await _client
          .from('rooms')
          .delete()
          .eq('id', roomId)
          .select('id');

      if (response.isEmpty) {
        throw Exception(
          'Aucune salle supprimée. Vérifiez vos droits ou la salle sélectionnée.',
        );
      }
    } on PostgrestException catch (error) {
      if (error.code == '23503') {
        throw Exception(
          'Cette salle est utilisée par une session d’examen. '
          'Elle ne peut pas être supprimée.',
        );
      }

      throw Exception(
        'Impossible de supprimer la salle : ${error.message}',
      );
    }
  }
}

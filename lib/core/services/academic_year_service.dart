import 'package:supabase_flutter/supabase_flutter.dart';

class AcademicYearService {
  AcademicYearService({SupabaseClient? client})
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

  /// Récupère toutes les années académiques.
  Future<List<Map<String, dynamic>>> getAcademicYears() async {
    _checkSession();

    try {
      final response = await _client
          .from('academic_years')
          .select(
            'id, name, start_date, end_date, is_current, created_at',
          )
          .order('start_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (error) {
      throw Exception(
        'Impossible de récupérer les années académiques : '
        '${error.message}',
      );
    }
  }

  /// Récupère l'année académique actuellement opérationnelle.
  ///
  /// Retourne null si aucune année n'est définie comme courante.
  Future<Map<String, dynamic>?> getCurrentAcademicYear() async {
    _checkSession();

    try {
      final response = await _client
          .from('academic_years')
          .select(
            'id, name, start_date, end_date, is_current',
          )
          .eq('is_current', true)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Map<String, dynamic>.from(response);
    } on PostgrestException catch (error) {
      throw Exception(
        'Impossible de récupérer l’année académique courante : '
        '${error.message}',
      );
    }
  }

  /// Crée une nouvelle année académique.
  ///
  /// Une nouvelle année n'est jamais activée automatiquement.
  Future<Map<String, dynamic>> createAcademicYear({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _checkSession();

    final normalizedName = name.trim();

    if (normalizedName.isEmpty) {
      throw Exception(
        'Le nom de l’année académique est obligatoire.',
      );
    }

    if (!startDate.isBefore(endDate)) {
      throw Exception(
        'La date de début doit être antérieure à la date de fin.',
      );
    }

    final formattedStartDate =
        startDate.toIso8601String().split('T').first;

    final formattedEndDate =
        endDate.toIso8601String().split('T').first;

    try {
      final response = await _client
          .from('academic_years')
          .insert({
            'name': normalizedName,
            'start_date': formattedStartDate,
            'end_date': formattedEndDate,
            'is_current': false,
          })
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw Exception(
          'Cette année académique existe déjà.',
        );
      }

      throw Exception(
        'Impossible de créer l’année académique : ${error.message}',
      );
    }
  }

  /// Définit une année comme année académique courante.
  ///
  /// Le changement est effectué exclusivement par la fonction SQL
  /// sécurisée set_current_academic_year.
  Future<void> setCurrentAcademicYear(String academicYearId) async {
    _checkSession();

    final normalizedId = academicYearId.trim();

    if (normalizedId.isEmpty) {
      throw Exception(
        'L’identifiant de l’année académique est invalide.',
      );
    }

    try {
      await _client.rpc(
        'set_current_academic_year',
        params: {
          'p_academic_year_id': normalizedId,
        },
      );
    } on PostgrestException catch (error) {
      if (error.code == '42501') {
        throw Exception(
          'Vous n’avez pas l’autorisation de changer l’année courante.',
        );
      }

      if (error.code == 'P0002') {
        throw Exception(
          'L’année académique sélectionnée est introuvable.',
        );
      }

      throw Exception(
        'Impossible de changer l’année académique courante : '
        '${error.message}',
      );
    }
  }
}
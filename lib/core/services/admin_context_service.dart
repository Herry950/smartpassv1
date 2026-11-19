import 'package:supabase_flutter/supabase_flutter.dart';

/// Profil de l'administrateur connecté.
class AdminContext {
  const AdminContext({
    required this.id,
    required this.fullName,
    required this.email,
    required this.isCentral,
    this.facultyId,
    this.facultyName,
  });

  final String id;
  final String fullName;
  final String email;
  final bool isCentral;
  final String? facultyId;
  final String? facultyName;
}

/// Contexte et statistiques des espaces administrateur.
///
/// Toutes les lectures passent par les politiques RLS :
/// un administrateur facultaire ne compte que les données
/// de sa faculté, l'administrateur central voit l'ensemble.
class AdminContextService {
  AdminContextService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<AdminContext> load() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Votre session a expiré. Veuillez vous reconnecter.');
    }

    final admin = await _client
        .from('admins')
        .select('id, full_name, email, faculty_id, is_active')
        .eq('auth_user_id', user.id)
        .maybeSingle();

    if (admin == null || admin['is_active'] != true) {
      throw Exception('Aucun compte administrateur actif n’a été trouvé.');
    }

    // Statut central confirmé par le backend.
    final isCentral =
        await _client.rpc('is_central_admin') as bool? ?? false;

    final facultyId = admin['faculty_id'] as String?;
    String? facultyName;

    if (facultyId != null) {
      final faculty = await _client
          .from('academic_faculties')
          .select('name')
          .eq('id', facultyId)
          .maybeSingle();

      facultyName = faculty?['name'] as String?;
    }

    return AdminContext(
      id: admin['id'] as String,
      fullName: (admin['full_name'] ?? '').toString(),
      email: (admin['email'] ?? user.email ?? '').toString(),
      isCentral: isCentral,
      facultyId: facultyId,
      facultyName: facultyName,
    );
  }

  Future<int> _count(PostgrestFilterBuilder<List<Map<String, dynamic>>> query) async {
    final response = await query.count(CountOption.exact);
    return response.count;
  }

  /// Statistiques de la faculté de l'administrateur facultaire.
  Future<Map<String, int>> loadFacultyStats(AdminContext context) async {
    final facultyId = context.facultyId;
    final facultyName = context.facultyName;

    if (facultyId == null || facultyName == null) {
      throw Exception('Ce compte n’est associé à aucune faculté.');
    }

    final results = await Future.wait([
      _count(
        _client.from('students').select('id').eq('faculty', facultyName),
      ),
      _count(
        _client
            .from('assistants')
            .select('id')
            .eq('faculty_id', facultyId)
            .eq('is_active', true),
      ),
      _count(
        _client
            .from('exam_sessions')
            .select('id')
            .eq('faculty_id', facultyId)
            .eq('payment_open', true),
      ),
      _count(
        _client
            .from('payments')
            .select('id, exam_sessions!inner(faculty_id)')
            .eq('status', 'validated')
            .eq('exam_sessions.faculty_id', facultyId),
      ),
    ]);

    return {
      'students': results[0],
      'active_assistants': results[1],
      'open_sessions': results[2],
      'validated_payments': results[3],
    };
  }

  /// Statistiques globales (non financières) de l'administrateur central.
  Future<Map<String, int>> loadCentralStats() async {
    final results = await Future.wait([
      _count(_client.from('academic_faculties').select('id')),
      _count(
        _client
            .from('academic_departments')
            .select('id')
            .eq('is_active', true),
      ),
      _count(_client.from('students').select('id')),
      _count(
        _client.from('admins').select('id').not('faculty_id', 'is', null),
      ),
      _count(_client.from('rooms').select('id').eq('is_active', true)),
      _count(_client.from('academic_years').select('id')),
    ]);

    // Aucune donnée financière (paiements, sessions de paiement, remises) :
    // l'administration centrale n'a pas d'accès financier.
    return {
      'faculties': results[0],
      'departments': results[1],
      'students': results[2],
      'faculty_admins': results[3],
      'rooms': results[4],
      'academic_years': results[5],
    };
  }
}

/// Contenu du QR code de la carte étudiante SmartPass.
///
/// Format : `<id étudiant>|<matricule>|<année académique>`.
///
/// Le QR code sert uniquement à IDENTIFIER l'étudiant. Il ne prouve ni
/// le paiement ni l'autorisation : l'assistant relance la vérification
/// par matricule (mêmes règles RLS et mêmes contrôles), puis l'application
/// confirme que l'identifiant de la carte correspond bien à l'étudiant trouvé.
class StudentCardQrData {
  const StudentCardQrData({
    required this.studentId,
    required this.matricule,
    required this.academicYear,
  });

  final String studentId;
  final String matricule;
  final String academicYear;

  static final RegExp _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static String encode({
    required String studentId,
    required String matricule,
    required String academicYear,
  }) {
    return '$studentId|$matricule|$academicYear';
  }

  /// Retourne null si le contenu n'est pas un QR de carte SmartPass.
  static StudentCardQrData? tryParse(String raw) {
    final parts = raw.trim().split('|');

    if (parts.length != 3) return null;

    final id = parts[0].trim();
    final matricule = parts[1].trim();
    final year = parts[2].trim();

    if (!_uuid.hasMatch(id) || matricule.isEmpty || year.isEmpty) {
      return null;
    }

    return StudentCardQrData(
      studentId: id,
      matricule: matricule,
      academicYear: year,
    );
  }
}

/// Numéro de reçu SmartPass (ex. SP-2026-000123), contenu du QR des reçus.
final RegExp receiptNumberPattern = RegExp(r'^SP-\d{4}-\d{6}$');

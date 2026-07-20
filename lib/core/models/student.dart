class Student {
  final String id;
  final String? authUserId;

  final String fullName;
  final String matricule;

  final String faculty;
  final String department;
  final String promotion;
  final String academicYear;

  final String? photoUrl;

  final DateTime? expiryDate;

  final bool paymentValidated;
  final bool examAuthorized;

  const Student({
    required this.id,
    this.authUserId,
    required this.fullName,
    required this.matricule,
    required this.faculty,
    required this.department,
    required this.promotion,
    required this.academicYear,
    this.photoUrl,
    this.expiryDate,
    this.paymentValidated = false,
    this.examAuthorized = false,
  });

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as String,
      authUserId: map['auth_user_id'] as String?,
      fullName: map['full_name'] as String,
      matricule: map['matricule'] as String,
      faculty: map['faculty'] as String,
      department: map['department'] as String,
      promotion: map['promotion'] as String,
      academicYear: map['academic_year'] as String,
      photoUrl: map['photo_url'] as String?,
      paymentValidated: map['payment_validated'] ?? false,
      examAuthorized: map['exam_authorized'] ?? false,
      expiryDate: map['expiry_date'] == null
          ? null
          : DateTime.parse(map['expiry_date']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'auth_user_id': authUserId,
      'full_name': fullName,
      'matricule': matricule,
      'faculty': faculty,
      'department': department,
      'promotion': promotion,
      'academic_year': academicYear,
      'photo_url': photoUrl,
      'payment_validated': paymentValidated,
      'exam_authorized': examAuthorized,
      'expiry_date': expiryDate?.toIso8601String(),
    };
  }
}
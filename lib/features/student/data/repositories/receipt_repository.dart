import 'package:supabase_flutter/supabase_flutter.dart';

class ReceiptRepository {
ReceiptRepository();

final SupabaseClient _supabase =
Supabase.instance.client;

Future<Map<String, dynamic>?> getLatestValidatedPayment() async {
final user = _supabase.auth.currentUser;

if (user == null) {
  throw Exception(
    "Utilisateur non connecté",
  );
}

// Récupérer l'étudiant connecté.
final student = await _supabase
    .from('students')
    .select('id')
    .eq('auth_user_id', user.id)
    .single();

final studentId = student['id'];

// Récupérer le dernier paiement validé
// avec toutes les informations nécessaires
// de l'étudiant.
final payment = await _supabase
    .from('payments')
    .select('''
      id,
      receipt_number,
      amount,
      currency,
      payment_method,
      payment_channel,
      provider,
      flutterwave_transaction_id,
      status,
      paid_at,
      created_at,
      receipt_signature,
      students (
        full_name,
        matricule,
        faculty,
        department,
        promotion
      )
    ''')
    .eq('student_id', studentId)
    .eq('status', 'validated')
    .order(
      'paid_at',
      ascending: false,
    )
    .limit(1)
    .maybeSingle();

if (payment == null) {
  return null;
}

// Les données de l'étudiant sont retournées
// dans un objet imbriqué par Supabase.
final studentData =
    payment['students'] as Map<String, dynamic>?;

// Construire une map uniforme pour PaymentReceipt.
return {
  'payment_id': payment['id'],

  'receipt_number':
      payment['receipt_number'],

  'student':
      studentData?['full_name'] ?? 'N/A',

  'matricule':
      studentData?['matricule'] ?? 'N/A',

  'faculty':
      studentData?['faculty'] ?? 'N/A',

  'department':
      studentData?['department'] ?? 'N/A',

  'promotion':
      studentData?['promotion'] ?? 'N/A',

  'amount':
      payment['amount'],

  'currency':
      payment['currency'],

  'method':
      payment['payment_method'] ?? 'N/A',

  'provider':
      payment['provider'] ?? 'N/A',

  'transaction':
      payment['flutterwave_transaction_id'] ?? '',

  'date':
      payment['paid_at'] ??
      payment['created_at'] ??
      '',

  'validated':
      payment['status'] == 'validated',

  'signature':
      payment['receipt_signature'] ?? '',
};

}
}
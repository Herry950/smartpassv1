class PaymentReceipt {
final String paymentId;

final String receiptNumber;

final String student;
final String matricule;

final String faculty;
final String department;
final String promotion;

final String amount;
final String currency;

final String method;
final String provider;

final String transaction;

final String date;

final bool validated;

final String signature;

const PaymentReceipt({
required this.paymentId,
required this.receiptNumber,
required this.student,
required this.matricule,
required this.faculty,
required this.department,
required this.promotion,
required this.amount,
required this.currency,
required this.method,
required this.provider,
required this.transaction,
required this.date,
required this.validated,
required this.signature,
});

factory PaymentReceipt.fromMap(
Map<String, dynamic> map,
) {
return PaymentReceipt(
paymentId: (
map['payment_id'] ??
map['id'] ??
''
).toString(),

  receiptNumber: (
    map['receipt_number'] ??
    'N/A'
  ).toString(),

  student: (
    map['student'] ??
    'N/A'
  ).toString(),

  matricule: (
    map['matricule'] ??
    'N/A'
  ).toString(),

  faculty: (
    map['faculty'] ??
    'N/A'
  ).toString(),

  department: (
    map['department'] ??
    'N/A'
  ).toString(),

  promotion: (
    map['promotion'] ??
    'N/A'
  ).toString(),

  amount: (
    map['amount'] ??
    '0'
  ).toString(),

  currency: (
    map['currency'] ??
    'USD'
  ).toString(),

  method: (
    map['method'] ??
    'N/A'
  ).toString(),

  provider: (
    map['provider'] ??
    'N/A'
  ).toString(),

  transaction: (
    map['transaction'] ??
    map['flutterwave_transaction_id'] ??
    ''
  ).toString(),

  date: (
    map['date'] ??
    map['paid_at'] ??
    map['created_at'] ??
    ''
  ).toString(),

  validated:
      map['validated'] == true ||
      map['status']?.toString().toLowerCase() ==
          'validated',

  signature: (
    map['signature'] ??
    map['receipt_signature'] ??
    ''
  ).toString(),
);

}

Map<String, dynamic> toMap() {
return {
'payment_id': paymentId,
'receipt_number': receiptNumber,
'student': student,
'matricule': matricule,
'faculty': faculty,
'department': department,
'promotion': promotion,
'amount': amount,
'currency': currency,
'method': method,
'provider': provider,
'transaction': transaction,
'date': date,
'validated': validated,
'signature': signature,
};
}
}
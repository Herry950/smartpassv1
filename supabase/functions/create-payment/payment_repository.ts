import { supabase } from "../_shared/supabase.ts";
import { Payment } from "../_shared/types.ts";

/// Erreur métier conservant le code et le message d'origine de PostgreSQL.
export class PaymentCreationError extends Error {
  constructor(
    message: string,
    public readonly code: string | undefined,
  ) {
    super(message);
    this.name = "PaymentCreationError";
  }
}

export async function createPendingPayment({
  studentId,
  examSessionId,
  amount,
  currency,
  txRef,
  paymentMethod,
}: {
  studentId: string;
  examSessionId: string;
  amount: number;
  currency: string;
  txRef: string;
  paymentMethod: string;
}): Promise<Payment> {
  console.log("========== ATOMIC PAYMENT CREATION ==========");
  console.log("Student ID :", studentId);
  console.log("Exam Session ID :", examSessionId);
  console.log("Amount :", amount);
  console.log("Currency :", currency);
  console.log("Payment Method :", paymentMethod);
  console.log("TX REF :", txRef);

  const { data, error } = await supabase.rpc(
    "create_pending_payment_atomic",
    {
      p_student_id: studentId,
      p_exam_session_id: examSessionId,
      p_amount: amount,
      p_currency: currency,
      p_payment_method: paymentMethod,
      p_tx_ref: txRef,
    },
  );

  if (error) {
    console.error("Échec de la création atomique :", {
      code: error.code,
      message: error.message,
      details: error.details,
      hint: error.hint,
    });

    throw new PaymentCreationError(
      error.message,
      error.code,
    );
  }

  if (!data) {
    throw new Error(
      "La fonction SQL n'a retourné aucun paiement.",
    );
  }

  const payment = data as Payment;

  console.log("Paiement créé atomiquement :", payment.id);
  console.log("Statut :", payment.status);
  console.log("TX REF enregistré :", payment.flutterwave_tx_ref);

  return payment;
}
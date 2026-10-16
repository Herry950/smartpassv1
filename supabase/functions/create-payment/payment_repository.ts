import { supabase } from "../_shared/supabase.ts";
import { Payment } from "../_shared/types.ts";

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
  console.log("========== PAYMENT INSERT ==========");
  console.log("Student ID :", studentId);
  console.log("Exam Session ID :", examSessionId);
  console.log("Amount :", amount);
  console.log("Currency :", currency);
  console.log("TX REF :", txRef);
  console.log("Payment Method :", paymentMethod);

  // Vérification avant l'insertion
  console.log("TX REF reçu dans repository :", txRef);

  const { data, error } = await supabase
    .from("payments")
    .insert({
      student_id: studentId,
      exam_session_id: examSessionId,
      amount,
      currency,
      payment_method: paymentMethod,
      payment_channel: "Flutterwave",
      provider: "Flutterwave",
      flutterwave_tx_ref: txRef,
      flutterwave_transaction_id: null,
      status: "pending",
    })
    .select()
    .single();

  // Vérification après l'insertion
  console.log("Paiement inséré :", data);
  console.log("Erreur insertion :", error);

  if (error || !data) {
    throw new Error(
      `Erreur création paiement: ${
        error?.message ?? "Données paiement absentes"
      } | code=${error?.code ?? ""} | details=${
        error?.details ?? ""
      } | hint=${error?.hint ?? ""}`,
    );
  }

  return data as Payment;
}
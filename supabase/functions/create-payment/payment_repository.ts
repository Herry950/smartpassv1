import { supabase } from "../_shared/supabase.ts";
import { Payment } from "../_shared/types.ts";

export async function createPendingPayment({
  studentId,
  examSessionId,
  amount,
  currency,
  txRef,
}: {
  studentId: string;
  examSessionId: string;
  amount: number;
  currency: string;
  txRef: string;
}): Promise<Payment> {
  console.log("========== PAYMENT INSERT ==========");
  console.log("Student ID :", studentId);
  console.log("Exam Session ID :", examSessionId);
  console.log("Amount :", amount);
  console.log("Currency :", currency);
  console.log("TX REF :", txRef);

  const { data, error } = await supabase
    .from("payments")
    .insert({
      student_id: studentId,
      exam_session_id: examSessionId,
      amount,
      currency,

      payment_method: "online",
      payment_channel: "Flutterwave",
      provider: "Flutterwave",

      // IMPORTANT :
      // le nom réel de la colonne est celui-ci
      flutterwave_transaction_id: txRef,

      status: "pending",
    })
    .select()
    .single();

  console.log("Payment inserted :", data);
  console.log("Payment insert error :", error);

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
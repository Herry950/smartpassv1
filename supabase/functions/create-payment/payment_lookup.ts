import { supabase } from "../_shared/supabase.ts";
import { Payment } from "../_shared/types.ts";

export async function getExistingPayment({
  studentId,
  examSessionId,
}: {
  studentId: string;
  examSessionId: string;
}): Promise<Payment | null> {
  console.log("========== PAYMENT LOOKUP ==========");
  console.log("Student ID :", studentId);
  console.log("Exam Session ID :", examSessionId);

  const { data, error } = await supabase
    .from("payments")
    .select("*")
    .eq("student_id", studentId)
    .eq("exam_session_id", examSessionId)
    .in("status", ["pending", "validated"])
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  console.log("Paiement existant :", data);
  console.log("Erreur recherche :", error);

  if (error) {
    throw new Error(
      `Erreur recherche paiement : ${error.message}`
    );
  }

  return data as Payment | null;
}
import { supabase } from "../_shared/supabase.ts";
import { ExamSession } from "../_shared/types.ts";

export async function getExamSession(
  examSessionId: string,
): Promise<ExamSession> {
  const {
    data,
    error,
  } = await supabase
      .from("exam_sessions")
      .select(`
        id,
        session_name,
        semester,
        fee_amount,
        currency,
        payment_open,
        academic_year_id
      `)
      .eq("id", examSessionId)
      .single();

  if (error || !data) {
    throw new Error(
      "Session d'examen introuvable.",
    );
  }

  if (!data.payment_open) {
    throw new Error(
      "Les paiements sont fermés.",
    );
  }

  return data;
}
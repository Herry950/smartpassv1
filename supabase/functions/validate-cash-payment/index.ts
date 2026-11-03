import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json; charset=utf-8",
    },
  });
}

function isUuid(value: unknown): value is string {
  return typeof value === "string" &&
    /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
      .test(value);
}

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return jsonResponse(405, {
      success: false,
      message: "Méthode non autorisée.",
    });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const internalSecret = Deno.env.get("INTERNAL_FUNCTION_SECRET");

    if (!supabaseUrl || !anonKey || !serviceRoleKey || !internalSecret) {
      console.error("Configuration serveur incomplète.");
      return jsonResponse(500, {
        success: false,
        message: "Configuration serveur incomplète.",
      });
    }

    const authorization = request.headers.get("Authorization");

    if (!authorization?.startsWith("Bearer ")) {
      return jsonResponse(401, {
        success: false,
        message: "Authentification requise.",
      });
    }

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const {
      data: { user },
      error: authError,
    } = await userClient.auth.getUser();

    if (authError || !user) {
      return jsonResponse(401, {
        success: false,
        message: "Session utilisateur invalide.",
      });
    }

    let body: Record<string, unknown>;

    try {
      body = await request.json();
    } catch {
      return jsonResponse(400, {
        success: false,
        message: "Corps JSON invalide.",
      });
    }

    const { student_id, exam_session_id, idempotency_key } = body;

    if (
      !isUuid(student_id) ||
      !isUuid(exam_session_id) ||
      !isUuid(idempotency_key)
    ) {
      return jsonResponse(400, {
        success: false,
        message: "Identifiants ou clé d'opération invalides.",
      });
    }

    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    // Vérifier que l'utilisateur authentifié est un assistant actif.
    const { data: assistant, error: assistantError } = await admin
      .from("assistants")
      .select("id")
      .eq("auth_user_id", user.id)
      .eq("is_active", true)
      .maybeSingle();

    if (assistantError) {
      console.error(
        "Erreur de vérification de l'assistant :",
        assistantError.message,
      );

      return jsonResponse(500, {
        success: false,
        message: "Impossible de vérifier le compte assistant.",
      });
    }

    if (!assistant) {
      return jsonResponse(403, {
        success: false,
        message: "Compte assistant introuvable ou désactivé.",
      });
    }

    // La fonction SQL reste responsable de la création
    // et de l'idempotence du paiement.
    const { data: payment, error: paymentError } = await admin.rpc(
      "validate_cash_payment_idempotent",
      {
        p_student_id: student_id,
        p_exam_session_id: exam_session_id,
        p_assistant_auth_user_id: user.id,
        p_idempotency_key: idempotency_key,
      },
    );

    // Traiter une erreur RPC avant d'utiliser les données du paiement.
    if (paymentError || !payment) {
      const databaseMessage = paymentError?.message ?? "";

      console.error(
        "Échec de validation du paiement :",
        databaseMessage || "Réponse vide",
      );

      if (
        databaseMessage.includes(
          "Cette session est déjà payée pour cet étudiant.",
        )
      ) {
        return jsonResponse(409, {
          success: false,
          code: "PAYMENT_ALREADY_EXISTS",
          message:
            "Cet étudiant a déjà payé les frais de cette session. Aucun nouveau paiement n'a été créé.",
        });
      }

      if (
        databaseMessage.includes(
          "Un paiement est déjà en attente pour cet étudiant.",
        )
      ) {
        return jsonResponse(409, {
          success: false,
          code: "PAYMENT_PENDING",
          message:
            "Un paiement est déjà en attente pour cet étudiant. Vérifiez son état avant de continuer.",
        });
      }

      return jsonResponse(409, {
        success: false,
        code: "CASH_PAYMENT_VALIDATION_FAILED",
        message:
          "La validation du paiement a échoué. Vérifiez son état avant de réessayer.",
      });
    }

    // Vérifier le paiement retourné avant de signer le reçu.
    if (
      payment.student_id !== student_id ||
      payment.exam_session_id !== exam_session_id ||
      payment.payment_method !== "Espèces" ||
      payment.payment_channel !== "manual" ||
      payment.status !== "validated" ||
      !payment.receipt_number ||
      !payment.paid_at
    ) {
      console.error("Le paiement retourné ne correspond pas à la demande.");

      return jsonResponse(409, {
        success: false,
        code: "PAYMENT_RESPONSE_INVALID",
        message: "Le paiement retourné ne peut pas être confirmé.",
      });
    }

    // Un reçu déjà signé peut être retourné sans nouvelle signature.
    if (payment.receipt_signature) {
      return jsonResponse(200, {
        success: true,
        already_processed: true,
        signature_pending: false,
        payment,
        payment_id: payment.id,
        receipt_number: payment.receipt_number,
      });
    }

    // Signer le reçu du paiement existant sans créer de paiement.
    const signingResponse = await fetch(
      `${supabaseUrl}/functions/v1/sign-document`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-internal-function-secret": internalSecret,
        },
        body: JSON.stringify({
          payment_id: payment.id,
          receipt_number: payment.receipt_number,
          student_id: payment.student_id,
          amount: Number(payment.amount),
          currency: payment.currency,
          paid_at: payment.paid_at,
          flutterwave_transaction_id: null,
        }),
      },
    );

    const signingData = await signingResponse.json().catch(() => null);

    if (
      !signingResponse.ok ||
      signingData?.success !== true ||
      typeof signingData?.signature !== "string"
    ) {
      console.error(
        "Signature en attente pour le paiement :",
        payment.id,
        signingResponse.status,
      );

      return jsonResponse(202, {
        success: true,
        signature_pending: true,
        message:
          "Paiement validé, mais signature du reçu à reprendre.",
        payment_id: payment.id,
        receipt_number: payment.receipt_number,
        idempotency_key,
      });
    }

    return jsonResponse(200, {
      success: true,
      already_processed: false,
      signature_pending: false,
      payment: {
        ...payment,
        receipt_signature: signingData.signature,
      },
      payment_id: payment.id,
      receipt_number: payment.receipt_number,
    });
  } catch (error) {
    console.error(
      "Erreur validate-cash-payment :",
      error instanceof Error ? error.message : String(error),
    );

    return jsonResponse(500, {
      success: false,
      message: "Une erreur interne est survenue.",
    });
  }
});
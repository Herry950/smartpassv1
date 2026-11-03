import { createClient } from "npm:@supabase/supabase-js@2";
import { generateReceiptSignature } from "../sign-document/signer.ts";

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

interface PaymentForVerification {
  id: string;
  student_id: string;
  exam_session_id: string;
  amount: number | string;
  currency: string;
  status: string;
  payment_method: string;
  payment_channel: string;
  receipt_number: string | null;
  receipt_signature: string | null;
  flutterwave_transaction_id: string | null;
  paid_at: string | null;
}

interface AssistantRecord {
  id: string;
  auth_user_id: string;
  is_active: boolean;
}

function isNonEmptyString(value: unknown): value is string {
  return typeof value === "string" && value.trim().length > 0;
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
    const receiptSecret = Deno.env.get("RECEIPT_SECRET");

    if (
      !supabaseUrl ||
      !anonKey ||
      !serviceRoleKey ||
      !receiptSecret
    ) {
      console.error("Configuration serveur incomplète.");

      return jsonResponse(500, {
        success: false,
        message: "Configuration du service de vérification incomplète.",
      });
    }

    const authorization = request.headers.get("Authorization");

    if (!authorization?.startsWith("Bearer ")) {
      return jsonResponse(401, {
        success: false,
        message: "Authentification requise.",
      });
    }

    const token = authorization.slice("Bearer ".length).trim();

    if (!token) {
      return jsonResponse(401, {
        success: false,
        message: "Jeton d'authentification absent.",
      });
    }

    // Le client authentifié sert uniquement à vérifier l'identité.
    const authClient = createClient(supabaseUrl, anonKey, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    });

    const {
      data: authData,
      error: authError,
    } = await authClient.auth.getUser(token);

    if (authError || !authData.user) {
      return jsonResponse(401, {
        success: false,
        message: "Session utilisateur invalide ou expirée.",
      });
    }

    const userId = authData.user.id;

    const supabase = createClient(
      supabaseUrl,
      serviceRoleKey,
      {
        auth: {
          persistSession: false,
          autoRefreshToken: false,
        },
      },
    );

    // La vérification d'un reçu est réservée aux assistants actifs.
    const {
      data: assistantData,
      error: assistantError,
    } = await supabase
      .from("assistants")
      .select("id, auth_user_id, is_active")
      .eq("auth_user_id", userId)
      .maybeSingle();

    if (assistantError) {
      console.error(
        "Erreur de lecture de l'assistant :",
        assistantError.message,
      );

      throw new Error("Impossible de vérifier le profil de l'assistant.");
    }

    const assistant = assistantData as AssistantRecord | null;

    if (!assistant || assistant.is_active !== true) {
      return jsonResponse(403, {
        success: false,
        message: "Un compte assistant actif est requis.",
      });
    }

    let body: { receipt_number?: unknown };

    try {
      body = await request.json();
    } catch {
      return jsonResponse(400, {
        success: false,
        message: "Corps JSON invalide.",
      });
    }

    if (!isNonEmptyString(body.receipt_number)) {
      return jsonResponse(400, {
        success: false,
        message: "Le numéro du reçu est obligatoire.",
      });
    }

    const receiptNumber = body.receipt_number.trim();

    if (!/^SP-\d{4}-\d{6}$/.test(receiptNumber)) {
      return jsonResponse(400, {
        success: false,
        authentic: false,
        message: "Format du numéro de reçu invalide.",
      });
    }

    const {
      data: paymentData,
      error: paymentError,
    } = await supabase
      .from("payments")
      .select(
        [
          "id",
          "student_id",
          "exam_session_id",
          "amount",
          "currency",
          "status",
          "payment_method",
          "payment_channel",
          "receipt_number",
          "receipt_signature",
          "flutterwave_transaction_id",
          "paid_at",
        ].join(", "),
      )
      .eq("receipt_number", receiptNumber)
      .maybeSingle();

    if (paymentError) {
      console.error(
        "Erreur de lecture du paiement :",
        paymentError.message,
      );

      throw new Error("Impossible de lire le paiement.");
    }

    const payment = paymentData as PaymentForVerification | null;

    if (!payment) {
      return jsonResponse(404, {
        success: false,
        authentic: false,
        message: "Reçu introuvable.",
      });
    }

    if (payment.status !== "validated") {
      return jsonResponse(409, {
        success: false,
        authentic: false,
        message: "Ce paiement n'est pas validé.",
      });
    }

    if (
      !payment.receipt_signature ||
      !payment.paid_at ||
      !payment.receipt_number
    ) {
      return jsonResponse(409, {
        success: false,
        authentic: false,
        message: "Ce reçu n'a pas encore été signé.",
      });
    }

    const isCashPayment =
      payment.payment_method === "Espèces" &&
      payment.payment_channel === "manual";

    let transactionMarker: string;

    if (isCashPayment) {
      if (payment.flutterwave_transaction_id) {
        return jsonResponse(409, {
          success: false,
          authentic: false,
          message:
            "Les informations du paiement en espèces sont incohérentes.",
        });
      }

      transactionMarker = "CASH";
    } else {
      if (!isNonEmptyString(payment.flutterwave_transaction_id)) {
        return jsonResponse(409, {
          success: false,
          authentic: false,
          message: "Identifiant de transaction manquant.",
        });
      }

      transactionMarker = payment.flutterwave_transaction_id;
    }

    const dataToSign = [
      payment.receipt_number,
      payment.student_id,
      Number(payment.amount),
      payment.currency,
      transactionMarker,
      payment.paid_at,
    ].join("|");

    const expectedSignature = await generateReceiptSignature(
      receiptSecret,
      dataToSign,
    );

    // Comparaison sans différence de longueur ni sortie anticipée.
    const encoder = new TextEncoder();
    const expectedBytes = encoder.encode(expectedSignature);
    const actualBytes = encoder.encode(payment.receipt_signature);

    let difference = expectedBytes.length ^ actualBytes.length;
    const maxLength = Math.max(
      expectedBytes.length,
      actualBytes.length,
    );

    for (let i = 0; i < maxLength; i++) {
      difference |=
        (expectedBytes[i] ?? 0) ^ (actualBytes[i] ?? 0);
    }

    if (difference !== 0) {
      return jsonResponse(200, {
        success: true,
        authentic: false,
        message:
          "La signature du reçu est invalide. Son authenticité ne peut pas être confirmée.",
      });
    }

    const {
      data: student,
      error: studentError,
    } = await supabase
      .from("students")
      .select("*")
      .eq("id", payment.student_id)
      .maybeSingle();

    if (studentError) {
      console.error(
        "Erreur de lecture de l'étudiant :",
        studentError.message,
      );

      throw new Error("Impossible de lire les informations de l'étudiant.");
    }

    if (!student) {
      return jsonResponse(404, {
        success: false,
        authentic: false,
        message: "Étudiant associé au reçu introuvable.",
      });
    }

    const {
      data: examSession,
      error: sessionError,
    } = await supabase
      .from("exam_sessions")
      .select("*")
      .eq("id", payment.exam_session_id)
      .maybeSingle();

    if (sessionError) {
      console.error(
        "Erreur de lecture de la session :",
        sessionError.message,
      );

      throw new Error("Impossible de lire la session d'examen.");
    }

    if (!examSession) {
      return jsonResponse(404, {
        success: false,
        authentic: false,
        message: "Session d'examen associée au reçu introuvable.",
      });
    }

    return jsonResponse(200, {
      success: true,
      authentic: true,
      receipt: {
        receipt_number: payment.receipt_number,
        amount: Number(payment.amount),
        currency: payment.currency,
        paid_at: payment.paid_at,
        status: payment.status,
        payment_method: payment.payment_method,
        payment_channel: payment.payment_channel,
      },
      student,
      exam_session: examSession,
    });
  } catch (error: unknown) {
    console.error(
      "Erreur get-receipt :",
      error instanceof Error ? error.message : String(error),
    );

    return jsonResponse(500, {
      success: false,
      message:
        "Une erreur est survenue pendant la vérification du reçu.",
    });
  }
});
import { createClient } from "npm:@supabase/supabase-js@2";
import { generateReceiptSignature } from "./signer.ts";
import type { ReceiptPayload } from "./types.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-internal-function-secret",
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

interface PaymentForSigning {
  id: string;
  student_id: string;
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
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const internalSecret = Deno.env.get("INTERNAL_FUNCTION_SECRET");
    const receiptSecret = Deno.env.get("RECEIPT_SECRET");

    if (
      !supabaseUrl ||
      !serviceRoleKey ||
      !internalSecret ||
      !receiptSecret
    ) {
      console.error("Configuration serveur incomplète.");

      return jsonResponse(500, {
        success: false,
        message: "Configuration du service de signature incomplète.",
      });
    }

    const suppliedSecret = request.headers.get(
      "x-internal-function-secret",
    );

    if (
      !suppliedSecret ||
      suppliedSecret !== internalSecret
    ) {
      return jsonResponse(401, {
        success: false,
        message: "Accès interne non autorisé.",
      });
    }

    let payload: ReceiptPayload;

    try {
      payload = await request.json() as ReceiptPayload;
    } catch {
      return jsonResponse(400, {
        success: false,
        message: "Corps JSON invalide.",
      });
    }

    if (
      !isNonEmptyString(payload.payment_id) ||
      !isNonEmptyString(payload.receipt_number) ||
      !isNonEmptyString(payload.student_id) ||
      !isNonEmptyString(payload.currency) ||
      !isNonEmptyString(payload.paid_at) ||
      typeof payload.amount !== "number" ||
      !Number.isFinite(payload.amount) ||
      payload.amount <= 0
    ) {
      return jsonResponse(400, {
        success: false,
        message: "Informations de reçu invalides.",
      });
    }

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

    const {
      data: paymentData,
      error: paymentError,
    } = await supabase
      .from("payments")
      .select(
        [
          "id",
          "student_id",
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
      .eq("id", payload.payment_id)
      .maybeSingle();

    if (paymentError) {
      console.error(
        "Erreur de lecture du paiement :",
        paymentError.message,
      );

      throw new Error("Impossible de lire le paiement.");
    }

    const payment = paymentData as PaymentForSigning | null;

    if (!payment) {
      return jsonResponse(404, {
        success: false,
        message: "Paiement introuvable.",
      });
    }

    const isCashPayment =
      payment.payment_method === "Espèces" &&
      payment.payment_channel === "manual";

    if (payment.status !== "validated") {
      return jsonResponse(409, {
        success: false,
        message: "Seuls les paiements validés peuvent être signés.",
      });
    }

    if (
      !payment.receipt_number ||
      payment.receipt_number !== payload.receipt_number ||
      payment.student_id !== payload.student_id ||
      Number(payment.amount) !== payload.amount ||
      payment.currency !== payload.currency ||
      payment.paid_at !== payload.paid_at
    ) {
      return jsonResponse(409, {
        success: false,
        message:
          "Les informations fournies ne correspondent pas au paiement enregistré.",
      });
    }

    let transactionMarker: string;

    if (isCashPayment) {
      // Un paiement en espèces ne doit jamais être signé
      // comme s'il s'agissait d'une transaction Flutterwave.
      if (
        payment.flutterwave_transaction_id ||
        (
          payload.flutterwave_transaction_id != null &&
          payload.flutterwave_transaction_id !== ""
        )
      ) {
        return jsonResponse(409, {
          success: false,
          message:
            "Un paiement en espèces ne peut pas posséder de transaction Flutterwave.",
        });
      }

      transactionMarker = "CASH";
    } else {
      if (
        !isNonEmptyString(payment.flutterwave_transaction_id) ||
        payload.flutterwave_transaction_id !==
          payment.flutterwave_transaction_id
      ) {
        return jsonResponse(409, {
          success: false,
          message:
            "La transaction Flutterwave ne correspond pas au paiement.",
        });
      }

      transactionMarker = payment.flutterwave_transaction_id;
    }

    // Ne jamais remplacer une signature déjà enregistrée.
    if (payment.receipt_signature) {
      return jsonResponse(200, {
        success: true,
        already_signed: true,
        receipt_number: payment.receipt_number,
        signature: payment.receipt_signature,
      });
    }

    const dataToSign = [
      payment.receipt_number,
      payment.student_id,
      Number(payment.amount),
      payment.currency,
      transactionMarker,
      payment.paid_at,
    ].join("|");

    const signature = await generateReceiptSignature(
      receiptSecret,
      dataToSign,
    );

    const {
      data: updatedPayment,
      error: updateError,
    } = await supabase
      .from("payments")
      .update({ receipt_signature: signature })
      .eq("id", payment.id)
      .eq("status", "validated")
      .is("receipt_signature", null)
      .select("id, receipt_number, receipt_signature")
      .maybeSingle();

    if (updateError) {
      console.error(
        "Erreur d'enregistrement de la signature :",
        updateError.message,
      );

      throw new Error("Impossible d'enregistrer la signature.");
    }

    if (!updatedPayment) {
      // Une autre requête a pu signer le reçu entre-temps.
      const { data: latestPayment, error: latestError } =
        await supabase
          .from("payments")
          .select("receipt_number, receipt_signature")
          .eq("id", payment.id)
          .maybeSingle();

      if (latestError) {
        throw new Error("Impossible de vérifier la signature enregistrée.");
      }

      if (
        latestPayment?.receipt_signature &&
        latestPayment.receipt_number === payment.receipt_number
      ) {
        return jsonResponse(200, {
          success: true,
          already_signed: true,
          receipt_number: latestPayment.receipt_number,
          signature: latestPayment.receipt_signature,
        });
      }

      return jsonResponse(409, {
        success: false,
        message:
          "Le paiement a changé ou sa signature n'a pas pu être enregistrée.",
      });
    }

    return jsonResponse(200, {
      success: true,
      already_signed: false,
      receipt_number: updatedPayment.receipt_number,
      signature: updatedPayment.receipt_signature,
    });
  } catch (error: unknown) {
    console.error(
      "Erreur sign-document :",
      error instanceof Error ? error.message : String(error),
    );

    return jsonResponse(500, {
      success: false,
      message: "Une erreur est survenue pendant la signature du reçu.",
    });
  }
});
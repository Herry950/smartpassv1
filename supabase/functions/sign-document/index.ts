import "@supabase/functions-js/edge-runtime.d.ts";

import { createClient } from "jsr:@supabase/supabase-js@2";

import { generateReceiptSignature } from "./signer.ts";
import type { ReceiptPayload } from "./types.ts";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

Deno.serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return new Response(
        JSON.stringify({
          success: false,
          message: "Méthode HTTP non autorisée.",
        }),
        {
          status: 405,
          headers: {
            "Content-Type": "application/json",
          },
        },
      );
    }

    const payload: ReceiptPayload = await req.json();

    if (
      !payload.payment_id ||
      !payload.receipt_number ||
      !payload.student_id ||
      payload.amount === undefined ||
      !payload.currency ||
      !payload.flutterwave_transaction_id ||
      !payload.paid_at
    ) {
      return new Response(
        JSON.stringify({
          success: false,
          message: "Payload incomplet pour la signature du reçu.",
        }),
        {
          status: 400,
          headers: {
            "Content-Type": "application/json",
          },
        },
      );
    }

    const secret = Deno.env.get("RECEIPT_SECRET");

    if (!secret) {
      throw new Error("RECEIPT_SECRET introuvable.");
    }

    const dataToSign = [
      payload.receipt_number,
      payload.student_id,
      payload.amount,
      payload.currency,
      payload.flutterwave_transaction_id,
      payload.paid_at,
    ].join("|");

    const signature = await generateReceiptSignature(
      secret,
      dataToSign,
    );

    const { error } = await supabase
      .from("payments")
      .update({
        receipt_signature: signature,
      })
      .eq("id", payload.payment_id);

    if (error) {
      throw error;
    }

    return new Response(
      JSON.stringify({
        success: true,
        signature,
      }),
      {
        status: 200,
        headers: {
          "Content-Type": "application/json",
        },
      },
    );
  } catch (e) {
    return new Response(
      JSON.stringify({
        success: false,
        message:
          e instanceof Error ? e.message : String(e),
      }),
      {
        status: 500,
        headers: {
          "Content-Type": "application/json",
        },
      },
    );
  }
});
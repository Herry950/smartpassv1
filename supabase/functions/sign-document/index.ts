import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";

import { generateReceiptSignature } from "./signer.ts";
import type { ReceiptPayload } from "./types.ts";

export default {
  fetch: withSupabase(
    { auth: ["publishable", "secret"] },
    async (req, ctx) => {
      try {
        const payload: ReceiptPayload = await req.json();

        const secret = Deno.env.get("RECEIPT_SECRET");

        if (!secret) {
          return Response.json(
            {
              success: false,
              message: "RECEIPT_SECRET introuvable.",
            },
            { status: 500 },
          );
        }

        const dataToSign = [
          payload.receipt_number,
          payload.student_id,
          payload.amount,
          payload.currency,
          payload.transaction_id,
          payload.paid_at,
        ].join("|");

        const signature = await generateReceiptSignature(
          secret,
          dataToSign,
        );

        const { error } = await ctx.supabaseAdmin
          .from("payments")
          .update({
            receipt_signature: signature,
        })
        .eq("id", payload.payment_id);

        if (error) {
          return Response.json(
            {
              success: false,
              message: error.message,
            },
            { status: 500 },
          );
        }

        return Response.json({
          success: true,
          signature,
          message: "Signature enregistrée avec succès.",
        });
      } catch (error) {
        return Response.json(
          {
            success: false,
            message:
              error instanceof Error
                ? error.message
                : "Erreur inconnue",
          },
          { status: 500 },
        );
      }
    },
  ),
};
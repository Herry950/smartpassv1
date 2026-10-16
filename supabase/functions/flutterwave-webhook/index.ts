import "@supabase/functions-js/edge-runtime.d.ts";

import { createClient } from "jsr:@supabase/supabase-js@2";

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

    const body = await req.json();

    console.log("===== WEBHOOK RECU =====");
    console.log(body);

    if (body.event !== "charge.completed") {
      return new Response(
        JSON.stringify({
          success: true,
          message: "Evènement ignoré.",
        }),
        {
          status: 200,
          headers: {
            "Content-Type": "application/json",
          },
        },
      );
    }

    const data = body.data;

    if (!data) {
      throw new Error(
        "Données Flutterwave absentes.",
      );
    }

    const txRef = data.tx_ref;
    const transactionId = String(data.id);

    console.log("TX REF :", txRef);
    console.log(
      "Transaction :",
      transactionId,
    );

    if (!txRef) {
      throw new Error(
        "tx_ref absent du webhook Flutterwave.",
      );
    }

    if (!transactionId) {
      throw new Error(
        "ID transaction Flutterwave absent.",
      );
    }

    const {
      data: payment,
      error: paymentError,
    } = await supabase
      .from("payments")
      .select("*")
      .eq("flutterwave_tx_ref", txRef)
      .single();

    console.log(
      "Paiement trouvé :",
      payment,
    );

    console.log(
      "Erreur recherche :",
      paymentError,
    );

    if (paymentError || !payment) {
      throw new Error(
        "Paiement introuvable : " + txRef,
      );
    }

    if (
      payment.status === "validated" &&
      payment.receipt_number
    ) {
      console.log(
        "Paiement déjà traité :",
        payment.id,
      );

      return new Response(
        JSON.stringify({
          success: true,
          message:
            "Paiement déjà validé.",
          receipt_number:
            payment.receipt_number,
        }),
        {
          status: 200,
          headers: {
            "Content-Type":
              "application/json",
          },
        },
      );
    }

    // ============================================================
    // GÉNÉRATION ATOMIQUE DU NUMÉRO DE REÇU
    // ============================================================

    const {
      data: receiptNumber,
      error: receiptNumberError,
    } = await supabase.rpc(
      "get_next_receipt_number",
    );

    console.log(
      "Numéro de reçu généré :",
      receiptNumber,
    );

    console.log(
      "Erreur génération numéro :",
      receiptNumberError,
    );

    if (receiptNumberError) {
      throw new Error(
        "Impossible de générer le numéro de reçu : " +
          receiptNumberError.message,
      );
    }

    if (
      !receiptNumber ||
      typeof receiptNumber !== "string"
    ) {
      throw new Error(
        "Numéro de reçu invalide.",
      );
    }

    const paidAt =
      new Date().toISOString();

    // ============================================================
    // VALIDATION DU PAIEMENT
    // ============================================================

    const {
      data: updatedPayment,
      error: updateError,
    } = await supabase
      .from("payments")
      .update({
        flutterwave_transaction_id:
          transactionId,
        status: "validated",
        paid_at: paidAt,
        receipt_number:
          receiptNumber,
      })
      .eq("id", payment.id)
      .select("*")
      .single();

    console.log(
      "Paiement après validation :",
      updatedPayment,
    );

    console.log(
      "Erreur update :",
      updateError,
    );

    if (updateError) {
      throw updateError;
    }

    // ============================================================
    // SIGNATURE NUMÉRIQUE DU REÇU
    // ============================================================

    const {
      data: signatureData,
      error: signatureError,
    } = await supabase.functions.invoke(
      "sign-document",
      {
        body: {
          payment_id:
            updatedPayment.id,

          receipt_number:
            updatedPayment.receipt_number,

          student_id:
            updatedPayment.student_id,

          amount:
            Number(
              updatedPayment.amount,
            ),

          currency:
            updatedPayment.currency,

          flutterwave_transaction_id:
            updatedPayment.flutterwave_transaction_id,

          paid_at:
            updatedPayment.paid_at,
        },
      },
    );

    console.log(
      "Résultat signature :",
      signatureData,
    );

    console.log(
      "Erreur signature :",
      signatureError,
    );

    if (signatureError) {
      throw signatureError;
    }

    if (
      !signatureData ||
      signatureData.success !== true
    ) {
      throw new Error(
        "La signature du reçu a échoué.",
      );
    }

    // ============================================================
    // ENREGISTREMENT DE L'ÉVÉNEMENT
    // ============================================================

    const {
      error: eventError,
    } = await supabase
      .from("payment_events")
      .insert({
        payment_id:
          payment.id,

        event_type:
          body.event,

        flutterwave_transaction_id:
          transactionId,

        flutterwave_tx_ref:
          txRef,

        payload:
          body,

        verified:
          true,
      });

    console.log(
      "Erreur payment_events :",
      eventError,
    );

    if (eventError) {
      console.error(
        "Erreur lors de l'enregistrement de payment_events :",
        eventError,
      );
    }

    // ============================================================
    // RÉPONSE
    // ============================================================

    return new Response(
      JSON.stringify({
        success: true,

        payment_id:
          payment.id,

        receipt_number:
          receiptNumber,

        signature:
          signatureData.signature,
      }),
      {
        status: 200,
        headers: {
          "Content-Type":
            "application/json",
        },
      },
    );
  } catch (e: unknown) {
    console.log(
      "===== ERREUR WEBHOOK =====",
    );

    console.log(e);

    return new Response(
      JSON.stringify({
        success: false,

        error:
          e instanceof Error
            ? e.message
            : String(e),
      }),
      {
        status: 500,
        headers: {
          "Content-Type":
            "application/json",
        },
      },
    );
  }
});
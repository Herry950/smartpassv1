import "@supabase/functions-js/edge-runtime.d.ts";

import { createClient } from "jsr:@supabase/supabase-js@2";
import { verifyFlutterwaveTransaction } from "../_shared/flutterwave.ts";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

const INTERNAL_FUNCTION_SECRET = Deno.env.get(
  "INTERNAL_FUNCTION_SECRET",
);

if (!INTERNAL_FUNCTION_SECRET) {
  throw new Error("INTERNAL_FUNCTION_SECRET introuvable.");
}

function safeEquals(a: string, b: string): boolean {
  const encoder = new TextEncoder();
  const aBytes = encoder.encode(a);
  const bBytes = encoder.encode(b);

  if (aBytes.length !== bBytes.length) return false;

  let result = 0;

  for (let i = 0; i < aBytes.length; i++) {
    result |= aBytes[i] ^ bBytes[i];
  }

  return result === 0;
}

function jsonResponse(
  status: number,
  body: Record<string, unknown>,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  try {
    // 1. Vérifier la méthode HTTP
    if (req.method !== "POST") {
      return jsonResponse(405, {
        success: false,
        message: "Méthode HTTP non autorisée.",
      });
    }

    // 2. Authentifier le webhook Flutterwave
    const expectedHash = Deno.env.get("FLW_WEBHOOK_HASH_TEST");

    if (!expectedHash) {
      console.error("Configuration absente : FLW_WEBHOOK_HASH_TEST.");

      return jsonResponse(500, {
        success: false,
        message: "Configuration du webhook absente.",
      });
    }

    const receivedHash = req.headers.get("verif-hash");

    if (!receivedHash || !safeEquals(receivedHash, expectedHash)) {
      console.warn("Webhook rejeté : hash absent ou incorrect.");

      return jsonResponse(401, {
        success: false,
        message: "Webhook non authentifié.",
      });
    }

    // 3. Lire l'événement
    const body = await req.json();

    console.log("===== WEBHOOK AUTHENTIFIÉ =====");
    console.log("Événement :", body.event);

    if (body.event !== "charge.completed") {
      return jsonResponse(200, {
        success: true,
        message: "Événement ignoré.",
      });
    }

    const data = body.data;

    if (!data) {
      throw new Error("Données Flutterwave absentes.");
    }

    const txRef = data.tx_ref;
    const transactionId = data.id != null ? String(data.id) : "";

    if (typeof txRef !== "string" || !txRef.trim()) {
      throw new Error("tx_ref absent du webhook Flutterwave.");
    }

    if (!transactionId.trim()) {
      throw new Error("ID transaction Flutterwave absent.");
    }

    console.log("TX REF :", txRef);
    console.log("ID transaction :", transactionId);

    // 4. Retrouver le paiement SmartPass
    const { data: payment, error: paymentError } = await supabase
      .from("payments")
      .select("*")
      .eq("flutterwave_tx_ref", txRef)
      .maybeSingle();

    if (paymentError) {
      throw new Error(
        "Erreur recherche paiement : " + paymentError.message,
      );
    }

    if (!payment) {
      throw new Error(
        "Paiement introuvable pour la référence : " + txRef,
      );
    }

    console.log("Paiement trouvé :", payment.id);

    // 5. Vérifier la transaction auprès de Flutterwave
    await verifyFlutterwaveTransaction({
      transactionId,
      expectedTxRef: payment.flutterwave_tx_ref,
      expectedAmount: Number(payment.amount),
      expectedCurrency: payment.currency,
    });

    console.log("Transaction vérifiée auprès de Flutterwave.");

   // 6. Idempotence : vérifier la transaction avant de répondre
    if (
      payment.status === "validated" &&
      payment.receipt_number &&
      payment.receipt_signature
    ) {
      // Le même paiement doit toujours correspondre
      // à la même transaction Flutterwave.
      if (
        payment.flutterwave_transaction_id !== transactionId
      ) {
        throw new Error(
          "Le paiement est déjà validé avec un autre identifiant de transaction.",
        );
      }

      console.log("Paiement déjà validé et signé :", payment.id);

      return jsonResponse(200, {
        success: true,
        message: "Paiement déjà validé.",
        payment_id: payment.id,
        receipt_number: payment.receipt_number,
      });
    }

    // 7. Valider atomiquement dans PostgreSQL.
    // Le numéro de reçu est généré dans cette fonction SQL.
    // Elle bloque également une deuxième validation pour la même
    // combinaison étudiant/session d'examen.
    const paidAt = new Date().toISOString();

    const {
      data: validationData,
      error: validationError,
    } = await supabase.rpc("validate_payment_atomic", {
      p_payment_id: payment.id,
      p_transaction_id: transactionId,
      p_paid_at: paidAt,
    });

    if (validationError) {
  console.error(
    "Validation atomique refusée :",
    validationError.message,
  );

  // Une autre tentative peut avoir été validée entre-temps.
  // Dans ce cas, ne validons pas une seconde fois la session.
  const { data: existingPayment, error: existingError } =
    await supabase
      .from("payments")
      .select("id, receipt_number")
      .eq("student_id", payment.student_id)
      .eq("exam_session_id", payment.exam_session_id)
      .eq("status", "validated")
      .neq("id", payment.id)
      .limit(1)
      .maybeSingle();

  if (existingError) {
    throw new Error(
      "Impossible de vérifier le conflit de paiement : " +
        existingError.message,
    );
  }

  if (existingPayment) {
    const { error: eventError } = await supabase
      .from("payment_events")
      .insert({
        payment_id: payment.id,
        event_type: "late_payment_conflict",
        flutterwave_transaction_id: transactionId,
        flutterwave_tx_ref: txRef,
        payload: {
          event: body.event,
          payment_id: payment.id,
          conflicting_payment_id: existingPayment.id,
          conflicting_receipt_number: existingPayment.receipt_number,
          reason: validationError.message,
        },
        verified: true,
      });

    if (eventError) {
      console.error(
        "Échec de journalisation du conflit :",
        eventError.message,
      );

      throw new Error(
        "Conflit détecté, mais sa journalisation a échoué.",
      );
    }

    console.error(
      "Paiement tardif à réconcilier :",
      payment.id,
      "Paiement déjà validé :",
      existingPayment.id,
    );

    // Le conflit est enregistré. Ne pas recréer de reçu
    // ni tenter de valider une deuxième fois la session.
    return jsonResponse(200, {
      success: true,
      reconciliation_required: true,
      payment_id: payment.id,
      message:
        "Transaction confirmée, mais une autre tentative est déjà validée. Réconciliation manuelle requise.",
    });
  }

  throw new Error(
    "Validation atomique refusée : " + validationError.message,
  );
}

    // Selon la représentation retournée par PostgREST, la ligne
    // peut être un objet ou un tableau contenant un objet.
    const updatedPayment = Array.isArray(validationData)
      ? validationData[0]
      : validationData;

    if (
      !updatedPayment ||
      !updatedPayment.id ||
      updatedPayment.status !== "validated" ||
      !updatedPayment.receipt_number
    ) {
      throw new Error(
        "La fonction SQL n'a pas retourné un paiement validé avec un reçu.",
      );
    }

    if (
      updatedPayment.flutterwave_transaction_id !== transactionId
    ) {
      throw new Error(
        "La transaction retournée ne correspond pas à la transaction vérifiée.",
      );
    }

    console.log("Paiement validé :", updatedPayment.id);
    console.log("Numéro de reçu :", updatedPayment.receipt_number);

    // 8. Signer le reçu si nécessaire
    let signature: string | null =
      updatedPayment.receipt_signature ?? null;

    if (!signature) {
      const {
        data: signatureData,
        error: signatureError,
      } = await supabase.functions.invoke("sign-document", {
        body: {
          payment_id: updatedPayment.id,
          receipt_number: updatedPayment.receipt_number,
          student_id: updatedPayment.student_id,
          amount: Number(updatedPayment.amount),
          currency: updatedPayment.currency,
          flutterwave_transaction_id:
            updatedPayment.flutterwave_transaction_id,
          paid_at: updatedPayment.paid_at,
        },
        headers: {
          "x-internal-function-secret": INTERNAL_FUNCTION_SECRET,
        },
      });

      if (signatureError) {
        throw new Error(
          "Erreur lors de la signature du reçu : " +
            signatureError.message,
        );
      }

      if (!signatureData || signatureData.success !== true) {
        throw new Error("La signature du reçu a échoué.");
      }

      signature = signatureData.signature ?? null;

      console.log("Signature du reçu enregistrée.");
    }

    // 9. Enregistrer l'événement sans invalider le paiement
    const { error: eventError } = await supabase
      .from("payment_events")
      .insert({
        payment_id: updatedPayment.id,
        event_type: body.event,
        flutterwave_transaction_id: transactionId,
        flutterwave_tx_ref: txRef,
        payload: body,
        verified: true,
      });

    if (eventError) {
      console.error(
        "Erreur enregistrement payment_events :",
        eventError.message,
      );
    }

    // 10. Réponse finale
    return jsonResponse(200, {
      success: true,
      payment_id: updatedPayment.id,
      receipt_number: updatedPayment.receipt_number,
      signature,
    });
  } catch (e: unknown) {
    console.error("===== ERREUR WEBHOOK =====");
    console.error(e instanceof Error ? e.message : String(e));

    return jsonResponse(500, {
      success: false,
      error: e instanceof Error ? e.message : String(e),
    });
  }
});
import "@supabase/functions-js/edge-runtime.d.ts";

import { corsHeaders } from "../_shared/cors.ts";

import {
  badRequest,
  conflict,
  serverError,
  success,
} from "../_shared/responses.ts";

import { generateTxRef } from "../_shared/tx_ref.ts";

import {
  createFlutterwaveCheckout,
} from "../_shared/flutterwave.ts";

import {
  getAuthenticatedStudent,
} from "./auth.ts";

import {
  getExamSession,
} from "./exam_session.ts";

import {
  createPendingPayment,
  PaymentCreationError,
} from "./payment_repository.ts";

Deno.serve(async (req) => {
  console.log("========== CREATE PAYMENT ==========");
  console.log("Method :", req.method);

  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: corsHeaders,
    });
  }

  try {
    const authorization =
      req.headers.get("Authorization");

    console.log(
      "Authorization présente :",
      !!authorization,
    );

    if (!authorization) {
      return badRequest("Authorization manquante.");
    }

    const body = await req.json();
    console.log("Request body :", body);

    const examSessionId = body?.exam_session_id;
    const paymentMethod =
      body?.payment_method ?? "Carte bancaire";

    if (!examSessionId) {
      return badRequest("exam_session_id manquant.");
    }

    console.log("Exam Session ID :", examSessionId);
    console.log("Payment Method :", paymentMethod);

    // 1. Authentification
    const student = await getAuthenticatedStudent(
      authorization,
    );

    console.log("Étudiant authentifié :", student.full_name);
    console.log("Student ID :", student.id);

    // 2. Récupération de la session
    const session = await getExamSession(examSessionId);

    console.log("Session trouvée :", session);

    // 3. Génération de la référence
    const txRef = generateTxRef(student.matricule);
    console.log("TX REF :", txRef);

    // 4. Création atomique du paiement en attente
    let payment;

    try {
      payment = await createPendingPayment({
        studentId: student.id,
        examSessionId: session.id,
        amount: session.fee_amount,
        currency: session.currency,
        txRef,
        paymentMethod,
      });
    } catch (error) {
      if (error instanceof PaymentCreationError) {
        if (
          error.code === "23505" &&
          error.message.includes(
            "Cette session est déjà payée pour cet étudiant.",
          )
        ) {
          return conflict(
            "PAYMENT_ALREADY_EXISTS",
            "Cette session est déjà payée pour cet étudiant.",
          );
        }

        if (
          error.code === "23505" &&
          error.message.includes(
            "Une tentative de paiement est déjà en attente pour cette session.",
          )
        ) {
          return conflict(
            "PAYMENT_PENDING",
            "Une tentative de paiement est déjà en attente pour cette session.",
          );
        }
      }

      // Laisse les véritables erreurs remonter vers le gestionnaire général.
      throw error;
    }

    console.log("Paiement pending créé :", payment.id);

    // 5. Création du checkout Flutterwave
    const checkout = await createFlutterwaveCheckout({
      txRef,
      amount: session.fee_amount,
      currency: session.currency,
      customerName: student.full_name,
      customerEmail: student.email,
      redirectUrl:
        "https://smartpass.vercel.app/payment-result",
      paymentMethod,
    });

    console.log("Checkout prêt.");

    return success({
      success: true,
      payment_id: payment.id,
      tx_ref: txRef,
      checkout_url: checkout.checkoutUrl,
    });
  } catch (error) {
    console.error(
      "========== CREATE PAYMENT ERROR ==========",
    );
    console.error(error);

    return serverError(
      error instanceof Error
        ? error.message
        : String(error),
    );
  }
});
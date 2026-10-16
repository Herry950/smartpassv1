import { withSupabase } from "npm:@supabase/server@^1";
import type { Database } from "../../../database.types.ts";

type PaymentRow = Database["public"]["Tables"]["payments"]["Row"];
type StudentRow = Database["public"]["Tables"]["students"]["Row"];

type JsonObject = Record<string, unknown>;

function jsonResponse(
body: JsonObject,
status = 200,
): Response {
return Response.json(body, { status });
}

/**

* Génère une signature HMAC-SHA256.
* Le format doit rester identique à celui de sign-document.
  */
  async function generateReceiptSignature(
  secret: string,
  payload: string,
  ): Promise<string> {
  const encoder = new TextEncoder();

const key = await crypto.subtle.importKey(
"raw",
encoder.encode(secret),
{ name: "HMAC", hash: "SHA-256" },
false,
["sign"],
);

const signature = await crypto.subtle.sign(
"HMAC",
key,
encoder.encode(payload),
);

return Array.from(new Uint8Array(signature))
.map((byte) => byte.toString(16).padStart(2, "0"))
.join("");
}

/**

* Compare les signatures sans arrêter la comparaison
* au premier caractère différent.
  */
  function signaturesMatch(
  expected: string,
  actual: string,
  ): boolean {
  if (
  !/^[a-f0-9]{64}$/i.test(expected) ||
  !/^[a-f0-9]{64}$/i.test(actual)
  ) {
  return false;
  }

let difference = 0;

for (let i = 0; i < expected.length; i++) {
difference |= expected.charCodeAt(i) ^ actual.charCodeAt(i);
}

return difference === 0;
}

export default {
fetch: withSupabase<Database>(
{ auth: "user" },
async (req, ctx) => {
try {
// 1. Seules les requêtes POST sont autorisées.
if (req.method !== "POST") {
return jsonResponse(
{
success: false,
message: "Méthode HTTP non autorisée.",
},
405,
);
}

    // 2. Vérifier l'utilisateur authentifié.
    const userId = ctx.userClaims?.id;

    if (!userId) {
      return jsonResponse(
        {
          success: false,
          result: "unauthorized",
          message: "Utilisateur non authentifié.",
        },
        401,
      );
    }

    // 3. Le client administrateur est utilisé uniquement
    // dans cette fonction côté serveur.
    const supabase = ctx.supabaseAdmin;

    // 4. Vérifier que l'utilisateur est un assistant actif.
    const {
      data: assistant,
      error: assistantError,
    } = await supabase
      .from("assistants")
      .select("id, is_active")
      .eq("auth_user_id", userId)
      .maybeSingle();

    if (assistantError) {
      console.error(
        "Erreur de vérification de l'assistant:",
        assistantError.message,
      );

      return jsonResponse(
        {
          success: false,
          message: "Impossible de vérifier les autorisations.",
        },
        500,
      );
    }

    if (!assistant || assistant.is_active !== true) {
      return jsonResponse(
        {
          success: false,
          result: "forbidden",
          message: "Accès réservé aux assistants actifs.",
        },
        403,
      );
    }

    // 5. Lire et valider le numéro du reçu.
    let body: { receipt_number?: unknown };

    try {
      body = await req.json();
    } catch {
      return jsonResponse(
        {
          success: false,
          message: "Le corps de la requête est invalide.",
        },
        400,
      );
    }

    const receiptNumber = body?.receipt_number;

    if (
      typeof receiptNumber !== "string" ||
      !/^SP-\d{4}-\d{6}$/.test(receiptNumber)
    ) {
      return jsonResponse(
        {
          success: false,
          message: "Numéro de reçu invalide.",
        },
        400,
      );
    }

    // 6. Rechercher le paiement officiel.
    const {
      data: paymentData,
      error: paymentError,
    } = await supabase
      .from("payments")
      .select(
        "id, receipt_number, student_id, amount, currency, flutterwave_transaction_id, paid_at, status, receipt_signature",
      )
      .eq("receipt_number", receiptNumber)
      .maybeSingle();

    if (paymentError) {
      console.error(
        "Erreur de recherche du paiement:",
        paymentError.message,
      );

      return jsonResponse(
        {
          success: false,
          message: "Impossible de vérifier le reçu.",
        },
        500,
      );
    }

    if (!paymentData) {
      return jsonResponse(
        {
          success: false,
          result: "not_found",
          message: "Reçu introuvable dans le système officiel.",
        },
        404,
      );
    }

    // Le résultat est maintenant vérifié comme non nul.
    const payment: Pick<
      PaymentRow,
      | "id"
      | "receipt_number"
      | "student_id"
      | "amount"
      | "currency"
      | "flutterwave_transaction_id"
      | "paid_at"
      | "status"
      | "receipt_signature"
    > = paymentData;

    // 7. Un paiement en attente ne prouve pas un paiement validé.
    if (payment.status !== "validated") {
      return jsonResponse({
        success: true,
        result: "not_validated",
        message: "Ce paiement n'est pas encore validé.",
        receipt_number: payment.receipt_number,
        payment_status: payment.status,
      });
    }

    // 8. Vérifier la présence du secret côté serveur.
    const secret = Deno.env.get("RECEIPT_SECRET");

    if (!secret) {
      console.error("RECEIPT_SECRET est absent.");

      return jsonResponse(
        {
          success: false,
          message: "Le service de vérification est indisponible.",
        },
        500,
      );
    }

    const transactionId = payment.flutterwave_transaction_id;
    const paidAt = payment.paid_at;
    const amount = payment.amount;
    const currency = payment.currency;
    const storedSignature = payment.receipt_signature;
    const storedReceiptNumber = payment.receipt_number;

    if (
      !storedReceiptNumber ||
      !payment.student_id ||
      !Number.isFinite(amount) ||
      !currency ||
      !transactionId ||
      !paidAt ||
      !storedSignature
    ) {
      return jsonResponse({
        success: false,
        result: "invalid_signature",
        message:
          "Le reçu ne contient pas toutes les données nécessaires à sa vérification.",
        receipt_number: storedReceiptNumber,
      });
    }

    // 9. Reconstruire le payload exactement comme sign-document.
    const dataToSign = [
      storedReceiptNumber,
      payment.student_id,
      amount,
      currency,
      transactionId,
      paidAt,
    ].join("|");

    const expectedSignature = await generateReceiptSignature(
      secret,
      dataToSign,
    );

    // 10. Vérifier la signature cryptographique.
    if (!signaturesMatch(expectedSignature, storedSignature)) {
      return jsonResponse({
        success: false,
        result: "invalid_signature",
        message:
          "Signature invalide : l'authenticité du reçu n'est pas confirmée.",
        receipt_number: storedReceiptNumber,
      });
    }

    // 11. Récupérer les informations officielles de l'étudiant.
    const {
      data: studentData,
      error: studentError,
    } = await supabase
      .from("students")
      .select(
        "full_name, matricule, faculty, department, promotion",
      )
      .eq("id", payment.student_id)
      .maybeSingle();

    if (studentError) {
      console.error(
        "Erreur de recherche de l'étudiant:",
        studentError.message,
      );

      return jsonResponse(
        {
          success: false,
          message:
            "Impossible de récupérer les informations de l'étudiant.",
        },
        500,
      );
    }

    if (!studentData) {
      return jsonResponse({
        success: false,
        result: "student_not_found",
        message:
          "Le paiement est signé, mais l'étudiant correspondant est introuvable.",
        receipt_number: storedReceiptNumber,
      });
    }

    const student: Pick<
      StudentRow,
      "full_name" | "matricule" | "faculty" | "department" | "promotion"
    > = studentData;

    // 12. Retourner uniquement les informations nécessaires.
    return jsonResponse({
      success: true,
      result: "authentic",
      message: "Reçu authentique. Signature vérifiée avec succès.",
      receipt: {
        receipt_number: storedReceiptNumber,
        amount,
        currency,
        paid_at: paidAt,
        status: payment.status,
      },
      student: {
        full_name: student.full_name,
        matricule: student.matricule,
        faculty: student.faculty,
        department: student.department,
        promotion: student.promotion,
      },
    });
  } catch (error) {
    console.error(
      "Erreur interne de vérification du reçu:",
      error instanceof Error ? error.message : String(error),
    );

    return jsonResponse(
      {
        success: false,
        message:
          "Une erreur interne est survenue pendant la vérification.",
      },
      500,
    );
  }
},

),
};
const FLW_SECRET_KEY = Deno.env.get("FLW_SECRET_KEY");

if (!FLW_SECRET_KEY) {
  throw new Error("FLW_SECRET_KEY introuvable.");
}

const API = "https://api.flutterwave.com/v3";

export interface FlutterwavePaymentRequest {
  txRef: string;
  amount: number;
  currency: string;
  customerName: string;
  customerEmail: string;
  redirectUrl: string;
  paymentMethod: string;
}

interface FlutterwaveCheckoutResponse {
  status: string;
  message: string;
  data?: {
    link?: string;
  };
}

interface FlutterwaveTransactionVerificationResponse {
  status: string;
  message: string;
  data?: {
    id: number;
    tx_ref: string;
    amount: number;
    currency: string;
    status: string;
  } | null;
}

// ============================================================
// VÉRIFICATION OFFICIELLE D'UNE TRANSACTION FLUTTERWAVE V3
// ============================================================

export async function verifyFlutterwaveTransaction({
  transactionId,
  expectedTxRef,
  expectedAmount,
  expectedCurrency,
}: {
  transactionId: string;
  expectedTxRef: string;
  expectedAmount: number;
  expectedCurrency: string;
}): Promise<void> {
  if (!transactionId.trim()) {
    throw new Error(
      "Identifiant de transaction absent.",
    );
  }

  const response = await fetch(
    `https://api.flutterwave.com/v3/transactions/${encodeURIComponent(transactionId)}/verify`,
    {
      method: "GET",
      headers: {
        Authorization: `Bearer ${FLW_SECRET_KEY}`,
        Accept: "application/json",
      },
    },
  );

  let result: FlutterwaveTransactionVerificationResponse;

  try {
    result =
      await response.json() as FlutterwaveTransactionVerificationResponse;
  } catch {
    throw new Error(
      `Réponse de vérification Flutterwave invalide. HTTP ${response.status}`,
    );
  }

  if (
    !response.ok ||
    result.status !== "success" ||
    !result.data
  ) {
    throw new Error(
      `Vérification Flutterwave impossible : ${result.message ?? response.status}`,
    );
  }

  const transaction = result.data;

  if (String(transaction.id) !== transactionId) {
    throw new Error(
      "Identifiant de transaction non concordant.",
    );
  }

  if (transaction.status !== "successful") {
    throw new Error(
      "La transaction Flutterwave n'est pas réussie.",
    );
  }

  if (transaction.tx_ref !== expectedTxRef) {
    throw new Error(
      "Référence de transaction non concordante.",
    );
  }

  if (
    transaction.currency.toUpperCase() !==
    expectedCurrency.toUpperCase()
  ) {
    throw new Error(
      "Devise de transaction non concordante.",
    );
  }

  // SmartPass exige le montant exact de la session.
  if (
    Number(transaction.amount) !==
    Number(expectedAmount)
  ) {
    throw new Error(
      "Montant de transaction non concordant.",
    );
  }

  console.log(
    "Transaction Flutterwave vérifiée avec succès.",
    {
      transactionId,
      txRef: expectedTxRef,
      amount: expectedAmount,
      currency: expectedCurrency,
    },
  );
}

// ============================================================
// CRÉATION DU LIEN DE PAIEMENT FLUTTERWAVE
// ============================================================

export async function createFlutterwaveCheckout(
  request: FlutterwavePaymentRequest,
): Promise<{ checkoutUrl: string }> {
  // Détermination des moyens de paiement.
  let paymentOptions = "card";

  if (
    request.paymentMethod === "Orange" ||
    request.paymentMethod === "MTN"
  ) {
    paymentOptions = "mobilemoneyxaf,card";
  }

  const response = await fetch(
    `${API}/payments`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${FLW_SECRET_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        tx_ref: request.txRef,
        amount: request.amount,
        currency: request.currency,
        redirect_url: request.redirectUrl,
        payment_options: paymentOptions,
        customer: {
          email: request.customerEmail,
          name: request.customerName,
        },
        customizations: {
          title: "ULPGL SmartPass",
          description:
            "Paiement des frais d'accès aux examens",
        },
      }),
    },
  );

  let json: FlutterwaveCheckoutResponse;

  try {
    json =
      await response.json() as FlutterwaveCheckoutResponse;
  } catch {
    throw new Error(
      `Réponse Flutterwave invalide. HTTP ${response.status}`
    );
  }

  if (!response.ok) {
    throw new Error(
      `Flutterwave Error HTTP ${response.status}: ${
        json.message ?? "Erreur inconnue"
      }`,
    );
  }

  if (
    json.status !== "success" ||
    !json.data?.link
  ) {
    throw new Error(
      `Flutterwave n'a pas fourni de lien de paiement : ${
        json.message ?? "Erreur inconnue"
      }`,
    );
  }

  return {
    checkoutUrl: json.data.link,
  };
}
const FLW_SECRET_KEY = Deno.env.get("FLW_SECRET_KEY");

if (!FLW_SECRET_KEY) {
  throw new Error("FLW_SECRET_KEY introuvable.");
}

const API = "https://api.flutterwave.com/v3/payments";

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

export async function createFlutterwaveCheckout(
  request: FlutterwavePaymentRequest,
): Promise<{ checkoutUrl: string }> {
  // Détermination du paramètre payment_options selon le choix de l'étudiant
  let paymentOptions = "card";

  if (request.paymentMethod === "Orange" || request.paymentMethod === "MTN") {
    // Utilisation du canal Mobile Money XAF disponible sur ton dashboard pour l'Afrique Centrale
    paymentOptions = "mobilemoneyxaf,card"; 
  }

  const response = await fetch(API, {
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
      payment_options: paymentOptions, // Applique le filtre dynamique
      customer: {
        email: request.customerEmail,
        name: request.customerName,
      },
      customizations: {
        title: "ULPGL SmartPass",
        description: "Paiement des frais d'accès aux examens",
      },
    }),
  });

  let json: FlutterwaveCheckoutResponse;

  try {
    json = await response.json() as FlutterwaveCheckoutResponse;
  } catch (_) {
    throw new Error(
      `Réponse Flutterwave invalide. HTTP ${response.status}`,
    );
  }

  if (!response.ok) {
    throw new Error(
      `Flutterwave Error HTTP ${response.status}: ${json.message ?? "Erreur inconnue"}`,
    );
  }

  if (json.status !== "success" || !json.data?.link) {
    throw new Error(
      `Flutterwave n'a pas fourni de lien de paiement: ${json.message ?? "Erreur inconnue"}`,
    );
  }

  return {
    checkoutUrl: json.data.link,
  };
}
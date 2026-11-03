import { createClient } from "npm:@supabase/supabase-js@2";

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

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
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
    // 1. Configuration Supabase
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !anonKey || !serviceRoleKey) {
      console.error("Configuration Supabase incomplète.");

      return jsonResponse(500, {
        success: false,
        message: "Configuration serveur incomplète.",
      });
    }

    // 2. Authentifier l'utilisateur avec son JWT
    const authorization = request.headers.get("Authorization");

    if (!authorization?.startsWith("Bearer ")) {
      return jsonResponse(401, {
        success: false,
        message: "Authentification requise.",
      });
    }

    const token = authorization.substring("Bearer ".length).trim();

    const userClient = createClient(supabaseUrl, anonKey, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    });

    const {
      data: { user },
      error: authError,
    } = await userClient.auth.getUser(token);

    if (authError || !user || !user.email) {
      return jsonResponse(401, {
        success: false,
        message: "Session utilisateur invalide.",
      });
    }

    // 3. Lire et valider le mot de passe
    let body: unknown;

    try {
      body = await request.json();
    } catch {
      return jsonResponse(400, {
        success: false,
        message: "Corps JSON invalide.",
      });
    }

    if (!isRecord(body) || typeof body.password !== "string") {
      return jsonResponse(400, {
        success: false,
        message: "Mot de passe manquant.",
      });
    }

    const password = body.password;

    if (password.length < 8 || password.length > 128) {
      return jsonResponse(400, {
        success: false,
        message: "Le mot de passe doit contenir entre 8 et 128 caractères.",
      });
    }

    // 4. Client administratif réservé au serveur
    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    });

    // 5. Vérifier le profil Assistant lié à cet utilisateur
    const { data: assistant, error: assistantError } =
      await adminClient
        .from("assistants")
        .select("id, auth_user_id, email, is_active")
        .eq("auth_user_id", user.id)
        .maybeSingle();

    if (assistantError) {
      console.error("Lecture profil Assistant:", assistantError.message);

      return jsonResponse(500, {
        success: false,
        message: "Impossible de vérifier le profil Assistant.",
      });
    }

    if (!assistant) {
      return jsonResponse(403, {
        success: false,
        message: "Aucun profil Assistant associé à ce compte.",
      });
    }

    if (
      assistant.email?.trim().toLowerCase() !==
      user.email.trim().toLowerCase()
    ) {
      return jsonResponse(403, {
        success: false,
        message: "L'adresse e-mail ne correspond pas au profil Assistant.",
      });
    }

    if (assistant.is_active === true) {
      return jsonResponse(409, {
        success: false,
        message: "Ce compte Assistant est déjà activé.",
      });
    }

    // 6. Vérifier l'invitation en attente
    const { data: invitation, error: invitationError } =
      await adminClient
        .from("assistant_invitations")
        .select("id, assistant_id, email, status, expires_at")
        .eq("assistant_id", assistant.id)
        .eq("status", "pending")
        .maybeSingle();

    if (invitationError) {
      console.error("Lecture invitation:", invitationError.message);

      return jsonResponse(500, {
        success: false,
        message: "Impossible de vérifier l'invitation.",
      });
    }

    if (!invitation) {
      return jsonResponse(403, {
        success: false,
        message: "Aucune invitation en attente pour ce compte.",
      });
    }

    if (
      invitation.email.trim().toLowerCase() !==
      user.email.trim().toLowerCase()
    ) {
      return jsonResponse(403, {
        success: false,
        message: "L'invitation ne correspond pas à cette adresse e-mail.",
      });
    }

    if (new Date(invitation.expires_at).getTime() <= Date.now()) {
      await adminClient
        .from("assistant_invitations")
        .update({ status: "expired" })
        .eq("id", invitation.id)
        .eq("status", "pending");

      return jsonResponse(410, {
        success: false,
        message: "Cette invitation a expiré. Demandez une nouvelle invitation.",
      });
    }

    // 7. Réserver l'invitation pour éviter une double activation
    const { data: claimedInvitation, error: claimError } =
      await adminClient
        .from("assistant_invitations")
        .update({
          status: "accepted",
          accepted_at: new Date().toISOString(),
        })
        .eq("id", invitation.id)
        .eq("status", "pending")
        .gt("expires_at", new Date().toISOString())
        .select("id")
        .maybeSingle();

    if (claimError) {
      console.error("Réservation invitation:", claimError.message);

      return jsonResponse(500, {
        success: false,
        message: "Impossible de valider l'invitation.",
      });
    }

    if (!claimedInvitation) {
      return jsonResponse(409, {
        success: false,
        message: "Cette invitation a déjà été utilisée ou a expiré.",
      });
    }

    // 8. Définir le mot de passe côté serveur
    const { error: passwordError } =
      await adminClient.auth.admin.updateUserById(user.id, {
        password,
      });

    if (passwordError) {
      console.error("Définition mot de passe:", passwordError.message);

      // Réouvrir l'invitation si la modification du mot de passe échoue.
      await adminClient
        .from("assistant_invitations")
        .update({
          status: "pending",
          accepted_at: null,
        })
        .eq("id", invitation.id)
        .eq("status", "accepted");

      return jsonResponse(400, {
        success: false,
        message: "Impossible de définir le mot de passe.",
      });
    }

    // 9. Activer le profil Assistant
    const { data: activatedAssistant, error: activationError } =
      await adminClient
        .from("assistants")
        .update({ is_active: true })
        .eq("id", assistant.id)
        .eq("auth_user_id", user.id)
        .eq("is_active", false)
        .select("id")
        .maybeSingle();

    if (activationError || !activatedAssistant) {
      console.error(
        "Activation profil:",
        activationError?.message ?? "Aucune ligne modifiée.",
      );

      return jsonResponse(500, {
        success: false,
        code: "PASSWORD_SET_ACTIVATION_FAILED",
        message:
          "Le mot de passe a été défini, mais l'activation du profil a échoué. Une intervention administrative est nécessaire.",
      });
    }

    // 10. Succès
    return jsonResponse(200, {
      success: true,
      message: "Votre compte Assistant a été activé avec succès.",
    });
  } catch (error) {
    console.error(
      "Erreur activate-assistant:",
      error instanceof Error ? error.message : String(error),
    );

    return jsonResponse(500, {
      success: false,
      message: "Une erreur interne est survenue pendant l'activation.",
    });
  }
});
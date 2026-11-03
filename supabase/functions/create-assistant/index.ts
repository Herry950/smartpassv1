import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type AssistantInput = {
  full_name: string;
  email: string;
  employee_number: string;
  phone: string;
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

function cleanString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
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

  let adminClient: any = null;
  let createdAuthUserId: string | null = null;
  let createdAssistantId: string | null = null;

  try {
    // 1. Configuration distante Supabase
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const redirectTo = Deno.env.get("APP_INVITE_REDIRECT_URL");

    if (!supabaseUrl || !anonKey || !serviceRoleKey || !redirectTo) {
      console.error("Configuration serveur incomplète.");

      return jsonResponse(500, {
        success: false,
        message: "Configuration serveur incomplète.",
      });
    }

    // 2. Vérifier la session de l'Admin
    const authorization = request.headers.get("Authorization");

    if (!authorization?.startsWith("Bearer ")) {
      return jsonResponse(401, {
        success: false,
        message: "Authentification requise.",
      });
    }

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authorization } },
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    });

    const {
      data: { user },
      error: authError,
    } = await userClient.auth.getUser();

    if (authError || !user) {
      return jsonResponse(401, {
        success: false,
        message: "Session utilisateur invalide.",
      });
    }

    // 3. Lire et valider les données
    let body: unknown;

    try {
      body = await request.json();
    } catch {
      return jsonResponse(400, {
        success: false,
        message: "Le corps de la requête doit être un JSON valide.",
      });
    }

    if (!isRecord(body)) {
      return jsonResponse(400, {
        success: false,
        message: "Les données reçues sont invalides.",
      });
    }

    const input: AssistantInput = {
      full_name: cleanString(body.full_name),
      email: cleanString(body.email).toLowerCase(),
      employee_number: cleanString(body.employee_number),
      phone: cleanString(body.phone),
    };

    if (!input.full_name || input.full_name.length > 150) {
      return jsonResponse(400, {
        success: false,
        message: "Le nom complet est obligatoire (150 caractères maximum).",
      });
    }

    if (
      !input.email ||
      input.email.length > 254 ||
      !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(input.email)
    ) {
      return jsonResponse(400, {
        success: false,
        message: "Adresse e-mail invalide.",
      });
    }

    if (
      input.employee_number.length > 50 ||
      input.phone.length > 30
    ) {
      return jsonResponse(400, {
        success: false,
        message: "Le matricule professionnel ou le téléphone est trop long.",
      });
    }

    // 4. Client administratif
    adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    });
//diagnoctic de l'utilisation du service role par rapport à l'utilisateur admin connecté
    const { data: roleCheck, error: roleError } =
  await adminClient.rpc("get_current_role");

console.log("DIAGNOSTIC SERVICE ROLE:", {
  role: roleCheck,
  error: roleError?.message ?? null,
});

    // 5. Vérifier les droits Admin
    const { data: administrator, error: adminError } =
      await adminClient
        .from("admins")
        .select("id")
        .eq("auth_user_id", user.id)
        .eq("is_active", true)
        .maybeSingle();

    if (adminError) {
      console.error("Vérification Admin:", adminError.message);

      return jsonResponse(500, {
        success: false,
        message: "Impossible de vérifier les droits administrateur.",
      });
    }

    if (!administrator) {
      return jsonResponse(403, {
        success: false,
        message: "Accès réservé aux administrateurs actifs.",
      });
    }

    // 6. Mode test sans création
    if (body.dry_run === true) {
      return jsonResponse(200, {
        success: true,
        code: "ADMIN_AUTHORIZED",
        message: "Authentification et droits administrateur vérifiés.",
      });
    }

    // 7. Vérifier les doublons
    const { data: existingEmail, error: emailError } =
      await adminClient
        .from("assistants")
        .select("id")
        .ilike("email", input.email)
        .limit(1)
        .maybeSingle();

    if (emailError) {
      console.error("Recherche e-mail:", emailError.message);

      return jsonResponse(500, {
        success: false,
        message: "Impossible de vérifier cette adresse e-mail.",
      });
    }

    if (existingEmail) {
      return jsonResponse(409, {
        success: false,
        code: "ASSISTANT_EMAIL_EXISTS",
        message: "Cette adresse e-mail est déjà associée à un assistant.",
      });
    }

    if (input.employee_number) {
      const { data: existingNumber, error: numberError } =
        await adminClient
          .from("assistants")
          .select("id")
          .eq("employee_number", input.employee_number)
          .limit(1)
          .maybeSingle();

      if (numberError) {
        console.error("Recherche matricule:", numberError.message);

        return jsonResponse(500, {
          success: false,
          message: "Impossible de vérifier le matricule professionnel.",
        });
      }

      if (existingNumber) {
        return jsonResponse(409, {
          success: false,
          code: "ASSISTANT_NUMBER_EXISTS",
          message: "Ce matricule professionnel est déjà utilisé.",
        });
      }
    }

    // 8. Créer le compte Auth et envoyer l'invitation
    const { data: invitation, error: invitationError } =
      await adminClient.auth.admin.inviteUserByEmail(input.email, {
        redirectTo,
        data: {
          full_name: input.full_name,
          role: "assistant",
        },
      });

    if (invitationError || !invitation.user) {
      console.error(
        "Invitation Auth:",
        invitationError?.message ?? "Utilisateur non retourné.",
      );

      return jsonResponse(409, {
        success: false,
        code: "ASSISTANT_INVITATION_FAILED",
        message:
          "Impossible de créer l'invitation. Vérifiez l'adresse e-mail et la configuration Supabase Auth.",
      });
    }

    createdAuthUserId = invitation.user.id;

    // 9. Créer le profil Assistant inactif
    const { data: assistant, error: profileError } =
      await adminClient
        .from("assistants")
        .insert({
          auth_user_id: createdAuthUserId,
          full_name: input.full_name,
          email: input.email,
          employee_number: input.employee_number || null,
          phone: input.phone || null,
          is_active: false,
        })
        .select(
          "id, auth_user_id, full_name, email, employee_number, phone, is_active, created_at",
        )
        .single();

    if (profileError || !assistant) {
      console.error("Création profil:", profileError?.message);
      throw new Error("ASSISTANT_PROFILE_CREATION_FAILED");
    }

    createdAssistantId = assistant.id;

    // 10. Enregistrer l'invitation pendant 24 heures
    const { error: invitationRecordError } =
      await adminClient
        .from("assistant_invitations")
        .insert({
          assistant_id: assistant.id,
          email: input.email,
          status: "pending",
          expires_at: new Date(
            Date.now() + 24 * 60 * 60 * 1000,
          ).toISOString(),
        });

    if (invitationRecordError) {
      console.error(
        "Enregistrement invitation:",
        invitationRecordError.message,
      );

      throw new Error("ASSISTANT_INVITATION_RECORD_FAILED");
    }

    // 11. Succès
    createdAuthUserId = null;
    createdAssistantId = null;

    return jsonResponse(201, {
      success: true,
      message:
        "Assistant créé. Une invitation a été envoyée pour définir son mot de passe.",
      assistant,
    });
  } catch (error) {
    console.error(
      "Erreur create-assistant:",
      error instanceof Error ? error.message : String(error),
    );

    // La suppression du profil supprime aussi l'invitation en cascade.
    if (createdAssistantId && adminClient) {
      const { error: profileDeleteError } = await adminClient
        .from("assistants")
        .delete()
        .eq("id", createdAssistantId);

      if (profileDeleteError) {
        console.error("Nettoyage profil:", profileDeleteError.message);
      }
    }

    // Supprimer uniquement le compte Auth créé par cette opération.
    if (createdAuthUserId && adminClient) {
      const { error: authDeleteError } =
        await adminClient.auth.admin.deleteUser(createdAuthUserId);

      if (authDeleteError) {
        console.error("Nettoyage Auth:", authDeleteError.message);
      }
    }

    return jsonResponse(500, {
      success: false,
      code: "ASSISTANT_CREATION_FAILED",
      message:
        "La création de l'assistant a échoué. Vérifiez l'état du compte avant de réessayer.",
    });
  }
});
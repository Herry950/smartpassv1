import { supabase } from "../_shared/supabase.ts";
import { Student } from "../_shared/types.ts";

export async function getAuthenticatedStudent(
  authorization: string,
): Promise<Student> {
  console.log("========== AUTH ==========");

  if (!authorization) {
    throw new Error(
      "Authorization manquante.",
    );
  }

  const token = authorization
    .replace(/^Bearer\s+/i, "")
    .trim();

  if (!token) {
    throw new Error(
      "Token JWT manquant.",
    );
  }

  console.log(
    "Token reçu :",
    token.substring(0, 20) + "...",
  );

  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser(token);

  console.log(
    "Auth user ID :",
    user?.id ?? null,
  );

  console.log(
    "Auth error :",
    authError,
  );

  if (authError || !user) {
    throw new Error(
      `Utilisateur non authentifié : ${
        authError?.message ??
        "Utilisateur absent"
      }`,
    );
  }

  console.log(
    "========== STUDENT SEARCH ==========",
  );

  console.log(
    "Recherche auth_user_id =",
    user.id,
  );

  const {
    data: student,
    error: studentError,
  } = await supabase
    .from("students")
    .select(`
      id,
      auth_user_id,
      matricule,
      full_name
    `)
    .eq("auth_user_id", user.id)
    .maybeSingle();

  console.log(
    "========== MATCH RESULT ==========",
  );

  console.log(
    "Student :",
    student,
  );

  console.log(
    "Student Error :",
    studentError,
  );

  if (studentError) {
    throw new Error(
      `Erreur recherche étudiant : ${
        studentError.message
      } | code=${studentError.code ?? ""}`,
    );
  }

  if (!student) {
    throw new Error(
      `Étudiant introuvable pour auth_user_id = ${user.id}`,
    );
  }

  return {
    id: student.id,
    auth_user_id: student.auth_user_id,
    matricule: student.matricule,
    full_name: student.full_name,
    email: user.email ?? "",
  };
}
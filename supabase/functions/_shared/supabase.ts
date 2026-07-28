import { createClient } from "jsr:@supabase/supabase-js@2";

console.log(
  "SUPABASE_URL =",
  Deno.env.get("SUPABASE_URL"),
);

export const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);
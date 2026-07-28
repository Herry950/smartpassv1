import "@supabase/functions-js/edge-runtime.d.ts";

Deno.serve(async (req) => {
  try {
    const body = await req.json();

    console.log("===== WEBHOOK RECU =====");
    console.log(body);
    console.log("========================");

    return new Response(
      JSON.stringify({
        success: true,
        message: "Webhook reçu avec succès.",
      }),
      {
        headers: {
          "Content-Type": "application/json",
        },
      },
    );
  } catch (e: unknown) {
    return new Response(
      JSON.stringify({
        success: false,
        error: e instanceof Error ? e.message : String(e),
      }),
      {
        status: 500,
        headers: {
          "Content-Type": "application/json",
        },
      },
    );
  }
});
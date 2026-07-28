import { corsHeaders } from "./cors.ts";

export function success(data: unknown) {
  return new Response(
    JSON.stringify(data),
    {
      status: 200,
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json",
      },
    },
  );
}

export function badRequest(message: string) {
  return new Response(
    JSON.stringify({
      success: false,
      error: message,
    }),
    {
      status: 400,
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json",
      },
    },
  );
}

export function unauthorized(
  message = "Unauthorized",
) {
  return new Response(
    JSON.stringify({
      success: false,
      error: message,
    }),
    {
      status: 401,
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json",
      },
    },
  );
}

export function forbidden(message: string) {
  return new Response(
    JSON.stringify({
      success: false,
      error: message,
    }),
    {
      status: 403,
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json",
      },
    },
  );
}

export function notFound(message: string) {
  return new Response(
    JSON.stringify({
      success: false,
      error: message,
    }),
    {
      status: 404,
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json",
      },
    },
  );
}

export function serverError(message: string) {
  return new Response(
    JSON.stringify({
      success: false,
      error: message,
    }),
    {
      status: 500,
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json",
      },
    },
  );
}
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2.58.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "https://moz-saloes.github.io",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json; charset=utf-8",
};
function json(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders });
}
function isAllowedPushEndpoint(value: unknown): value is string {
  if (typeof value !== "string" || value.length < 20 || value.length > 2048) return false;
  try {
    const url = new URL(value);
    const host = url.hostname.toLowerCase();
    const allowed = host === "fcm.googleapis.com" ||
      host.endsWith(".push.services.mozilla.com") ||
      host === "web.push.apple.com";
    return url.protocol === "https:" && allowed && !url.username && !url.password;
  } catch {
    return false;
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json(405, { error: "method_not_allowed" });

  const authorization = req.headers.get("authorization") ?? "";
  const token = authorization.replace(/^Bearer\s+/i, "");
  if (!token) return json(401, { error: "authentication_required" });

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const publishableKeysRaw = Deno.env.get("SUPABASE_PUBLISHABLE_KEYS") ?? "";
  const secretKeysRaw = Deno.env.get("SUPABASE_SECRET_KEYS") ?? "";
  let publishableKey = "";
  let serviceKey = "";
  try {
    publishableKey = JSON.parse(publishableKeysRaw).default ?? "";
    serviceKey = JSON.parse(secretKeysRaw).default ?? "";
  } catch {
    return json(503, { error: "server_configuration_invalid" });
  }
  if (!supabaseUrl || !publishableKey || !serviceKey) {
    return json(503, { error: "server_configuration_missing" });
  }

  const userClient = createClient(supabaseUrl, publishableKey, {
    global: { headers: { Authorization: "Bearer " + token } },
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: userData, error: userError } = await userClient.auth.getUser(token);
  if (userError || !userData.user) return json(401, { error: "invalid_session" });
  const userId = userData.user.id;

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json(400, { error: "invalid_json" });
  }
  const action = body.action;
  const subscription = (body.subscription && typeof body.subscription === "object")
    ? body.subscription as Record<string, unknown>
    : {};
  const endpoint = subscription.endpoint;

  if (!isAllowedPushEndpoint(endpoint)) return json(400, { error: "invalid_push_endpoint" });

  const admin = createClient(supabaseUrl, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  if (action === "remove") {
    const { error } = await admin.from("push_subscriptions")
      .delete().eq("user_id", userId).eq("endpoint", endpoint);
    if (error) return json(500, { error: "subscription_removal_failed" });
    return json(200, { removed: true });
  }

  if (action !== "register") return json(400, { error: "unsupported_action" });
  const keys = (subscription.keys && typeof subscription.keys === "object")
    ? subscription.keys as Record<string, unknown>
    : {};
  const p256dh = keys.p256dh;
  const auth = keys.auth;
  if (typeof p256dh !== "string" || p256dh.length < 20 || p256dh.length > 256 ||
      typeof auth !== "string" || auth.length < 8 || auth.length > 128) {
    return json(400, { error: "invalid_subscription_keys" });
  }

  // Remove any previous account binding for this browser endpoint before assigning it to the current session.
  const { error: deleteError } = await admin.from("push_subscriptions").delete().eq("endpoint", endpoint);
  if (deleteError) return json(500, { error: "subscription_reassignment_failed" });

  const { error: insertError } = await admin.from("push_subscriptions").insert({
    user_id: userId,
    endpoint,
    p256dh,
    auth,
    user_agent: null,
    last_seen_at: new Date().toISOString(),
    disabled_at: null,
  });
  if (insertError) return json(500, { error: "subscription_registration_failed" });
  return json(200, { registered: true });
});

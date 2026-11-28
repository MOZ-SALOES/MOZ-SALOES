import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import webpush from "npm:web-push@3.6.7";
import { createClient } from "npm:@supabase/supabase-js@2.58.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "https://moz-saloes.github.io",
  "Access-Control-Allow-Headers": "content-type, x-moz-webhook-secret",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json; charset=utf-8",
};

function json(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders });
}

function constantTimeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let mismatch = 0;
  for (let i = 0; i < a.length; i++) mismatch |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return mismatch === 0;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json(405, { error: "method_not_allowed" });

  const webhookSecret = Deno.env.get("MOZ_PUSH_WEBHOOK_SECRET") ?? "";
  const providedSecret = req.headers.get("x-moz-webhook-secret") ?? "";
  if (!webhookSecret || !providedSecret || !constantTimeEqual(webhookSecret, providedSecret)) {
    return json(401, { error: "unauthorized" });
  }

  const vapidPublicKey = Deno.env.get("MOZ_VAPID_PUBLIC_KEY") ?? "";
  const vapidPrivateKey = Deno.env.get("MOZ_VAPID_PRIVATE_KEY") ?? "";
  const vapidSubject = Deno.env.get("MOZ_VAPID_SUBJECT") ?? "";
  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const secretKeysRaw = Deno.env.get("SUPABASE_SECRET_KEYS") ?? "";
  let serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

  try {
    if (!serviceKey && secretKeysRaw) {
      const secretKeys = JSON.parse(secretKeysRaw);
      serviceKey = secretKeys.default ?? "";
    }
  } catch {
    return json(503, { error: "server_configuration_invalid" });
  }

  if (!vapidPublicKey || !vapidPrivateKey || !vapidSubject || !supabaseUrl || !serviceKey) {
    return json(503, { error: "push_not_configured" });
  }

  let payload: Record<string, unknown>;
  try {
    payload = await req.json();
  } catch {
    return json(400, { error: "invalid_json" });
  }

  const table = payload.table;
  const record = (payload.record && typeof payload.record === "object")
    ? payload.record as Record<string, unknown>
    : (payload.new && typeof payload.new === "object")
    ? payload.new as Record<string, unknown>
    : {};
  if (table !== "user_notifications" && table !== "admin_notifications") {
    return json(400, { error: "unsupported_notification_source" });
  }
  const notificationId = typeof record.id === "string" ? record.id : "";
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(notificationId)) {
    return json(400, { error: "invalid_notification_id" });
  }

  const supabase = createClient(supabaseUrl, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  webpush.setVapidDetails(vapidSubject, vapidPublicKey, vapidPrivateKey);

  const { data: notification, error: notificationError } = await supabase
    .from(table)
    .select("id,recipient_id,read_at")
    .eq("id", notificationId)
    .maybeSingle();
  if (notificationError || !notification) return json(404, { error: "notification_not_found" });
  if (notification.read_at) return json(200, { sent: 0, skipped: "already_read" });

  const { data: subscriptions, error: subscriptionError } = await supabase
    .from("push_subscriptions")
    .select("id,endpoint,p256dh,auth")
    .eq("user_id", notification.recipient_id)
    .is("disabled_at", null)
    .limit(20);
  if (subscriptionError) return json(500, { error: "subscriptions_unavailable" });
  if (!subscriptions?.length) return json(200, { sent: 0, expired: 0 });

  // Push content is deliberately generic: private appointment details remain inside the authenticated app.
  const pushPayload = JSON.stringify({
    title: "MOZ SALÕES",
    body: "Tens uma nova mensagem. Entra na tua conta para consultar.",
    url: "./#owner",
    tag: "moz-saloes-message-" + notification.id,
  });

  let sent = 0;
  let expired = 0;
  for (const item of subscriptions) {
    try {
      await webpush.sendNotification({
        endpoint: item.endpoint,
        keys: { p256dh: item.p256dh, auth: item.auth },
      }, pushPayload, { TTL: 60 * 60 * 24, urgency: "normal" });
      sent++;
    } catch (error) {
      const statusCode = (error as { statusCode?: number })?.statusCode;
      if (statusCode === 404 || statusCode === 410) {
        await supabase.from("push_subscriptions")
          .update({ disabled_at: new Date().toISOString() })
          .eq("id", item.id)
          .eq("user_id", notification.recipient_id);
        expired++;
      } else {
        console.error("Push delivery failed", { statusCode: statusCode ?? "unknown" });
      }
    }
  }

  return json(200, { sent, expired, attempted: subscriptions.length });
});

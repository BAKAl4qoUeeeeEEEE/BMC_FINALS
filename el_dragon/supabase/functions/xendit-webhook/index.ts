import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (request: Request) => {
  if (request.method !== "POST") return new Response("Method not allowed", { status: 405 });

  const callbackToken = Deno.env.get("XENDIT_WEBHOOK_TOKEN");
  const suppliedToken = request.headers.get("x-callback-token");
  if (!callbackToken || !suppliedToken || callbackToken !== suppliedToken) {
    console.error("Webhook rejected: invalid Xendit callback token.");
    return new Response("Unauthorized", { status: 401 });
  }

  try {
    const event = await request.json();
    const externalId = event?.external_id;
    const status = String(event?.status ?? "").toUpperCase();
    if (typeof externalId !== "string" || !externalId.startsWith("el_dragon_") || !status) {
      return new Response("Invalid invoice event", { status: 400 });
    }
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceRoleKey) return new Response("Server configuration error", { status: 500 });

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const updates: Record<string, unknown> = { status };
    if (status === "PAID") updates.paid_at = event.paid_at ?? new Date().toISOString();
    if (event.id) updates.xendit_invoice_id = event.id;

    const { data, error } = await supabase.from("orders").update(updates)
      .eq("external_id", externalId).select("id").maybeSingle();
    if (error) {
      console.error("Could not update order from webhook:", error.message);
      return new Response("Could not update order", { status: 500 });
    }
    if (!data) return new Response("Order not found", { status: 404 });
    return new Response("ok", { status: 200 });
  } catch (error) {
    console.error("Webhook processing failed:", error);
    return new Response("Invalid webhook payload", { status: 400 });
  }
});

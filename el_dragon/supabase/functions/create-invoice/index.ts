import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function reply(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return reply(405, { error: "Method not allowed." });

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const xenditSecret = Deno.env.get("XENDIT_SECRET_KEY");
    if (!supabaseUrl || !serviceRoleKey || !xenditSecret) {
      console.error("Missing Supabase runtime config or XENDIT_SECRET_KEY.");
      return reply(500, { error: "Checkout is not configured on the server." });
    }

    const body = await request.json();
    if (!Array.isArray(body?.items) || body.items.length < 1 || body.items.length > 50) {
      return reply(400, { error: "Add between 1 and 50 products to your cart." });
    }

    const quantities = new Map<number, number>();
    for (const item of body.items) {
      const id = Number(item?.product_id);
      const quantity = Number(item?.quantity);
      if (!Number.isSafeInteger(id) || id <= 0 || !Number.isSafeInteger(quantity) || quantity < 1 || quantity > 10) {
        return reply(400, { error: "A product or quantity in the cart is invalid." });
      }
      quantities.set(id, (quantities.get(id) ?? 0) + quantity);
    }
    if ([...quantities.values()].some((quantity) => quantity > 10)) {
      return reply(400, { error: "Maximum quantity is 10 per product." });
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: products, error: productError } = await supabase
      .from("products").select("id, name, price, available").in("id", [...quantities.keys()]);
    if (productError) {
      console.error("Product lookup failed:", productError.message);
      return reply(500, { error: "Could not verify products. Please try again." });
    }
    if (!products || products.length !== quantities.size || products.some((p) => p.available !== true)) {
      return reply(400, { error: "A product is unavailable. Refresh the shop and try again." });
    }

    const invoiceItems = products.map((product) => {
      const price = Number(product.price);
      const quantity = quantities.get(Number(product.id))!;
      if (!Number.isFinite(price) || price <= 0) throw new Error("Invalid product price in database.");
      return { name: String(product.name).slice(0, 255), quantity, price };
    });
    const amount = Math.round(invoiceItems.reduce((sum, item) => sum + item.price * item.quantity, 0) * 100) / 100;
    if (!Number.isFinite(amount) || amount <= 0) return reply(400, { error: "The order total is invalid." });

    const externalId = `el_dragon_${crypto.randomUUID()}`;
    const { error: orderError } = await supabase.from("orders").insert({
      external_id: externalId,
      status: "PENDING",
      amount,
      currency: "PHP",
      items: invoiceItems,
    });
    if (orderError) {
      console.error("Could not save pending order:", orderError.message);
      return reply(500, { error: "Could not save the order. Check the orders table setup." });
    }

    const xenditResponse = await fetch("https://api.xendit.co/v2/invoices", {
      method: "POST",
      headers: {
        Authorization: `Basic ${btoa(`${xenditSecret}:`)}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        external_id: externalId,
        amount,
        currency: "PHP",
        description: `El Dragon order (${quantities.size} product${quantities.size === 1 ? "" : "s"})`,
        invoice_duration: 86400,
        items: invoiceItems,
      }),
    });
    const invoice = await xenditResponse.json().catch(() => ({}));
    if (!xenditResponse.ok) {
      console.error("Xendit invoice request failed:", xenditResponse.status, invoice);
      await supabase.from("orders").update({ status: "FAILED" }).eq("external_id", externalId);
      return reply(502, { error: "Xendit could not create the payment link. Check the function logs and API key mode." });
    }
    if (typeof invoice.invoice_url !== "string" || !invoice.invoice_url.startsWith("https://")) {
      console.error("Xendit did not return a valid invoice_url.");
      await supabase.from("orders").update({ status: "FAILED" }).eq("external_id", externalId);
      return reply(502, { error: "Xendit did not return a checkout URL." });
    }

    const { error: updateError } = await supabase.from("orders")
      .update({ xendit_invoice_id: invoice.id }).eq("external_id", externalId);
    if (updateError) console.error("Could not save Xendit invoice ID:", updateError.message);
    return reply(200, { invoice_url: invoice.invoice_url, invoice_id: invoice.id });
  } catch (error) {
    console.error("Checkout function failed:", error);
    return reply(500, { error: "Could not prepare checkout. Check the Edge Function logs." });
  }
});

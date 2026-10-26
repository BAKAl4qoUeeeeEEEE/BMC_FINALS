# El Dragon checkout setup

The Flutter app reads products from the Supabase `products` table configured in `lib/main.dart`. When a customer taps **Pay with Xendit**, it calls `create-invoice`. The Edge Function validates product IDs and quantities, reads current prices from Supabase, saves a pending order, creates a PHP invoice through Xendit, then returns `invoice_url` for Flutter to open.

## Deploy the Edge Function

Run `supabase/migrations/202610260001_create_orders.sql` in Supabase SQL Editor to create the private orders table. The function sources are in `supabase/functions/create-invoice/` and `supabase/functions/xendit-webhook/`. From this folder, link the Supabase CLI to the same project used by `lib/main.dart`, then deploy both:

```powershell
supabase login
supabase link --project-ref relwoizlzfccmrhxswyl
supabase functions deploy create-invoice --no-verify-jwt
supabase functions deploy xendit-webhook --no-verify-jwt
```

Guest checkout uses the public Supabase anon key, so `supabase/config.toml` disables JWT verification for this function. The function validates the cart and gets prices from the database; it does not trust prices sent by the app.

## Configure Xendit

In Supabase Dashboard > Edge Functions > Secrets, set `XENDIT_SECRET_KEY` to a Xendit **secret API key** and keep your existing `XENDIT_WEBHOOK_TOKEN`. The function runtime reads `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` from Supabase's built-in environment. Keep secret keys in Supabase; never put them in Flutter code. The webhook function checks `XENDIT_WEBHOOK_TOKEN` before it updates an order.

After deployment, copy the `xendit-webhook` function URL from Supabase and add it to Xendit's **Invoices paid** webhook. Then try a checkout and open Edge Functions > `create-invoice` > Logs. If the app reports `FunctionFetchException(status 0)` and there is no function invocation in the logs, check the phone's internet connection, deployed function name and project, or browser CORS/network settings. If an invocation appears, use its log entry to identify whether the Supabase product lookup or Xendit invoice request failed. A successful payment updates the matching order to `PAID` through the webhook.

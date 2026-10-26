# EL-DRAGON — Installation and Setup Guide

EL-DRAGON is a Flutter e-commerce application that uses **Supabase** for backend services and **Xendit** for hosted checkout payments. This guide is intended for a Windows development machine, Android emulator, or Android phone.

> **Important:** This guide is based on the project configuration discussed, not a full source-code audit. Verify table schemas, environment variable names, and application initialization against your local project before deploying. Use **Xendit Test Mode** for testing. Never put Xendit secret keys or Supabase service-role keys inside Flutter client code.

## 1. Requirements

Install the following:

- Flutter SDK (with the Dart SDK bundled with Flutter)
- Android Studio, Android SDK, and Android SDK command-line tools
- Java Development Kit compatible with the project's Android Gradle Plugin (JDK 17 is a common choice)
- Visual Studio Code (optional), with Flutter and Dart extensions
- A Supabase account and project
- A Xendit account with Test Mode enabled
- An Android emulator or Android device with USB debugging enabled

For this project's `pubspec.yaml`, the Dart SDK constraint is:

```yaml
environment:
  sdk: '>=3.13.2 <4.0.0'
```

Check the installed SDK versions rather than assuming compatibility:

```powershell
flutter --version
flutter doctor -v
java -version
```

Follow any missing-component recommendations from `flutter doctor -v`. Accept Android SDK licenses if prompted:

```powershell
flutter doctor --android-licenses
```

## 2. Open the Flutter project

Open PowerShell or the VS Code terminal and go to the folder containing `pubspec.yaml`:

```powershell
cd "C:\Users\STUDENT-PC5\Downloads\BMC\el_dragon"
Test-Path .\pubspec.yaml
```

`Test-Path` must return `True`. If it returns `False`, locate your Flutter project root before continuing.

## 3. Install project dependencies

```powershell
flutter pub get
flutter analyze
```

The dependencies previously shown in `pubspec.yaml` are:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  supabase_flutter: ^2.18.3
  url_launcher: ^6.3.3
```

Keep other dependencies and assets already used by your actual source code. Do not replace the project's `pubspec.yaml` with a minimal example if the project needs more packages.

## 4. Configure Supabase

1. Sign in to the [Supabase Dashboard](https://supabase.com/dashboard) and open the correct project.
2. Confirm that your project's Supabase URL and **publishable/anon** key are configured where the Flutter application initializes Supabase. Do not expose the service-role key.
3. Open **SQL Editor** and review the migration `supabase/migrations/202610260001_create_orders.sql` in this repository. Run the migration only after checking that it does not overwrite existing data or conflict with existing tables.
4. In **Table Editor**, confirm the tables required by the app exist (including `products` and `orders`, if those are the names used by this version).
5. Verify Row Level Security policies: only permitted reads and writes should be possible from the client. **Do not allow anonymous clients to set paid status directly.**

If the application uses values passed via Dart defines, use the exact names expected by your code. For example, only if the app reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` via `String.fromEnvironment`, run:

```powershell
flutter run --dart-define=SUPABASE_URL="YOUR_SUPABASE_URL" --dart-define=SUPABASE_ANON_KEY="YOUR_PUBLISHABLE_OR_ANON_KEY"
```

Otherwise configure the keys using the method already implemented in the application.

## 5. Configure Xendit Test Mode

1. Open the [Xendit Dashboard](https://dashboard.xendit.co/) in **Test Mode**.
2. Under API key settings, confirm the secret key has appropriate payment creation permissions (for example, Money-In: Write, if required by the API in use).
3. In Supabase, go to **Edge Functions → Secrets** and add:

| Secret name | Value |
| --- | --- |
| `XENDIT_SECRET_KEY` | Xendit Test Mode secret API key |
| `XENDIT_WEBHOOK_TOKEN` | Xendit webhook verification token |

Do not paste these values into GitHub, screenshots, documentation, or Flutter source files.

## 6. Deploy the Supabase Edge Functions

From **Supabase → Edge Functions**, deploy the function code from these project files using the Dashboard editor (if available):

- `supabase/functions/create-invoice/index.ts` → function name: `create-invoice`
- `supabase/functions/xendit-webhook/index.ts` → function name: `xendit-webhook`

If the functions already exist, update their code rather than creating duplicates.

**Authentication:** In the previously discussed guest-checkout setup, JWT verification was disabled for these functions. Only use that configuration if the current function implementation explicitly supports it and performs its own appropriate checks. In particular, `create-invoice` must validate items, quantities, product prices, and order ownership or another abuse-prevention mechanism server-side. `xendit-webhook` must verify the Xendit callback token and correlate the event to an existing order before changing payment status.

## 7. Set up the Xendit webhook

In Xendit **Test Mode → Developers / Webhooks**, configure the invoice payment callback URL to:

```text
https://relwoizlzfccmrhxswyl.supabase.co/functions/v1/xendit-webhook
```

Only use this address if **`relwoizlzfccmrhxswyl` is your actual Supabase project reference**. If you use another project, replace the hostname accordingly. Enable and save the relevant invoice/payment-link event callback.

A sample webhook test may respond with HTTP `400` because its dummy `external_id` does not correspond to an actual order. A successful *real Test Mode checkout* is a better end-to-end check. Do not infer the cause of a `400` from the status alone; inspect Edge Function invocation logs, response details, and code.

## 8. Run on Android

Start an Android emulator through Android Studio, or connect a phone with USB debugging enabled. Then run:

```powershell
flutter devices
flutter run
```

Select a specific device if more than one is connected:

```powershell
flutter run -d DEVICE_ID
```

If the app requires `--dart-define` arguments, include them with your `flutter run` command using the exact identifiers expected by your project.

## 9. Build the release APK

From the project root:

```powershell
flutter clean
flutter pub get
flutter build apk --release
```

Successful builds normally generate:

```text
build\app\outputs\flutter-apk\app-release.apk
```

Check whether release signing, Android permissions, and payment return URLs are correctly configured before distributing the APK. If application values are provided through `--dart-define`, pass the same **public/client-safe** settings when building the release.

## 10. Test checkout and payment callbacks

1. Confirm an available product exists in Supabase `products`.
2. Launch the app and add the product to the cart.
3. Continue to checkout and select Xendit.
4. Open the hosted Xendit **Test Mode** checkout URL.
5. Complete a supported test payment.
6. In Supabase `orders`, confirm the matching order transitions from pending to the project's expected paid status, and that its `paid_at` timestamp is populated if used by the schema.
7. Verify that duplicate webhook deliveries do not double-charge or apply paid status twice.

Never mark an order paid merely because the app opened or returned from a checkout URL. The server must validate the payment notification or provider payment status.

## 11. Troubleshooting

### `No pubspec.yaml file found`

You are not in the Flutter project root. Run `Test-Path .\pubspec.yaml` and `cd` into the correct folder.

### YAML error: `Could not find expected ':'`

Check `pubspec.yaml` indentation and look for extra pasted text, Markdown fences, or missing colons. Run `flutter pub get` after correcting the YAML.

### `Unresolved reference 'Version'` / `Unresolved reference 'name'`

If the failure points to `C:\flutter\packages\flutter_tools\gradle\src\main\kotlin\dependency_version_checker.gradle.kts`, the failure is occurring in the Flutter Gradle build tooling. **Do not edit Flutter SDK source files or randomly change Kotlin/Gradle versions.** Collect version details:

```powershell
flutter --version
flutter doctor -v
java -version
Get-Content android\gradle\wrapper\gradle-wrapper.properties
Get-Content android\settings.gradle.kts
```

If `settings.gradle.kts` doesn't exist, try `Get-Content android\settings.gradle` instead. Check Gradle, Android Gradle Plugin, Kotlin, JDK, and Flutter compatibility. Project-level cache cleanup can be attempted:

```powershell
cd android
.\gradlew.bat --stop
cd ..
flutter clean
Remove-Item -Recurse -Force android\.gradle -ErrorAction SilentlyContinue
flutter pub get
flutter build apk --release
```

If the same error persists, review the version output and the exact affected lines before changing configuration. Updating `pubspec.yaml` alone will not fix this failure.

### Xendit webhook returns HTTP `400`

Check the webhook's response, Supabase Edge Function **Invocations**, callback token verification, matching `external_id` / invoice ID, and order record. Xendit's generic example payload may contain old timestamps and `IDR` currency; it is not an actual PHP test checkout from your app.

### Xendit payment succeeds but order stays pending

Verify webhook URL, event type, Test Mode credentials, signature/callback-token validation, order lookup, and database permissions. Review Edge Function logs and do not update payment status from the Flutter client as a workaround.

## 12. Security reminders

- Keep `XENDIT_SECRET_KEY`, `XENDIT_WEBHOOK_TOKEN`, and Supabase service-role keys on the server only.
- Never commit real secrets, `.env` files containing credentials, or private signing keys.
- Calculate payment amounts using trusted database product prices on the backend, not client-submitted totals.
- Validate webhooks before recording a successful payment.
- Use Test Mode until the full checkout flow and refund/cancellation cases are verified.

---

**Project:** EL-DRAGON  
**Stack:** Flutter / Dart / Supabase / Xendit  
**Guide:** Windows development, Android installation, and Xendit Test Mode setup

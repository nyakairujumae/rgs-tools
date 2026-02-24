# Codemagic: Supabase config for production builds

The app does **not** bundle a `.env` file (so CI build succeeds). Supabase URL and anon key must be provided at **build time** so the app can authenticate.

---

## Step 1: Environment variables (you did this)

In **Codemagic** → your app **rgs-tools** → **Application settings** (gear) → **Environment variables**:

- **Variable name:** `SUPABASE_URL`  
  **Variable value:** your Supabase project URL (e.g. `https://xxxx.supabase.co`)

- **Variable name:** `SUPABASE_ANON_KEY` (must be exactly this, not `SUPABASE_ANON_`)  
  **Variable value:** your Supabase anon/public key

Check **Secret** if you want them hidden in logs. Click **Add** for each.

---

## Step 2: Pass them into the Flutter build (required)

Codemagic does **not** inject env vars into the app automatically. You must pass them with **Build arguments**.

### In the workflow editor (UI)

1. Open your app → **Build** (left: Builds, then your workflow).
2. Scroll to the **Build** section (the block that runs the iOS build).
3. Expand it (click the row or the dropdown).
4. Find the field labeled **Build arguments** or **Additional build arguments** (same place you set Flutter version, build mode, etc.).
5. In that field, add exactly (on one line):

   ```
   --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
   ```

   Codemagic will replace `$SUPABASE_URL` and `$SUPABASE_ANON_KEY` with the values from Step 1 when the build runs.

6. Save and run a **new build**.

### If you don’t see “Build arguments”

Some workflows use a **custom script** for the build. In that case:

- Find the step that runs `flutter build ipa` (or `flutter build ios`).
- Change that line to:

  ```bash
  flutter build ipa --release \
    --dart-define=SUPABASE_URL=$SUPABASE_URL \
    --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
  ```

  (Same for `flutter build ios` if you use that.)

---

## Reference (from Codemagic docs)

- [Using environment variables with Flutter workflow editor](https://docs.codemagic.io/flutter-configuration/using-environment-variables/)
- [Building Flutter projects](https://docs.codemagic.io/flutter-configuration/flutter-projects) — “add additional build arguments” in the Build section.

Variables are referenced with `$VARIABLE_NAME` in scripts and build arguments. The app reads them via `String.fromEnvironment('SUPABASE_URL')` and `String.fromEnvironment('SUPABASE_ANON_KEY')`.

---

## Summary

| Step | Where | What |
|------|--------|------|
| 1 | Application settings → Environment variables | Add `SUPABASE_URL` and `SUPABASE_ANON_KEY` |
| 2 | Build section → **Build arguments** | Add `--dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY` |

Without Step 2, the app is built with empty Supabase config and login fails.

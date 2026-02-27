# .env, Firebase, APNs, and production builds

## What your app actually uses

| Config | Where it comes from | Does .env affect it? |
|--------|---------------------|----------------------|
| **Supabase** (URL, anon key) | `lib/config/supabase_config.dart` → reads `.env` or `--dart-define` | **Yes.** If .env is not bundled and you don’t pass `--dart-define`, auth fails. |
| **Firebase** (project, API key, app ID, etc.) | `lib/firebase_options.dart` (generated) + `GoogleService-Info.plist` / `google-services.json` | **No.** Firebase is initialized with `DefaultFirebaseOptions.currentPlatform` from `firebase_options.dart`. Those files are in the repo and are bundled. |
| **APNs** (Apple push) | Apple capability + key/cert in **Firebase Console** (and Apple Developer). The app only has the push capability. | **No.** The app does not read an APNs key from .env. FCM uses the key you uploaded in Firebase. |

So: **only Supabase** depends on .env or dart-define. Firebase and APNs keep working when .env is left out, because they use files already in the repo and server-side config.

---

## How others usually do it

1. **Secrets / API keys that must not be in the repo**  
   - Stored in CI (e.g. Codemagic) as **environment variables** or **secrets**.  
   - Passed into the build with `--dart-define=KEY=$KEY` so the app gets them at compile time.  
   - .env is **not** committed; CI doesn’t have it.

2. **Non-secret config (e.g. Supabase URL, anon key, Firebase options)**  
   - Often **in the repo**: e.g. `firebase_options.dart`, `GoogleService-Info.plist`, or constants in code.  
   - Supabase anon key is public by design; it’s normal to have it in the app.

3. **Local development**  
   - Developers use a **local .env** (gitignored) so they can override without changing the repo.  
   - Optional: you can still **bundle** .env for local runs only (e.g. with a flavor that includes the asset), but for CI you don’t bundle it so the build doesn’t depend on the file.

---

## Production build when you use Xcode

When you run “Build” or “Archive” in Xcode:

1. Xcode runs the Flutter build (or uses the built app).  
2. The **binary** only contains what was compiled and what’s in **assets**.  
3. A `.env` file on your Mac is **not** automatically in the app. It only gets in if:
   - you list it in `pubspec.yaml` under `assets` (we removed that so CI works), or  
   - you inject the values at **build time** (e.g. `--dart-define` in the script Xcode runs).

So for a **production build from Xcode** you have two options:

- **Option A – dart-define from Xcode**  
  In your scheme or the “Run Script” that runs Flutter, pass:

  ```bash
  flutter build ios \
    --dart-define=SUPABASE_URL=your_url \
    --dart-define=SUPABASE_ANON_KEY=your_anon_key
  ```

  (You can take the values from your local .env or from a secure place; don’t hardcode secrets in the script if others see it.)

- **Option B – Defaults in code**  
  In `supabase_config.dart`, if `String.fromEnvironment(...)` is empty, return a default URL and anon key (your real Supabase project). Then the app works even when no .env and no dart-define are used. The anon key is public; this is a common approach.

Firebase and APNs don’t need .env for production; they’re already covered by `firebase_options.dart` and your plist/json.

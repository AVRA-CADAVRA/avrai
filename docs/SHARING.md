# Shareable Branch

This branch is stripped of secrets, environment files, and IDE-specific config so it can be shared safely.

## What’s different from `main`

**Removed**
- `android/app/google-services.json` – add your own from [Firebase Console](https://console.firebase.google.com)
- `ios/Runner/GoogleService-Info.plist` – add your own from Firebase
- `lib/firebase_options.dart` – stub only; run `dart run flutterfire_cli:flutterfire configure` to generate a real one
- `.vscode/` – add your own if you use VS Code
- `.cursor/`, `.cursorrules*` – Cursor/IDE-specific; on `main` if you need them

**Neutralized (no real values)**
- `lib/supabase_config.dart` – `SUPABASE_URL` and `SUPABASE_ANON_KEY` default to `''`. Set via `--dart-define` or see `supabase_config.example`
- `examples/supabase/supabase_config.dart` – placeholder URL and anon key
- `scripts/create_storage_bucket.ts` – `SUPABASE_PROJECT_REF` falls back to `YOUR_SUPABASE_PROJECT_REF`; set `SUPABASE_PROJECT_REF` and `SUPABASE_ACCESS_TOKEN` in the environment

**Unchanged (already safe)**
- `lib/google_places_config.dart`, `lib/weather_config.dart` – use `--dart-define` or env; default to `''`

**Ignored**
- `models/` – in `.gitignore`; use `scripts/download_*.py` / `run_llama_to_coreml.sh` and docs in `docs/macos_llm_integration/` to obtain models

## Before you run the app

1. **Supabase**  
   - Copy `supabase_config.example` to `lib/supabase_config.dart` and fill in URL + anon key, **or**  
   - Pass `--dart-define=SUPABASE_URL=...` and `--dart-define=SUPABASE_ANON_KEY=...` when building/running.

2. **Firebase**  
   - Run: `dart run flutterfire_cli:flutterfire configure` (generates `lib/firebase_options.dart`).  
   - Do **not** commit the generated `lib/firebase_options.dart` — it contains your keys; keep it local.  
   - Add `google-services.json` and `GoogleService-Info.plist` from the Firebase project into `android/app/` and `ios/Runner/`.

3. **Optional**  
   - Google Places: `--dart-define=GOOGLE_PLACES_API_KEY=...`  
   - OpenWeather: `--dart-define=OPENWEATHERMAP_API_KEY=...`  
   - For LLM/download scripts: create a `.env` with `HF_TOKEN=...` (HuggingFace).

## Clone this branch

```bash
git clone -b shareable https://github.com/AVRA-CADAVRA/avrai.git
cd avrai
```

Then follow “Before you run the app” above.

# Automated Setup Walkthrough

**Script:** `./scripts/macos_llm_operational_setup.sh`

Use this as your cheat sheet when running the automated setup.

---

## Before You Start

1. **Terminal:** Open Terminal in your project root (`/Users/reisgordon/AVRAI`).
2. **Supabase:** Project linked (`supabase link`). Have Dashboard open.
3. **Dart:** `dart` available (for key generation).
4. **Models (optional):** If you're **not** converting yourself, you'll need to download models later.

---

## Step-by-Step Prompts

### Step 0: Manifest Signing Key (do this first)

**Prompt:** `Have you already set LOCAL_LLM_MANIFEST_SIGNING_KEY_B64? (y=skip / n=generate and configure now):`

**Answer:** **`n`** (first time)

- Script runs `dart run scripts/security/generate_local_llm_manifest_keys.dart`.
- It prints JSON with:
  - `LOCAL_LLM_MANIFEST_SIGNING_KEY_B64` (secret → Supabase only)
  - `LOCAL_LLM_MANIFEST_PUBLIC_KEY_B64_V1` (public → app build define later)
- **You must:**
  1. Run:
     ```bash
     supabase secrets set LOCAL_LLM_MANIFEST_KEY_ID=v1
     supabase secrets set LOCAL_LLM_MANIFEST_SIGNING_KEY_B64=<paste value from script output>
     ```
  2. Store `LOCAL_LLM_MANIFEST_PUBLIC_KEY_B64_V1` for when you build the app with  
     `--dart-define=LOCAL_LLM_MANIFEST_PUBLIC_KEY_B64_V1=...`
  3. Press Enter when done.

If you’ve already configured the signing key, answer **`y`** to skip.

---

### Step 1: Prerequisites
**No prompt.** Script checks:
- Python 3 ✓
- pip ✓
- Supabase CLI ✓
- shasum ✓

---

### Step 2: Install Python Dependencies

**Prompt:** `Install Python dependencies? (y/n)`

**Answer:** **`y`**

- Installs: `coremltools`, `transformers`, `torch`, `huggingface-hub`
- Takes a few minutes.
- Only needed if you'll **convert models yourself**. If you're using pre-converted models, you can answer **`n`**.

---

### Step 3: Model Conversion

**Prompt:** `Proceed with model conversion? (y/n)`

**Answer:** **`n`** (recommended first time)

- Conversion takes **30–60 minutes** and needs **~20GB** and an **Apple Silicon Mac**.
- **Easier path:** Use pre-converted models from HuggingFace, then come back to hashes/upload/secrets.

If you **do** want to convert now (Apple Silicon, plenty of disk space and time), answer **`y`**.

---

### Step 4: Calculate SHA-256 Hashes

**No prompt.** Script looks for:
- `models/macos/llama-3.1-8b-instruct-coreml.zip`
- `models/macos/llama-3.1-8b-instruct.gguf` (optional)

- If **found:** Prints hashes and sizes. **Save these** for Supabase secrets.
- If **not found:** You’ll add them later once you have the model files.

---

### Step 5: Upload Models to Supabase Storage

**Prompt:** `Have you uploaded the models? (y/n)`

**First time:** **`n`**

Then:

1. Create the bucket (if not exists):
   ```bash
   supabase migration up
   ```
   Or run the SQL in `supabase/migrations/064_local_llm_models_bucket_v1.sql` in the Supabase SQL Editor.

2. Upload your model(s):
   - Supabase Dashboard → **Storage** → **local-llm-models**
   - Upload `llama-3.1-8b-instruct-coreml.zip` (and optionally the GGUF).

3. Copy the **public URL** for each uploaded file.

4. Re-run the script later, or proceed manually with **Step 6**.

---

### Step 6: Configure Supabase Secrets

**If the script has URLs/hashes** (from earlier steps), it will offer to set secrets. Otherwise it prints the commands for you to run.

Run these yourself (fill in the real values):

```bash
# CoreML (Apple Silicon)
supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_URL="https://[project-ref].supabase.co/storage/v1/object/public/local-llm-models/llama-3.1-8b-instruct-coreml.zip"
supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SHA256="[hash from Step 4]"
supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SIZE_BYTES="[size from Step 4]"
```

**Optional (Intel / GGUF):**
```bash
supabase secrets set LOCAL_LLM_MACOS_INTEL_GGUF_URL="..."
supabase secrets set LOCAL_LLM_MACOS_INTEL_GGUF_SHA256="..."
supabase secrets set LOCAL_LLM_MACOS_INTEL_GGUF_SIZE_BYTES="..."
```

---

### Step 7: Deploy Edge Function

**No prompt.** Script runs:

```bash
supabase functions deploy local-llm-manifest --no-verify-jwt
```

Ensure you’re **linked** to the right project (`supabase link` if needed).

---

### Step 8: Testing Instructions

**No prompt.** Script prints:
- How to test the manifest endpoint
- How to test in the app on macOS

Use those to verify everything works.

---

## Quick Reference: What to Answer

| Step | Prompt | Suggested answer |
|------|--------|-------------------|
| 0 | Already set signing key? (y=skip / n=generate) | `n` first time; `y` if done |
| 2 | Install Python dependencies? | `y` (or `n` if using pre-converted only) |
| 3 | Proceed with model conversion? | `n` (use pre-converted first) |
| 5 | Have you uploaded the models? | `n` first time; `y` after upload |

---

## After the Script

1. **If you skipped conversion:** Get a pre-converted CoreML model (e.g. from HuggingFace), put it in `models/macos/`, then run **Step 4** again (or use the hash script) to get SHA-256 and size.
2. **Upload** the model to `local-llm-models` and **configure secrets** as in Step 6.
3. **Deploy** the Edge Function (Step 7) if the script didn’t do it.
4. **Test** using the instructions from Step 8.

---

## Run the Script

```bash
cd /Users/reisgordon/AVRAI
./scripts/macos_llm_operational_setup.sh
```

Use the prompts and this walkthrough as you go. If something errors, check `OPERATIONAL_SETUP_GUIDE.md` for troubleshooting.

---

## Critical: Signing Key

The manifest endpoint returns `{"error":"Signing key not configured"}` until you:

1. Generate keys: `dart run scripts/security/generate_local_llm_manifest_keys.dart`
2. Set secrets:
   ```bash
   supabase secrets set LOCAL_LLM_MANIFEST_KEY_ID=v1
   supabase secrets set LOCAL_LLM_MANIFEST_SIGNING_KEY_B64=<value from step 1>
   ```
3. Use the **public** key when building the app:  
   `--dart-define=LOCAL_LLM_MANIFEST_PUBLIC_KEY_B64_V1=<public key from step 1>`

Step 0 in the script does (1) and reminds you of (2)–(3).

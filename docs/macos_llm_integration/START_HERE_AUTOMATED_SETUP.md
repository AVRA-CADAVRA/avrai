# Start Here: Automated Setup

**Goal:** Get the macOS LLM automated setup done step by step.

---

## 1. Run the script

In your project root:

```bash
cd /Users/reisgordon/AVRAI
./scripts/macos_llm_operational_setup.sh
```

---

## 2. Answer the prompts

Use this table as you go:

| When it asks… | Answer | Notes |
|---------------|--------|--------|
| **Step 0:** Already set signing key? (y=skip / n=generate) | **`n`** | First time only |
| **Step 2:** Install Python dependencies? | **`n`** | Skip unless you’ll convert models yourself |
| **Step 3:** Proceed with model conversion? | **`n`** | Use pre-converted models first |
| **Step 5:** Have you uploaded the models? | **`n`** | Say `y` only after you’ve uploaded |

---

## 3. Step 0: Signing key (required)

When you answer **`n`** to “Already set signing key?”, the script generates Ed25519 keys and prints JSON.

**Do this next:**

1. **Set Supabase secrets** (use the values from the script output):

   ```bash
   supabase secrets set LOCAL_LLM_MANIFEST_KEY_ID=v1
   supabase secrets set LOCAL_LLM_MANIFEST_SIGNING_KEY_B64=<paste LOCAL_LLM_MANIFEST_SIGNING_KEY_B64 from output>
   ```

2. **Save** the `LOCAL_LLM_MANIFEST_PUBLIC_KEY_B64_V1` value. You’ll use it when building the app:
   ```bash
   flutter run -d macos --dart-define=LOCAL_LLM_MANIFEST_PUBLIC_KEY_B64_V1=<paste public key>
   ```

3. Press **Enter** in the script when you’re done.

**If you don’t do this:** The manifest endpoint will keep returning `{"error":"Signing key not configured"}`.

---

## 4. After the script finishes

The script will:

- ✓ Check prerequisites  
- ✓ Optionally install deps / convert models (you skipped)  
- ✓ Print upload and hash instructions  
- ✓ Deploy the `local-llm-manifest` Edge Function  

**You still need to:**

### A. Create the storage bucket

If the migration didn’t run (e.g. Docker not running):

1. Open **Supabase Dashboard** → **SQL Editor**.
2. Run the SQL in `supabase/migrations/064_local_llm_models_bucket_v1.sql`.
3. That creates the `local-llm-models` bucket and policies.

### B. Get a model

**Easiest:** Use a pre-converted CoreML model.

- e.g. HuggingFace: https://huggingface.co/models?search=llama-3.1-8b-coreml  
- Download the `.zip` (or package), then:

  ```bash
  mkdir -p models/macos
  # put the model zip in models/macos/
  ```

### C. Hashes and size

```bash
cd /Users/reisgordon/AVRAI
shasum -a 256 models/macos/llama-3.1-8b-instruct-coreml.zip
stat -f%z models/macos/llama-3.1-8b-instruct-coreml.zip
```

Save both values.

### D. Upload to Supabase Storage

1. **Storage** → **Buckets** → **local-llm-models**.
2. **Upload** your model zip.
3. Copy the **public URL** of the file.

### E. Set model-related secrets

```bash
supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_URL="https://[project-ref].supabase.co/storage/v1/object/public/local-llm-models/llama-3.1-8b-instruct-coreml.zip"
supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SHA256="<hash from step C>"
supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SIZE_BYTES="<size from step C>"
```

### F. Test the manifest

```bash
curl -X POST "https://nfzlwgbvezwwrutqpedy.supabase.co/functions/v1/local-llm-manifest" \
  -H "Content-Type: application/json" \
  -d '{"platform": "macos", "tier": "llama8b"}'
```

You should get JSON with `payload_b64` and `sig_b64`, not `{"error":"Signing key not configured"}`.

### G. Test in the app

1. Build and run with the public key:
   ```bash
   flutter run -d macos --dart-define=LOCAL_LLM_MANIFEST_PUBLIC_KEY_B64_V1=<your public key>
   ```
2. **Settings** → **On-Device AI** → turn **Offline LLM** on.
3. Confirm the model downloads and activates, then try AI chat.

---

## 5. Quick checklist

- [ ] Run `./scripts/macos_llm_operational_setup.sh`
- [ ] Step 0: Generate keys, set `LOCAL_LLM_MANIFEST_SIGNING_KEY_B64` and `KEY_ID`
- [ ] Save `LOCAL_LLM_MANIFEST_PUBLIC_KEY_B64_V1` for app builds
- [ ] Create `local-llm-models` bucket (migration or SQL)
- [ ] Get model (e.g. pre-converted CoreML), put in `models/macos/`
- [ ] Compute SHA-256 and size, upload to Storage, set macOS CoreML secrets
- [ ] Test manifest with `curl`
- [ ] Run app with `--dart-define=...`, enable Offline LLM, test chat

---

## 6. Where to look next

- **Full walkthrough:** [AUTOMATED_SETUP_WALKTHROUGH.md](./AUTOMATED_SETUP_WALKTHROUGH.md)  
- **Troubleshooting:** [OPERATIONAL_SETUP_GUIDE.md](./OPERATIONAL_SETUP_GUIDE.md)  
- **Security:** [SECURE_MODEL_HOSTING_GUIDE.md](./SECURE_MODEL_HOSTING_GUIDE.md)

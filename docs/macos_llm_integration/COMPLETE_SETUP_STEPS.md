# Complete macOS LLM Setup - Step-by-Step Guide

**Follow these steps in order to download, configure, and test the CoreML model.**

---

## ✅ Prerequisites (Already Done)

- [x] Storage bucket `local-llm-models` created
- [x] Edge function `local-llm-manifest` deployed
- [x] Signing keys configured
- [x] HuggingFace token saved to `.env`

---

## Step 1: Download the Pre-Converted CoreML Model

**Model:** `andmev/Llama-3.1-8B-Instruct-CoreML`  
**File:** `llama_3.1_coreml.mlpackage` (~4.5 GB)

### Option A: Manual Download (Recommended - Most Reliable)

1. **Open in browser:**
   ```
   https://huggingface.co/andmev/Llama-3.1-8B-Instruct-CoreML/tree/main
   ```

2. **Download the model:**
   - Click on `llama_3.1_coreml.mlpackage`
   - Click the **download button** (down arrow icon)
   - Save to: `/Users/reisgordon/AVRAI/models/macos/`
   - Wait for download to complete (~4.5 GB, may take 10-30 minutes)

3. **Verify download:**
   ```bash
   cd /Users/reisgordon/AVRAI/models/macos
   ls -lh llama_3.1_coreml.mlpackage
   # Should show ~4.5 GB file
   ```

### Option B: Using Python Script (If huggingface-hub is installed)

```bash
cd /Users/reisgordon/AVRAI
python3 scripts/download_coreml_model.py
```

**Note:** This requires `huggingface-hub` installed. If it fails, use Option A.

---

## Step 2: Package Model as ZIP

The model needs to be packaged as a ZIP file for Supabase upload.

```bash
cd /Users/reisgordon/AVRAI/models/macos

# Package the model directory as ZIP
zip -r llama-3.1-8b-instruct-coreml.zip llama_3.1_coreml.mlpackage

# Verify ZIP was created
ls -lh llama-3.1-8b-instruct-coreml.zip
# Should show ~4.5 GB ZIP file
```

**Expected output:**
- File: `llama-3.1-8b-instruct-coreml.zip`
- Size: ~4.5 GB

---

## Step 3: Calculate SHA-256 Hash and File Size

These values are required for Supabase secrets (security verification).

```bash
cd /Users/reisgordon/AVRAI/models/macos

# Calculate SHA-256 hash
shasum -a 256 llama-3.1-8b-instruct-coreml.zip

# Get file size in bytes
stat -f%z llama-3.1-8b-instruct-coreml.zip
```

**Save both values:**
- **Hash:** 64-character hex string (e.g., `a1b2c3d4...`)
- **Size:** Number in bytes (e.g., `4852345678`)

**Example output:**
```
a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456  llama-3.1-8b-instruct-coreml.zip
4852345678
```

---

## Step 4: Upload to Supabase Storage

1. **Open Supabase Dashboard:**
   ```
   https://supabase.com/dashboard/project/nfzlwgbvezwwrutqpedy/storage/buckets/local-llm-models
   ```

2. **Upload the ZIP file:**
   - Click **Upload** button
   - Select: `/Users/reisgordon/AVRAI/models/macos/llama-3.1-8b-instruct-coreml.zip`
   - Wait for upload to complete (may take 5-15 minutes for 4.5 GB)

3. **Get the public URL:**
   - After upload, click on the file name
   - Copy the **public URL** (format: `https://nfzlwgbvezwwrutqpedy.supabase.co/storage/v1/object/public/local-llm-models/llama-3.1-8b-instruct-coreml.zip`)
   - **Save this URL** - you'll need it in the next step

---

## Step 5: Configure Supabase Secrets

Set the three secrets required for the manifest endpoint:

```bash
cd /Users/reisgordon/AVRAI

# Replace <URL> with the public URL from Step 4
# Replace <HASH> with the SHA-256 hash from Step 3
# Replace <SIZE> with the file size from Step 3

supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_URL="https://nfzlwgbvezwwrutqpedy.supabase.co/storage/v1/object/public/local-llm-models/llama-3.1-8b-instruct-coreml.zip"

supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SHA256="<paste hash from Step 3>"

supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SIZE_BYTES="<paste size from Step 3>"
```

**Example (with real values):**
```bash
supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_URL="https://nfzlwgbvezwwrutqpedy.supabase.co/storage/v1/object/public/local-llm-models/llama-3.1-8b-instruct-coreml.zip"

supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SHA256="a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456"

supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SIZE_BYTES="4852345678"
```

**Verify secrets are set:**
```bash
# Check that secrets were set (won't show values, just confirms they exist)
supabase secrets list | grep LOCAL_LLM_MACOS
```

---

## Step 6: Test the Manifest Endpoint

Verify the manifest endpoint returns your model:

```bash
curl -X POST "https://nfzlwgbvezwwrutqpedy.supabase.co/functions/v1/local-llm-manifest" \
  -H "Content-Type: application/json" \
  -d '{"platform": "macos", "tier": "llama8b"}' | python3 -m json.tool
```

**Expected response:**
- Should contain `payload_b64` and `sig_b64`
- The payload should include your model in the `artifacts` array
- Should show `platform: "macos_coreml_zip"` with your URL, hash, and size

**If you see an empty `artifacts: []` array:**
- Check that all three secrets are set correctly
- Verify the URL is accessible (try opening it in a browser)
- Check Edge Function logs in Supabase Dashboard

---

## Step 7: Test in macOS App

1. **Build the app with the public key:**
   ```bash
   cd /Users/reisgordon/AVRAI
   flutter run -d macos --dart-define=LOCAL_LLM_MANIFEST_PUBLIC_KEY_B64_V1=HULfUDT5xMorF+UT8kawyNx+CYKbrP22C8MTwhv5Nas=
   ```

2. **Enable offline LLM:**
   - Launch the app
   - Go to **Settings** → **On-Device AI**
   - Toggle **Offline LLM** to **ON**

3. **Verify download:**
   - The app should automatically start downloading the model
   - Check download progress in the UI
   - Wait for download to complete (~4.5 GB)

4. **Test AI chat:**
   - Use the AI chat feature
   - Verify responses are generated locally
   - Check logs for any errors

---

## Step 8: Verify Model Activation

Check that the model is loaded and working:

1. **Check app logs:**
   - Look for "Model downloaded successfully"
   - Look for "Model activated" or "Model loaded"
   - Verify no error messages

2. **Test offline mode:**
   - Disable Wi-Fi/network
   - Try AI chat - should still work (using local model)
   - Re-enable network

3. **Check model location:**
   ```bash
   # Model should be downloaded to app's local storage
   # Location varies by app, but typically in:
   # ~/Library/Application Support/[app-name]/models/
   ```

---

## Troubleshooting

### Model download fails
- Check Supabase Storage bucket permissions
- Verify public URL is accessible
- Check file size matches (not corrupted)

### Manifest endpoint returns empty artifacts
- Verify all three secrets are set: URL, SHA256, SIZE_BYTES
- Check secret names are exact (case-sensitive)
- Verify Edge Function is deployed

### Model doesn't load in app
- Check app logs for errors
- Verify public key is set in build (`--dart-define`)
- Check model file format (should be `.mlpackage` inside ZIP)
- Verify macOS version supports CoreML (macOS 12+)

### Hash verification fails
- Re-calculate hash: `shasum -a 256 llama-3.1-8b-instruct-coreml.zip`
- Update secret: `supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SHA256="<new_hash>"`

---

## Quick Reference Checklist

- [ ] Step 1: Download model from HuggingFace
- [ ] Step 2: Package as ZIP
- [ ] Step 3: Calculate hash and size
- [ ] Step 4: Upload to Supabase Storage
- [ ] Step 5: Set three Supabase secrets (URL, SHA256, SIZE_BYTES)
- [ ] Step 6: Test manifest endpoint
- [ ] Step 7: Build app with public key and test download
- [ ] Step 8: Verify model loads and works

---

## Next Steps After Setup

Once everything is working:
- Monitor download logs for errors
- Test with different prompts
- Verify performance is acceptable
- Consider adding Intel Mac support (GGUF) if needed

---

## Support

- **Full documentation:** `docs/macos_llm_integration/`
- **Setup guide:** `docs/macos_llm_integration/BUCKET_AND_MODELS_SETUP.md`
- **Troubleshooting:** Check Edge Function logs in Supabase Dashboard

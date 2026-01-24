# macOS LLM Operational Setup Guide

**Complete step-by-step guide for preparing, uploading, and configuring models**

## Quick Start

Run the automated setup script:
```bash
./scripts/macos_llm_operational_setup.sh
```

Or follow the manual steps below.

---

## Step 1: Prepare Models

### Option A: Convert Models Yourself (Apple Silicon Mac Required)

**Requirements:**
- Apple Silicon Mac (M1/M2/M3)
- ~20GB free disk space
- Python 3.8+
- 30-60 minutes

**Install dependencies:**
```bash
pip3 install coremltools transformers torch huggingface-hub
```

**Convert to CoreML:**
```python
# convert_to_coreml.py
import coremltools as ct
from transformers import AutoTokenizer, AutoModelForCausalLM
import torch

model_name = "meta-llama/Llama-3.1-8B-Instruct"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForCausalLM.from_pretrained(
    model_name,
    torch_dtype=torch.float16,
    device_map="auto"
)

mlmodel = ct.convert(
    model,
    inputs=[ct.TensorType(name="input_ids", shape=(1, ct.RangeDim(1, 4096)))],
    compute_units=ct.ComputeUnit.ALL,
)

mlmodel.save("llama-3.1-8b-instruct.mlpackage")
```

**Package as ZIP:**
```bash
zip -r llama-3.1-8b-instruct-coreml.zip llama-3.1-8b-instruct.mlpackage
```

### Option B: Use Pre-Converted Models (Recommended)

**Download CoreML models:**
- HuggingFace: https://huggingface.co/models?search=llama-3.1-8b-coreml
- Look for `.mlpackage` or `.mlmodelc` formats

**Download GGUF models (Intel):**
- HuggingFace: https://huggingface.co/models?search=llama-3.1-8b-gguf
- Recommended quantization: Q4_0 or Q4_K_M
- Direct download: `wget https://huggingface.co/.../model.gguf`

### Option C: Use Cloud Conversion Services

- **Replicate.com**: Model conversion API
- **HuggingFace Spaces**: Community conversions
- **Apple Developer Forums**: Pre-converted models

---

## Step 2: Calculate SHA-256 Hashes

**CoreML model:**
```bash
shasum -a 256 llama-3.1-8b-instruct-coreml.zip
stat -f%z llama-3.1-8b-instruct-coreml.zip
```

**GGUF model:**
```bash
shasum -a 256 llama-3.1-8b-instruct.gguf
stat -f%z llama-3.1-8b-instruct.gguf
```

**Save the values:**
- Hash (SHA-256): 64-character hex string
- Size: File size in bytes

---

## Step 3: Create Storage Bucket

### Option A: Using Supabase CLI

```bash
# Run migration
supabase migration up

# Or apply manually
supabase db push
```

### Option B: Manual Setup (Supabase Dashboard)

1. Go to: **SQL Editor** in Supabase Dashboard
2. Run the migration SQL:
   ```sql
   -- See: supabase/migrations/064_local_llm_models_bucket_v1.sql
   ```
3. Or create bucket manually:
   - Go to **Storage** → **Buckets**
   - Click **New Bucket**
   - Name: `local-llm-models`
   - Public: **Yes** (read access)
   - File size limit: Set appropriate limit (e.g., 20GB)

**Security Note:** Public read access is safe because:
- SHA-256 verification prevents tampering
- Signed manifests ensure authenticity
- Uploads restricted to service role

---

## Step 4: Upload Models

### Via Supabase Dashboard

1. Go to: **Storage** → **Buckets** → **local-llm-models**
2. Click **Upload**
3. Upload files:
   - `llama-3.1-8b-instruct-coreml.zip`
   - `llama-3.1-8b-instruct.gguf` (optional, for Intel)
4. Wait for upload to complete
5. **Copy public URLs** for each file:
   ```
   https://[project-ref].supabase.co/storage/v1/object/public/local-llm-models/llama-3.1-8b-instruct-coreml.zip
   ```

### Via Supabase CLI

```bash
# Upload CoreML
supabase storage upload local-llm-models \
  llama-3.1-8b-instruct-coreml.zip \
  --file ./llama-3.1-8b-instruct-coreml.zip

# Upload GGUF (optional)
supabase storage upload local-llm-models \
  llama-3.1-8b-instruct.gguf \
  --file ./llama-3.1-8b-instruct.gguf
```

---

## Step 5: Configure Supabase Secrets

### Option A: Using Supabase CLI

```bash
# CoreML (Apple Silicon)
supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_URL="https://[project-ref].supabase.co/storage/v1/object/public/local-llm-models/llama-3.1-8b-instruct-coreml.zip"
supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SHA256="[hash from step 2]"
supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SIZE_BYTES="[size from step 2]"

# GGUF (Intel - optional)
supabase secrets set LOCAL_LLM_MACOS_INTEL_GGUF_URL="https://[project-ref].supabase.co/storage/v1/object/public/local-llm-models/llama-3.1-8b-instruct.gguf"
supabase secrets set LOCAL_LLM_MACOS_INTEL_GGUF_SHA256="[hash from step 2]"
supabase secrets set LOCAL_LLM_MACOS_INTEL_GGUF_SIZE_BYTES="[size from step 2]"
```

### Option B: Via Supabase Dashboard

1. Go to: **Project Settings** → **Edge Functions** → **Secrets**
2. Add each secret:
   - `LOCAL_LLM_MACOS_COREML_ZIP_URL`
   - `LOCAL_LLM_MACOS_COREML_ZIP_SHA256`
   - `LOCAL_LLM_MACOS_COREML_ZIP_SIZE_BYTES`
   - (Optional) `LOCAL_LLM_MACOS_INTEL_GGUF_URL`
   - (Optional) `LOCAL_LLM_MACOS_INTEL_GGUF_SHA256`
   - (Optional) `LOCAL_LLM_MACOS_INTEL_GGUF_SIZE_BYTES`

### Verify Secrets

```bash
# List all secrets (CLI)
supabase secrets list

# Or check in Dashboard: Project Settings → Edge Functions → Secrets
```

---

## Step 6: Deploy Edge Function

```bash
supabase functions deploy local-llm-manifest --no-verify-jwt
```

**Verify deployment:**
- Check Supabase Dashboard → Edge Functions
- Function should show as "Active"

---

## Step 7: Test Setup

### Test 1: Manifest Endpoint

```bash
curl -X POST https://[project-ref].supabase.co/functions/v1/local-llm-manifest \
  -H "Content-Type: application/json" \
  -d '{
    "platform": "macos",
    "tier": "llama8b"
  }'
```

**Expected response:**
```json
{
  "key_id": "v1",
  "payload_b64": "...",
  "sig_b64": "..."
}
```

### Test 2: Verify Manifest Content

The payload should contain:
- `model_id`: "llama3_1_8b_instruct"
- `artifacts`: Array with macOS artifacts
- Each artifact should have: `url`, `sha256`, `size_bytes`

### Test 3: Test in App (Apple Silicon Mac)

1. **Launch app**
2. **Go to Settings** → **On-Device AI**
3. **Enable "Offline LLM"**
4. **Verify:**
   - Download starts automatically
   - Progress indicator shows
   - Model activates after download
   - Status shows "Installed"

### Test 4: Test Model Inference

1. **Use AI chat feature**
2. **Send a message**
3. **Verify:**
   - Response is generated
   - No errors in logs
   - Response quality is acceptable

### Test 5: Test Fallback

1. **Disable offline LLM** in settings
2. **Use AI chat**
3. **Verify:** Cloud backend is used (check logs)

### Test 6: Test on Intel Mac (if GGUF configured)

1. **Same steps as Test 3**
2. **Verify:** GGUF model is selected (check logs)
3. **Verify:** Model loads and works

---

## Troubleshooting

### Manifest Returns Empty Artifacts

**Problem:** Manifest doesn't include macOS artifacts

**Solution:**
1. Check Supabase secrets are set correctly
2. Verify secret names match exactly
3. Check Edge Function logs for errors
4. Verify platform parameter is "macos"

### Download Fails

**Problem:** Model download fails

**Solution:**
1. Check storage bucket exists and is public
2. Verify file URLs are correct
3. Check file size matches expected
4. Verify network connectivity
5. Check Supabase Storage quota

### SHA-256 Verification Fails

**Problem:** Downloaded file hash doesn't match

**Solution:**
1. Re-calculate hash of uploaded file
2. Verify hash in Supabase secrets matches
3. Re-upload file if hash is wrong
4. Check for corruption during upload

### Model Doesn't Load

**Problem:** Model loads but doesn't generate

**Solution:**
1. Check CoreML model format is correct
2. Verify tokenizer files are included
3. Check model directory structure
4. Review native logs for errors
5. Verify model is compatible with CoreML version

### Edge Function Errors

**Problem:** Edge Function returns errors

**Solution:**
1. Check Edge Function logs in Dashboard
2. Verify all secrets are set
3. Check function code for errors
4. Verify function is deployed correctly

---

## Verification Checklist

- [ ] Models converted/prepared
- [ ] SHA-256 hashes calculated
- [ ] Storage bucket created
- [ ] Models uploaded to storage
- [ ] Public URLs obtained
- [ ] Supabase secrets configured
- [ ] Edge Function deployed
- [ ] Manifest endpoint tested
- [ ] App download tested (Apple Silicon)
- [ ] App download tested (Intel, if applicable)
- [ ] Model inference tested
- [ ] Fallback to cloud tested
- [ ] Logs reviewed for errors

---

## Next Steps After Setup

1. **Monitor Downloads:**
   - Check Supabase Storage usage
   - Monitor bandwidth costs
   - Track download success rate

2. **Optimize:**
   - Consider CDN if costs are high
   - Monitor download speeds
   - Optimize model sizes if needed

3. **Maintain:**
   - Update models periodically
   - Rotate signing keys as needed
   - Monitor for security issues

---

## Support Resources

- **Security Guide:** [SECURE_MODEL_HOSTING_GUIDE.md](./SECURE_MODEL_HOSTING_GUIDE.md)
- **Model Hosting:** [MODEL_HOSTING_GUIDE.md](./MODEL_HOSTING_GUIDE.md)
- **Quick Reference:** [SECURITY_QUICK_REFERENCE.md](./SECURITY_QUICK_REFERENCE.md)
- **Setup Script:** `scripts/macos_llm_operational_setup.sh`

---

## Common Issues & Solutions

### "Model not found" Error

**Cause:** Model directory structure incorrect

**Solution:**
- Verify `.mlmodelc` directory exists in model pack
- Check model directory path is correct
- Ensure model files are extracted properly

### "Tokenizer not available" Error

**Cause:** Tokenizer files missing from model directory

**Solution:**
- Include `tokenizer.json` or `tokenizer.model` in model pack
- Verify tokenizer files are in correct location
- Check file permissions

### "Generation failed" Error

**Cause:** CoreML model incompatible or corrupted

**Solution:**
- Verify model conversion was successful
- Check CoreML model version compatibility
- Re-convert model if needed
- Check model input/output shapes

### Slow Downloads

**Cause:** Large file size or slow connection

**Solution:**
- Use CDN for better performance
- Consider smaller quantized models
- Implement progressive download
- Cache models locally

---

**Ready to proceed?** Run the setup script or follow the steps above!

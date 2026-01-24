# macOS LLM Model Hosting Guide

This guide covers the complete process of preparing, hosting, and configuring macOS LLM models for the AVRAI app.

## Overview

macOS supports two model formats:
- **CoreML** (`.mlmodelc`): Primary format for Apple Silicon Macs
- **GGUF** (`.gguf`): Fallback format for Intel Macs

## Step 1: Model Conversion

### CoreML Conversion (Apple Silicon)

1. **Install dependencies:**
   ```bash
   pip3 install coremltools transformers torch
   ```

2. **Download Llama 3.1 8B model:**
   ```bash
   # Using HuggingFace CLI
   huggingface-cli download meta-llama/Llama-3.1-8B-Instruct
   ```

3. **Convert to CoreML:**
   ```python
   import coremltools as ct
   from transformers import AutoTokenizer, AutoModelForCausalLM
   
   # Load model
   model = AutoModelForCausalLM.from_pretrained("meta-llama/Llama-3.1-8B-Instruct")
   tokenizer = AutoTokenizer.from_pretrained("meta-llama/Llama-3.1-8B-Instruct")
   
   # Convert to CoreML
   mlmodel = ct.convert(
       model,
       inputs=[ct.TensorType(name="input_ids", shape=(1, ct.RangeDim(1, 4096)))],
       compute_units=ct.ComputeUnit.ALL,
   )
   
   # Save
   mlmodel.save("llama-3.1-8b-instruct.mlpackage")
   ```

4. **Package as ZIP:**
   ```bash
   zip -r llama-3.1-8b-instruct-coreml.zip llama-3.1-8b-instruct.mlpackage
   ```

### GGUF Conversion (Intel)

1. **Download GGUF model:**
   ```bash
   # From HuggingFace
   wget https://huggingface.co/.../llama-3.1-8b-instruct-q4_0.gguf
   ```

   Or convert using `llama.cpp`:
   ```bash
   ./llama.cpp/convert.py meta-llama/Llama-3.1-8B-Instruct \
     --outfile llama-3.1-8b-instruct.gguf \
     --outtype q4_0
   ```

## Step 2: Calculate Hashes

```bash
# CoreML model
shasum -a 256 llama-3.1-8b-instruct-coreml.zip
stat -f%z llama-3.1-8b-instruct-coreml.zip

# GGUF model
shasum -a 256 llama-3.1-8b-instruct.gguf
stat -f%z llama-3.1-8b-instruct.gguf
```

## Step 3: Upload to Storage

### Option A: Supabase Storage (Recommended)

**Security:** See [SECURE_MODEL_HOSTING_GUIDE.md](./SECURE_MODEL_HOSTING_GUIDE.md) for detailed security analysis.

1. **Run migration to create bucket:**
   ```bash
   # Migration file: supabase/migrations/064_local_llm_models_bucket_v1.sql
   supabase migration up
   ```
   
   Or manually in SQL Editor:
   ```sql
   -- See supabase/migrations/064_local_llm_models_bucket_v1.sql
   ```

2. **Upload via Supabase Dashboard:**
   - Go to Storage → local-llm-models
   - Upload `llama-3.1-8b-instruct-coreml.zip`
   - Upload `llama-3.1-8b-instruct.gguf` (optional)
   - Files are automatically publicly readable (secure: verified via SHA-256)

3. **Get public URLs:**
   ```
   https://[project-ref].supabase.co/storage/v1/object/public/local-llm-models/llama-3.1-8b-instruct-coreml.zip
   ```

**Security Notes:**
- ✅ Public read access is **safe** because:
  - SHA-256 verification prevents tampering
  - Signed manifests ensure authenticity
  - Models contain no sensitive data
  - Uploads restricted to service role
- See [SECURE_MODEL_HOSTING_GUIDE.md](./SECURE_MODEL_HOSTING_GUIDE.md) for full security analysis

### Option B: External CDN (For Scale)

**When to use:** High download volume (>10k/month) or performance requirements.

**Recommended:** Cloudflare R2 or AWS S3 + CloudFront

**Security:** Same security model applies (SHA-256 + signed manifests)

See [SECURE_MODEL_HOSTING_GUIDE.md](./SECURE_MODEL_HOSTING_GUIDE.md) for CDN setup details.

## Step 4: Configure Supabase Secrets

```bash
# CoreML (Apple Silicon)
supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_URL="https://..."
supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SHA256="[hash from step 2]"
supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SIZE_BYTES="[size from step 2]"

# GGUF (Intel - optional)
supabase secrets set LOCAL_LLM_MACOS_INTEL_GGUF_URL="https://..."
supabase secrets set LOCAL_LLM_MACOS_INTEL_GGUF_SHA256="[hash from step 2]"
supabase secrets set LOCAL_LLM_MACOS_INTEL_GGUF_SIZE_BYTES="[size from step 2]"
```

## Step 5: Deploy Edge Function

```bash
supabase functions deploy local-llm-manifest --no-verify-jwt
```

## Step 6: Verify

1. **Test manifest endpoint:**
   ```bash
   curl -X POST https://[project-ref].supabase.co/functions/v1/local-llm-manifest \
     -H "Content-Type: application/json" \
     -d '{"platform": "macos", "tier": "llama8b"}'
   ```

2. **Verify in app:**
   - Launch app on macOS
   - Enable offline LLM in settings
   - Check that model download initiates
   - Verify model activates correctly

## Troubleshooting

### Model too large
- Use quantized models (Q4_0, Q4_K_M)
- Consider 3B model instead of 8B for bundled version

### Conversion fails
- Ensure you're on Apple Silicon Mac
- Check model format compatibility
- Verify CoreML tools version

### Download fails
- Check Supabase Storage permissions
- Verify URLs are publicly accessible
- Check network connectivity

### Model doesn't load
- Verify model format matches expected structure
- Check tokenizer files are included
- Ensure model directory structure is correct

## Bundled Model Setup

For the lightweight bundled model:

1. **Convert 3B model:**
   ```python
   # Use smaller 3B model for bundle
   model = AutoModelForCausalLM.from_pretrained("meta-llama/Llama-3.1-3B-Instruct")
   # ... convert as above
   ```

2. **Place in app bundle:**
   ```
   macos/Runner/Resources/Flutter Assets/models/llama-3.1-3b-instruct.mlmodelc/
   ```

3. **Update Xcode:**
   - Add model to Xcode project
   - Ensure it's included in app bundle
   - Verify file size is acceptable

## Model Updates

When updating models:

1. Upload new model files
2. Calculate new hashes
3. Update Supabase secrets
4. Deploy Edge Function
5. App will download new models on next check

## Security Notes

- Models are publicly accessible (required for download)
- SHA-256 verification ensures integrity
- Signed manifests prevent tampering
- Models are verified before activation

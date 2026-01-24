# macOS LLM Setup - Quick Start

**Fastest path to get models working**

## 🚀 Automated Setup (Recommended)

```bash
# Run the complete setup script
./scripts/macos_llm_operational_setup.sh
```

This script will guide you through all steps interactively.

## 📋 Manual Quick Steps

### 1. Get Models (Choose One)

**Option A: Pre-converted (Easiest)**
```bash
# Download from HuggingFace
# CoreML: https://huggingface.co/models?search=llama-3.1-8b-coreml
# GGUF: https://huggingface.co/models?search=llama-3.1-8b-gguf
```

**Option B: Convert Yourself**
```bash
pip3 install coremltools transformers torch
# See: docs/macos_llm_integration/OPERATIONAL_SETUP_GUIDE.md
```

### 2. Calculate Hashes

```bash
shasum -a 256 llama-3.1-8b-instruct-coreml.zip
stat -f%z llama-3.1-8b-instruct-coreml.zip
```

### 3. Create Bucket & Upload

**Via Dashboard:**
1. Supabase Dashboard → Storage
2. Create bucket: `local-llm-models` (public)
3. Upload model files
4. Copy public URLs

**Or run migration:**
```bash
supabase migration up
# Then upload via Dashboard
```

### 4. Configure Secrets

```bash
supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_URL="[URL from step 3]"
supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SHA256="[hash from step 2]"
supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SIZE_BYTES="[size from step 2]"
```

### 5. Deploy & Test

```bash
# Deploy Edge Function
supabase functions deploy local-llm-manifest --no-verify-jwt

# Test
curl -X POST https://[project].supabase.co/functions/v1/local-llm-manifest \
  -H "Content-Type: application/json" \
  -d '{"platform": "macos", "tier": "llama8b"}'
```

### 6. Test in App

1. Launch app on macOS
2. Settings → On-Device AI → Enable "Offline LLM"
3. Verify download starts
4. Test AI chat

## ✅ Verification

Run test script:
```bash
./scripts/test_macos_llm_setup.sh
```

## 📚 Full Documentation

- **Complete Guide:** [OPERATIONAL_SETUP_GUIDE.md](./OPERATIONAL_SETUP_GUIDE.md)
- **Security:** [SECURE_MODEL_HOSTING_GUIDE.md](./SECURE_MODEL_HOSTING_GUIDE.md)
- **Quick Ref:** [SECURITY_QUICK_REFERENCE.md](./SECURITY_QUICK_REFERENCE.md)

## 🆘 Troubleshooting

**Manifest returns empty?**
- Check secrets are set correctly
- Verify Edge Function is deployed

**Download fails?**
- Check bucket is public
- Verify URLs are correct
- Check file sizes match

**Model doesn't work?**
- Check CoreML model format
- Verify tokenizer files included
- Review native logs

See [OPERATIONAL_SETUP_GUIDE.md](./OPERATIONAL_SETUP_GUIDE.md) for detailed troubleshooting.

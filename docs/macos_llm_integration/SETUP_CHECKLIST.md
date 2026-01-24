# macOS LLM Setup Checklist

Use this checklist to track your progress through the operational setup.

## 📦 Model Preparation

### Option A: Convert Models
- [ ] Install Python dependencies (`pip3 install coremltools transformers torch`)
- [ ] Run conversion script: `python3 scripts/convert_llama_to_coreml.py`
- [ ] Wait for conversion to complete (~30-60 minutes)
- [ ] Package CoreML model as ZIP
- [ ] (Optional) Download/prepare GGUF model for Intel Macs

### Option B: Use Pre-Converted Models
- [ ] Download CoreML model from HuggingFace
- [ ] (Optional) Download GGUF model for Intel Macs
- [ ] Verify model files are complete

## 🔐 Hash Calculation

- [ ] Calculate SHA-256 hash for CoreML model
- [ ] Record file size for CoreML model
- [ ] (If applicable) Calculate SHA-256 hash for GGUF model
- [ ] (If applicable) Record file size for GGUF model
- [ ] Save all values for later use

## ☁️ Supabase Setup

### Storage Bucket
- [ ] Run migration: `supabase migration up`
- [ ] Or create bucket manually in Dashboard
- [ ] Verify bucket is public (read access)
- [ ] Verify RLS policies are set correctly

### Upload Models
- [ ] Upload CoreML model to `local-llm-models` bucket
- [ ] (If applicable) Upload GGUF model to bucket
- [ ] Copy public URLs for each file
- [ ] Verify files are accessible via public URLs

### Configure Secrets
- [ ] Set `LOCAL_LLM_MACOS_COREML_ZIP_URL`
- [ ] Set `LOCAL_LLM_MACOS_COREML_ZIP_SHA256`
- [ ] Set `LOCAL_LLM_MACOS_COREML_ZIP_SIZE_BYTES`
- [ ] (If applicable) Set `LOCAL_LLM_MACOS_INTEL_GGUF_URL`
- [ ] (If applicable) Set `LOCAL_LLM_MACOS_INTEL_GGUF_SHA256`
- [ ] (If applicable) Set `LOCAL_LLM_MACOS_INTEL_GGUF_SIZE_BYTES`
- [ ] Verify all secrets are set correctly

### Deploy Edge Function
- [ ] Deploy: `supabase functions deploy local-llm-manifest --no-verify-jwt`
- [ ] Verify function is active in Dashboard
- [ ] Check function logs for errors

## 🧪 Testing

### Manifest Endpoint
- [ ] Test manifest endpoint with curl
- [ ] Verify response contains `payload_b64` and `sig_b64`
- [ ] Verify payload contains macOS artifacts
- [ ] Check artifact URLs are correct

### App Testing (Apple Silicon)
- [ ] Launch app on Apple Silicon Mac
- [ ] Navigate to Settings → On-Device AI
- [ ] Enable "Offline LLM"
- [ ] Verify download starts automatically
- [ ] Monitor download progress
- [ ] Verify model activates after download
- [ ] Test AI chat functionality
- [ ] Verify responses are generated
- [ ] Check logs for errors

### App Testing (Intel - if applicable)
- [ ] Launch app on Intel Mac
- [ ] Enable "Offline LLM"
- [ ] Verify GGUF model is selected
- [ ] Verify download and activation
- [ ] Test AI chat functionality

### Fallback Testing
- [ ] Disable "Offline LLM" in settings
- [ ] Use AI chat
- [ ] Verify cloud backend is used
- [ ] Re-enable and verify local model works

## ✅ Final Verification

- [ ] All models uploaded and accessible
- [ ] All secrets configured correctly
- [ ] Edge Function deployed and working
- [ ] Manifest endpoint returns correct data
- [ ] App downloads models successfully
- [ ] Models activate correctly
- [ ] AI chat works with local models
- [ ] Fallback to cloud works
- [ ] No errors in logs
- [ ] Performance is acceptable

## 📊 Monitoring Setup

- [ ] Set up monitoring for download success rate
- [ ] Track storage bandwidth usage
- [ ] Monitor Edge Function errors
- [ ] Set up alerts for verification failures
- [ ] Track model activation success rate

## 🎉 Completion

Once all items are checked:
- [ ] Document any issues encountered
- [ ] Note any configuration differences
- [ ] Update team on setup completion
- [ ] Schedule regular model updates

---

## Quick Commands Reference

```bash
# Calculate hashes
shasum -a 256 model.zip
stat -f%z model.zip

# Set secrets
supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_URL="..."
supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SHA256="..."
supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SIZE_BYTES="..."

# Deploy function
supabase functions deploy local-llm-manifest --no-verify-jwt

# Test manifest
curl -X POST https://[project].supabase.co/functions/v1/local-llm-manifest \
  -H "Content-Type: application/json" \
  -d '{"platform": "macos", "tier": "llama8b"}'
```

---

**Need help?** See:
- [QUICK_START.md](./QUICK_START.md) - Fast setup
- [OPERATIONAL_SETUP_GUIDE.md](./OPERATIONAL_SETUP_GUIDE.md) - Detailed guide
- [SECURE_MODEL_HOSTING_GUIDE.md](./SECURE_MODEL_HOSTING_GUIDE.md) - Security details

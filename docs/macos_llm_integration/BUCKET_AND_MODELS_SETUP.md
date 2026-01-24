# Storage Bucket & Model Download Instructions

## ✅ Step 1: Create Storage Bucket

**Option A: Via Supabase Dashboard (Recommended)**

1. Go to: https://supabase.com/dashboard/project/nfzlwgbvezwwrutqpedy/editor
2. Click **SQL Editor** in the left sidebar
3. Paste this SQL and click **Run**:

```sql
-- Local LLM Models: Supabase Storage bucket (v1)
INSERT INTO storage.buckets (id, name, public)
VALUES ('local-llm-models', 'local-llm-models', true)
ON CONFLICT (id) DO NOTHING;

-- Public read access (models are verified via SHA-256, so public access is safe)
DROP POLICY IF EXISTS "Public read access for LLM models" ON storage.objects;
CREATE POLICY "Public read access for LLM models" ON storage.objects
  FOR SELECT
  USING (bucket_id = 'local-llm-models');

-- Service role can upload models (prevents unauthorized uploads)
DROP POLICY IF EXISTS "Service role can upload LLM models" ON storage.objects;
CREATE POLICY "Service role can upload LLM models" ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'local-llm-models'
    AND (SELECT auth.role()) = 'service_role'
  );

-- Service role can update models (for model updates/rollbacks)
DROP POLICY IF EXISTS "Service role can update LLM models" ON storage.objects;
CREATE POLICY "Service role can update LLM models" ON storage.objects
  FOR UPDATE
  USING (
    bucket_id = 'local-llm-models'
    AND (SELECT auth.role()) = 'service_role'
  )
  WITH CHECK (
    bucket_id = 'local-llm-models'
    AND (SELECT auth.role()) = 'service_role'
  );

-- Service role can delete models (for cleanup/rollbacks)
DROP POLICY IF EXISTS "Service role can delete LLM models" ON storage.objects;
CREATE POLICY "Service role can delete LLM models" ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'local-llm-models'
    AND (SELECT auth.role()) = 'service_role'
  );
```

4. Verify bucket was created:
   - Go to **Storage** → **Buckets**
   - You should see `local-llm-models` bucket

---

## 📦 Step 2: Download Models

### For Apple Silicon Macs (M1/M2/M3) - CoreML Format

**Recommended: Pre-converted CoreML models from HuggingFace**

1. **Search for models:**
   - https://huggingface.co/models?search=llama-3.1-8b-coreml
   - https://huggingface.co/models?search=llama-3.1-8b-instruct-coreml

2. **Specific models to check:**
   - `apple/coreml-llama-3.1-8b-instruct` (if available)
   - Community-converted models with `.mlpackage` or `.mlmodelc` format
   - Look for models tagged with `coreml` or `mlpackage`

3. **Download options:**
   ```bash
   # Option A: Using HuggingFace CLI
   pip3 install huggingface-hub
   huggingface-cli download apple/coreml-llama-3.1-8b-instruct --local-dir ./models/macos
   
   # Option B: Direct download from HuggingFace website
   # Go to model page → Files → Download .mlpackage or .zip file
   
   # Option C: Use wget/curl if direct download links are available
   ```

4. **Package as ZIP (if needed):**
   ```bash
   # If you have a .mlpackage directory
   cd models/macos
   zip -r llama-3.1-8b-instruct-coreml.zip llama-3.1-8b-instruct.mlpackage
   ```

### For Intel Macs (Optional) - GGUF Format

**Recommended: Pre-quantized GGUF models**

1. **Search for models:**
   - https://huggingface.co/models?search=llama-3.1-8b-gguf
   - https://huggingface.co/models?search=llama-3.1-8b-instruct-gguf

2. **Recommended quantizations:**
   - `Q4_0` - Good balance of size and quality (~4-5GB)
   - `Q4_K_M` - Better quality, slightly larger
   - `Q5_0` - Higher quality, larger file

3. **Download:**
   ```bash
   # Example (replace with actual model URL)
   wget https://huggingface.co/[model-repo]/resolve/main/llama-3.1-8b-instruct-q4_0.gguf
   ```

### Alternative: Convert Models Yourself (llama-to-coreml)

**Official guide:** [llama-to-coreml](https://github.com/andmev/llama-to-coreml) — converts Llama 3.x from HuggingFace to CoreML.

**Requirements:**
- Apple Silicon Mac (M1/M2/M3)
- macOS 15+ (Sequoia)
- Python 3.8+, PyTorch 2.0+
- ~20GB free disk space, 30–60 minutes

**Setup:**
```bash
# Clone the converter
git clone https://github.com/andmev/llama-to-coreml.git
cd llama-to-coreml
mise install   # or use your Python env
pip install -e .
pip install -r requirements.txt
```

**Convert Llama 3.1 8B (for AVRAI macOS):**
```bash
# From inside llama-to-coreml/
python scripts/convert_model.py \
  --model-path meta-llama/Llama-3.1-8B-Instruct \
  --output-path ../output/Llama-3.1-8B-Instruct.mlpackage \
  --token YOUR_HUGGINGFACE_TOKEN \
  --compile
```

Use `--token` for gated models (e.g. Meta Llama). Optional `--compile` produces `.mlmodelc`.

**Package for Supabase:**
```bash
cd output
zip -r llama-3.1-8b-instruct-coreml.zip Llama-3.1-8B-Instruct.mlpackage
# Move to AVRAI: mv llama-3.1-8b-instruct-coreml.zip /path/to/AVRAI/models/macos/
```

**Or use AVRAI wrapper (converts, ZIPs, outputs to `models/macos`):**
```bash
# Clone llama-to-coreml, install deps, then:
LLAMA_TO_COREML=/path/to/llama-to-coreml HF_TOKEN=your_token ./scripts/run_llama_to_coreml.sh
# 3B: MODEL=3B LLAMA_TO_COREML=... HF_TOKEN=... ./scripts/run_llama_to_coreml.sh
```

**Smaller/faster option (3B):**
```bash
python scripts/convert_model.py \
  --model-path meta-llama/Llama-3.2-3B-Instruct \
  --output-path output/Llama-3.2-3B-Instruct.mlpackage \
  --token YOUR_HUGGINGFACE_TOKEN \
  --compile
```

See [llama-to-coreml README](https://github.com/andmev/llama-to-coreml) for full details.  
Also: `docs/macos_llm_integration/MODEL_HOSTING_GUIDE.md` and `scripts/convert_llama_to_coreml.py` (in-repo fallback).

---

## 📋 Step 3: Calculate Hashes & Upload

After downloading your model:

1. **Calculate SHA-256 hash:**
   ```bash
   cd /Users/reisgordon/AVRAI
   shasum -a 256 models/macos/llama-3.1-8b-instruct-coreml.zip
   # Save this hash value
   ```

2. **Get file size:**
   ```bash
   stat -f%z models/macos/llama-3.1-8b-instruct-coreml.zip
   # Save this size value
   ```

3. **Upload to Supabase Storage:**
   - Go to: https://supabase.com/dashboard/project/nfzlwgbvezwwrutqpedy/storage/buckets/local-llm-models
   - Click **Upload**
   - Select your model ZIP file
   - Wait for upload to complete
   - Copy the **public URL** (format: `https://nfzlwgbvezwwrutqpedy.supabase.co/storage/v1/object/public/local-llm-models/[filename]`)

4. **Set Supabase secrets:**
   ```bash
   supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_URL="https://nfzlwgbvezwwrutqpedy.supabase.co/storage/v1/object/public/local-llm-models/llama-3.1-8b-instruct-coreml.zip"
   supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SHA256="[paste hash from step 1]"
   supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SIZE_BYTES="[paste size from step 2]"
   ```

---

## ✅ Step 4: Verify Setup

Test the manifest endpoint:

```bash
curl -X POST "https://nfzlwgbvezwwrutqpedy.supabase.co/functions/v1/local-llm-manifest" \
  -H "Content-Type: application/json" \
  -d '{"platform": "macos", "tier": "llama8b"}' | python3 -m json.tool
```

You should see a response with `payload_b64` and `sig_b64`, and the payload should contain your model in the `artifacts` array.

---

## 🔗 Useful Links

- **llama-to-coreml (conversion):** https://github.com/andmev/llama-to-coreml
- **Pre-converted 8B CoreML:** https://huggingface.co/andmev/Llama-3.1-8B-Instruct-CoreML
- **HuggingFace CoreML models:** https://huggingface.co/models?search=llama-3.1-8b-coreml
- **HuggingFace GGUF models:** https://huggingface.co/models?search=llama-3.1-8b-gguf
- **Supabase Storage:** https://supabase.com/dashboard/project/nfzlwgbvezwwrutqpedy/storage/buckets
- **Full setup:** `docs/macos_llm_integration/OPERATIONAL_SETUP_GUIDE.md`

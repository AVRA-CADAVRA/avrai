# Download CoreML Model Instructions

## Model: Llama-3.1-8B-Instruct-CoreML

**Source:** https://huggingface.co/andmev/Llama-3.1-8B-Instruct-CoreML  
**File:** `llama_3.1_coreml.mlpackage` (4.52 GB)

## Option 1: Manual Download (Recommended)

1. **Go to HuggingFace:**
   - https://huggingface.co/andmev/Llama-3.1-8B-Instruct-CoreML/tree/main

2. **Download the model:**
   - Click on `llama_3.1_coreml.mlpackage`
   - Click the download button (or use the download icon)
   - Save to: `/Users/reisgordon/AVRAI/models/macos/`

3. **Package as ZIP:**
   ```bash
   cd /Users/reisgordon/AVRAI/models/macos
   
   # If it's a directory
   zip -r llama-3.1-8b-instruct-coreml.zip llama_3.1_coreml.mlpackage
   
   # If it's a single file
   zip llama-3.1-8b-instruct-coreml.zip llama_3.1_coreml.mlpackage
   ```

4. **Calculate hash and size:**
   ```bash
   shasum -a 256 llama-3.1-8b-instruct-coreml.zip
   stat -f%z llama-3.1-8b-instruct-coreml.zip
   ```

## Option 2: Using Python Script

If you can install `huggingface-hub`:

```bash
# Install (may require --break-system-packages flag)
pip3 install --break-system-packages huggingface-hub
# or
python3 -m pip install --user huggingface-hub

# Run download script
python3 scripts/download_coreml_model.py
```

## Option 3: Convert with llama-to-coreml (GitHub guide)

**Official tool:** [llama-to-coreml](https://github.com/andmev/llama-to-coreml) — converts Llama 3.x from HuggingFace to CoreML.

```bash
git clone https://github.com/andmev/llama-to-coreml.git
cd llama-to-coreml
pip install -e . && pip install -r requirements.txt

# 8B (default)
python scripts/convert_model.py \
  --model-path meta-llama/Llama-3.1-8B-Instruct \
  --output-path output/Llama-3.1-8B-Instruct.mlpackage \
  --token YOUR_HUGGINGFACE_TOKEN \
  --compile
```

**AVRAI wrapper** (outputs to `models/macos`, then ZIPs):
```bash
LLAMA_TO_COREML=/path/to/llama-to-coreml HF_TOKEN=your_token ./scripts/run_llama_to_coreml.sh
```

See [BUCKET_AND_MODELS_SETUP.md](./BUCKET_AND_MODELS_SETUP.md) for full llama-to-coreml setup and 3B option.

## Option 4: Using Git LFS

If the model is stored with Git LFS:

```bash
cd /Users/reisgordon/AVRAI/models/macos
git lfs install
git clone https://huggingface.co/andmev/Llama-3.1-8B-Instruct-CoreML
cd Llama-3.1-8B-Instruct-CoreML
# The model file should be in the directory
```

## After Download

Once you have `llama-3.1-8b-instruct-coreml.zip`:

1. **Upload to Supabase Storage:**
   - Go to: https://supabase.com/dashboard/project/nfzlwgbvezwwrutqpedy/storage/buckets/local-llm-models
   - Click **Upload**
   - Select `llama-3.1-8b-instruct-coreml.zip`
   - Wait for upload to complete
   - Copy the public URL

2. **Set Supabase secrets:**
   ```bash
   supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_URL="<paste URL from step 1>"
   supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SHA256="<paste hash>"
   supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SIZE_BYTES="<paste size>"
   ```

3. **Test the manifest:**
   ```bash
   curl -X POST "https://nfzlwgbvezwwrutqpedy.supabase.co/functions/v1/local-llm-manifest" \
     -H "Content-Type: application/json" \
     -d '{"platform": "macos", "tier": "llama8b"}' | python3 -m json.tool
   ```

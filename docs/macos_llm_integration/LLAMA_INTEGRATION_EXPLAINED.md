# How Llama 3.1 8B Instruct Gets Into Your App - Complete Explanation

**This document explains the complete flow from HuggingFace to your app running Llama locally.**

---

## 🎯 The Big Picture

Your app uses a **"model pack" system** that:
1. Downloads models **after** app installation (keeps app size small)
2. Verifies integrity with SHA-256 hashes
3. Extracts and activates models automatically
4. Works offline once downloaded

**The flow:**
```
HuggingFace Model → Convert to CoreML → Package as ZIP → Upload to Supabase → 
App Downloads → Extracts → Activates → Runs Locally
```

---

## 📋 Two Paths to Get the Model

### **Path A: Convert Yourself (Recommended if you have Meta access)**

**What this does:** Downloads the raw Llama model from HuggingFace and converts it to CoreML format.

**Why:** You have Meta access, so you can download the official model and convert it yourself.

**Steps:**

1. **Set up the converter:**
   ```bash
   # Clone the llama-to-coreml converter
   git clone https://github.com/andmev/llama-to-coreml.git
   cd llama-to-coreml
   pip install -e . && pip install -r requirements.txt
   ```

2. **Run your conversion script:**
   ```bash
   cd /Users/reisgordon/AVRAI
   
   # Your script will:
   # - Download meta-llama/Llama-3.1-8B-Instruct from HuggingFace
   # - Convert it to CoreML format (.mlpackage)
   # - Package it as a ZIP file
   LLAMA_TO_COREML=/path/to/llama-to-coreml \
   HF_TOKEN=YOUR_HUGGINGFACE_TOKEN \
   ./scripts/run_llama_to_coreml.sh
   ```

3. **Output:**
   - Creates: `models/macos/Llama-3.1-8B-Instruct.mlpackage` (~4.5 GB)
   - Creates: `models/macos/llama-3.1-8b-instruct-coreml.zip` (~4.5 GB)

**Time:** 30-60 minutes (download + conversion)

---

### **Path B: Use Pre-Converted Model (Faster)**

**What this does:** Downloads an already-converted CoreML model from HuggingFace.

**Why:** Faster - no conversion needed. But you're trusting someone else's conversion.

**Steps:**

1. **Download pre-converted model:**
   ```bash
   # Option 1: Browser download
   # Go to: https://huggingface.co/andmev/Llama-3.1-8B-Instruct-CoreML/tree/main
   # Click download on llama_3.1_coreml.mlpackage
   # Save to: /Users/reisgordon/AVRAI/models/macos/
   
   # Option 2: Python script (if huggingface-hub installed)
   cd /Users/reisgordon/AVRAI
   python3 scripts/download_coreml_model.py
   ```

2. **Package as ZIP:**
   ```bash
   cd /Users/reisgordon/AVRAI/models/macos
   zip -r llama-3.1-8b-instruct-coreml.zip llama_3.1_coreml.mlpackage
   ```

**Time:** 10-30 minutes (download only)

---

## 📦 Step 2: Prepare for Supabase Upload

After you have the ZIP file, you need to:

1. **Calculate SHA-256 hash** (for security verification):
   ```bash
   cd /Users/reisgordon/AVRAI/models/macos
   shasum -a 256 llama-3.1-8b-instruct-coreml.zip
   # Output: a1b2c3d4e5f6... (64 character hex string)
   ```

2. **Get file size in bytes:**
   ```bash
   stat -f%z llama-3.1-8b-instruct-coreml.zip
   # Output: 4852345678 (number in bytes)
   ```

**Save both values** - you'll need them in the next step.

---

## ☁️ Step 3: Upload to Supabase Storage

Your app doesn't download directly from HuggingFace. Instead, it downloads from **your Supabase storage bucket** (for security and control).

1. **Open Supabase Dashboard:**
   ```
   https://supabase.com/dashboard/project/nfzlwgbvezwwrutqpedy/storage/buckets/local-llm-models
   ```

2. **Upload the ZIP file:**
   - Click **Upload** button
   - Select: `llama-3.1-8b-instruct-coreml.zip`
   - Wait for upload (5-15 minutes for 4.5 GB)

3. **Copy the public URL:**
   - After upload, click on the file
   - Copy the URL (format: `https://nfzlwgbvezwwrutqpedy.supabase.co/storage/v1/object/public/local-llm-models/llama-3.1-8b-instruct-coreml.zip`)

---

## 🔐 Step 4: Configure Supabase Secrets

Your app needs to know where to find the model. This is done via **Supabase secrets** (secure configuration).

```bash
cd /Users/reisgordon/AVRAI

# Set the three required secrets:
supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_URL="<paste URL from Step 3>"
supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SHA256="<paste hash from Step 2>"
supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SIZE_BYTES="<paste size from Step 2>"
```

**Example:**
```bash
supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_URL="https://nfzlwgbvezwwrutqpedy.supabase.co/storage/v1/object/public/local-llm-models/llama-3.1-8b-instruct-coreml.zip"

supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SHA256="a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456"

supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SIZE_BYTES="4852345678"
```

**Why three secrets?**
- **URL**: Where to download from
- **SHA256**: Verify file integrity (prevents corruption/tampering)
- **SIZE_BYTES**: Verify complete download

---

## 🔍 Step 5: Test the Manifest Endpoint

Your app discovers models through a **manifest endpoint** (Supabase Edge Function). This endpoint:
- Reads the secrets you just set
- Creates a signed manifest (JSON with model info)
- Returns it to your app

**Test it:**
```bash
curl -X POST "https://nfzlwgbvezwwrutqpedy.supabase.co/functions/v1/local-llm-manifest" \
  -H "Content-Type: application/json" \
  -d '{"platform": "macos", "tier": "llama8b"}' | python3 -m json.tool
```

**Expected response:**
```json
{
  "key_id": "v1",
  "payload_b64": "...",
  "sig_b64": "..."
}
```

The `payload_b64` contains (when decoded) a manifest with your model's URL, hash, and size.

**If you see empty `artifacts: []`:**
- Check that all three secrets are set
- Verify the URL is accessible (try opening in browser)
- Check Edge Function logs in Supabase Dashboard

---

## 📱 Step 6: How Your App Downloads the Model

When a user enables "Offline LLM" in your app:

1. **App calls manifest endpoint:**
   - `LLMService` → `LocalLlmModelPackManager` → fetches signed manifest
   - Verifies signature using public key (built into app)

2. **App downloads model:**
   - Reads manifest → finds macOS CoreML artifact
   - Downloads ZIP from Supabase Storage URL
   - Verifies SHA-256 hash matches
   - Verifies file size matches

3. **App extracts and activates:**
   - Extracts ZIP to app's local storage
   - Verifies `.mlpackage` structure
   - Marks model as "active"
   - Stores path in SharedPreferences

4. **App uses model:**
   - `LLMService` → `LocalPlatformLlmBackend` → method channel → Swift
   - Swift loads CoreML model from active directory
   - Runs inference locally

**Code flow:**
```
User toggles "Offline LLM" ON
  ↓
OnDeviceAiSettingsPage → LocalLlmModelPackManager.downloadAndActivateTrusted()
  ↓
Fetches signed manifest from Supabase Edge Function
  ↓
Verifies signature locally
  ↓
Downloads ZIP from Supabase Storage
  ↓
Verifies hash and size
  ↓
Extracts to ~/Library/Application Support/[app]/local_llm_packs/
  ↓
Activates model (stores path in SharedPreferences)
  ↓
LLMService uses LocalPlatformLlmBackend
  ↓
Swift loads CoreML model and runs inference
```

---

## 🔑 Key Concepts Explained

### **1. Why Not Bundle in App?**

- App would be 4.5+ GB (too large for App Store)
- Users who don't want offline AI shouldn't pay the download cost
- Allows updating models without app updates

### **2. Why Supabase Storage?**

- **Security**: You control access (not public HuggingFace)
- **Reliability**: Your own CDN, not dependent on HuggingFace
- **Verification**: SHA-256 hashes prevent tampering
- **Versioning**: Can host multiple model versions

### **3. Why Signed Manifests?**

- **Prevents tampering**: Attacker can't inject malicious model URLs
- **Trust**: App only trusts manifests signed with your private key
- **Public key**: Built into app at compile time (can't be changed)

### **4. What is a "Model Pack"?**

A "model pack" is:
- A ZIP file containing the model artifacts
- A manifest (JSON) describing the pack (version, platform, requirements)
- Verification data (SHA-256, size)

Your app downloads packs, verifies them, and activates them.

---

## 🛠️ Technical Details

### **Model Format: CoreML**

- **`.mlpackage`**: Apple's CoreML model format (directory structure)
- **`.mlmodelc`**: Compiled CoreML model (faster, but requires compilation)
- Your Swift code loads `.mlpackage` or `.mlmodelc` using `MLModel`

### **Swift Integration**

Your macOS app has:
- **Method channel**: `spots/local_llm` (Flutter ↔ Swift)
- **Swift code**: `MainFlutterWindow.swift` → `LocalLlmManager`
- **CoreML**: Uses `MLModel` API for inference

### **Dart Integration**

Your Flutter app has:
- **`LocalLlmModelPackManager`**: Downloads and manages model packs
- **`LocalPlatformLlmBackend`**: Calls Swift via method channel
- **`LLMService`**: Routes queries to local or cloud backend

---

## ✅ Quick Checklist

**Before model works in app:**

- [ ] Model downloaded (Path A or B)
- [ ] Model packaged as ZIP
- [ ] SHA-256 hash calculated
- [ ] File size noted
- [ ] ZIP uploaded to Supabase Storage
- [ ] Public URL copied
- [ ] Three secrets set in Supabase (URL, SHA256, SIZE_BYTES)
- [ ] Manifest endpoint tested (returns your model)
- [ ] App built with public key (`--dart-define=LOCAL_LLM_MANIFEST_PUBLIC_KEY_B64_V1=...`)
- [ ] User enables "Offline LLM" in app
- [ ] Model downloads successfully
- [ ] Model activates
- [ ] Chat works offline

---

## 🚨 Common Issues

### **"Model not found" in manifest**
- Check all three secrets are set
- Verify secret names are exact (case-sensitive)
- Check Edge Function logs

### **Download fails**
- Verify Supabase Storage bucket permissions
- Check public URL is accessible
- Verify file size matches (not corrupted)

### **Model doesn't load in Swift**
- Check model path is correct
- Verify `.mlpackage` structure is valid
- Check macOS version (requires macOS 12+)
- Check app logs for CoreML errors

### **Hash verification fails**
- Re-calculate hash: `shasum -a 256 llama-3.1-8b-instruct-coreml.zip`
- Update secret with new hash
- Verify file wasn't corrupted during upload

---

## 📚 Related Documentation

- **Complete setup steps**: `docs/macos_llm_integration/COMPLETE_SETUP_STEPS.md`
- **Bucket setup**: `docs/macos_llm_integration/BUCKET_AND_MODELS_SETUP.md`
- **Model pack system**: `docs/plans/architecture/LOCAL_LLM_MODEL_PACK_SYSTEM.md`
- **Swift implementation**: `macos/Runner/MainFlutterWindow.swift`
- **Dart implementation**: `lib/core/services/local_llm/model_pack_manager.dart`

---

## 🎓 Understanding the Links You Provided

### **HuggingFace Model Page**
- **What it is**: The official Llama 3.1 8B Instruct model repository
- **What you need**: Access to download the model (you have Meta access ✅)
- **Model ID**: `meta-llama/Llama-3.1-8B-Instruct`
- **License**: Llama 3.1 Community License (allows commercial use with attribution)

### **Transformers Library**
- **What it is**: Python library for loading/using HuggingFace models
- **Used by**: `llama-to-coreml` converter (uses transformers to load the model)
- **You don't need**: To use transformers directly - the converter handles it

### **Llama License**
- **What it is**: The license agreement for using Llama models
- **Key points**: 
  - Commercial use allowed
  - Must display "Built with Llama" attribution
  - Must include license text
  - 700M+ MAU requires special license

### **Llama Cookbook**
- **What it is**: Official recipes and examples for using Llama
- **Useful for**: Understanding how to use Llama models
- **Not needed for**: Your integration (you're using CoreML, not Python)

---

## 🎯 Summary

**The complete flow:**

1. **Get model** → Download from HuggingFace (with Meta access) OR use pre-converted
2. **Convert** → Use `llama-to-coreml` to convert to CoreML format (if needed)
3. **Package** → ZIP the `.mlpackage` file
4. **Upload** → Upload ZIP to Supabase Storage bucket
5. **Configure** → Set three Supabase secrets (URL, hash, size)
6. **Test** → Verify manifest endpoint returns your model
7. **Use** → App downloads, verifies, and uses the model automatically

**The app handles:**
- Downloading from Supabase
- Verifying integrity (SHA-256)
- Extracting and activating
- Loading CoreML model in Swift
- Running inference locally

**You handle:**
- Getting the model (download + convert)
- Uploading to Supabase
- Setting secrets
- Testing the manifest

Once set up, users just toggle "Offline LLM" ON and the app handles everything else!

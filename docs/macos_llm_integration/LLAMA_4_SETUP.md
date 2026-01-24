# Llama 4 Setup Guide

**Using Llama 4 Scout or Maverick with AVRAI macOS integration**

---

## 🎯 Model Comparison

### **Llama 4 Scout** (Recommended for macOS)
- **Size:** 17B active parameters (Mixture of Experts)
- **Context:** 10M tokens
- **Performance:** Significantly better than Llama 3.1 8B
- **macOS Suitability:** ✅ Good (17B is manageable on Apple Silicon)
- **Use Case:** Best balance of performance and macOS compatibility

### **Llama 4 Maverick**
- **Size:** 17B active, 400B total parameters (128 experts)
- **Context:** 10M tokens
- **Performance:** Best-in-class, outperforms GPT-4o
- **macOS Suitability:** ⚠️ Challenging (very large, slower inference)
- **Use Case:** Maximum performance if you have high-end Mac

### **Llama 3.1 8B** (Baseline)
- **Size:** 8B parameters
- **Context:** 128k tokens
- **Performance:** Good for chat/conversation
- **macOS Suitability:** ✅ Excellent (fast, efficient)
- **Use Case:** Standard chat, cost-sensitive

---

## 📋 Setup Steps

### **Step 1: Verify Converter Support**

**Important:** `llama-to-coreml` may need updates for Llama 4 support. Test first:

```bash
# Check if llama-to-coreml supports Llama 4
cd /path/to/llama-to-coreml
git pull  # Get latest updates
# Check README or issues for Llama 4 support
```

**If not supported yet:**
- You may need to use `coremltools` directly
- Or wait for `llama-to-coreml` to add Llama 4 support
- Check the GitHub repo for recent updates

---

### **Step 2: Convert Llama 4 Scout**

**Using your updated script:**

```bash
cd /Users/reisgordon/AVRAI

# Convert Llama 4 Scout
LLAMA_TO_COREML=/path/to/llama-to-coreml \
HF_TOKEN=YOUR_HUGGINGFACE_TOKEN \
MODEL=scout \
./scripts/run_llama_to_coreml.sh
```

**Expected output:**
- `models/macos/Llama-4-Scout-Instruct.mlpackage` (~8-10 GB)
- `models/macos/llama-4-scout-instruct-coreml.zip` (~8-10 GB)

**Time:** 60-90 minutes (larger model, longer conversion)

---

### **Step 3: Convert Llama 4 Maverick (Optional)**

**If Scout works and you want to try Maverick:**

```bash
MODEL=maverick LLAMA_TO_COREML=... HF_TOKEN=... ./scripts/run_llama_to_coreml.sh
```

**Expected output:**
- `models/macos/Llama-4-Maverick-Instruct.mlpackage` (~20-30 GB)
- `models/macos/llama-4-maverick-instruct-coreml.zip` (~20-30 GB)

**Warning:** Maverick is very large and may be too slow for real-time chat on macOS.

---

### **Step 4: Alternative - Direct Conversion (If Script Fails)**

If `llama-to-coreml` doesn't support Llama 4 yet, use `coremltools` directly:

```python
# convert_llama4_scout.py
import coremltools as ct
from transformers import AutoTokenizer, AutoModelForCausalLM
import torch

model_name = "meta-llama/Llama-4-Scout-Instruct"
tokenizer = AutoTokenizer.from_pretrained(model_name, token="your_token")
model = AutoModelForCausalLM.from_pretrained(
    model_name,
    torch_dtype=torch.bfloat16,
    device_map="auto",
    token="your_token"
)

# Convert to CoreML
mlmodel = ct.convert(
    model,
    inputs=[ct.TensorType(name="input_ids", shape=(1, ct.RangeDim(1, 10000000)))],  # 10M context
    compute_units=ct.ComputeUnit.ALL,
)

# Save
mlmodel.save("Llama-4-Scout-Instruct.mlpackage")
```

**Note:** Llama 4 uses Mixture of Experts (MoE), which may require special handling in CoreML conversion.

---

### **Step 5: Package and Upload**

Same process as Llama 3.1:

```bash
cd /Users/reisgordon/AVRAI/models/macos

# Package as ZIP
zip -r llama-4-scout-instruct-coreml.zip Llama-4-Scout-Instruct.mlpackage

# Calculate hash and size
shasum -a 256 llama-4-scout-instruct-coreml.zip
stat -f%z llama-4-scout-instruct-coreml.zip

# Upload to Supabase Storage
# Then set secrets:
supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_URL="<url>"
supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SHA256="<hash>"
supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SIZE_BYTES="<size>"
```

---

## ⚠️ Important Considerations

### **1. Converter Compatibility**

**Check first:**
- `llama-to-coreml` may not support Llama 4 yet (released April 2025)
- MoE (Mixture of Experts) architecture may need special handling
- Test conversion before committing to full setup

**If converter doesn't work:**
- Use `coremltools` directly (see Step 4)
- Or wait for `llama-to-coreml` to add Llama 4 support
- Check GitHub issues: https://github.com/andmev/llama-to-coreml/issues

### **2. Performance Expectations**

**Llama 4 Scout (17B):**
- **Inference speed:** ~2-3x slower than 8B
- **Memory:** ~2x more RAM needed
- **Quality:** Significantly better reasoning, math, coding

**Llama 4 Maverick (400B total):**
- **Inference speed:** Much slower (may not be practical on macOS)
- **Memory:** Very high requirements
- **Quality:** Best-in-class, but may be too slow for real-time chat

### **3. Device Requirements**

**For Llama 4 Scout:**
- **RAM:** 16GB+ recommended (vs 8GB for 8B)
- **Disk:** 12GB+ free (vs 6GB for 8B)
- **CPU:** More cores = better performance
- **Apple Silicon:** M1 Pro/Max or better recommended

**For Llama 4 Maverick:**
- **RAM:** 32GB+ recommended
- **Disk:** 20GB+ free
- **CPU:** M2 Max/M3 Max or better
- **May be too slow for real-time use**

### **4. Tier Configuration**

Your app currently uses `llama8b` tier. For Llama 4 Scout, you may want to:

1. **Keep using `llama8b` tier** (simpler, just use different model)
2. **Add new tier** (e.g., `llama4scout`) for better device gating

**Option 1 (Simpler):**
- Just use Llama 4 Scout with existing `llama8b` tier
- App will download/use it the same way
- Device gate may need adjustment (higher RAM/disk requirements)

**Option 2 (More Precise):**
- Add `llama4scout` tier to `OfflineLlmTier` enum
- Update device capability gate thresholds
- Update Edge Function to support new tier

---

## 🧪 Testing Conversion

**Before full setup, test conversion:**

```bash
# Quick test - convert a small portion first
cd /path/to/llama-to-coreml

# Try converting (may fail if not supported)
python scripts/convert_model.py \
  --model-path meta-llama/Llama-4-Scout-Instruct \
  --output-path /tmp/test-scout.mlpackage \
  --token $HF_TOKEN \
  --compile
```

**If it fails:**
- Check error message
- Look for MoE-specific issues
- May need to wait for converter updates

---

## 📊 Performance Comparison

| Model | Parameters | Context | Speed (macOS) | Quality | Best For |
|-------|-----------|--------|---------------|---------|----------|
| **3.1 8B** | 8B | 128k | ⚡⚡⚡ Fast | Good | Chat, general use |
| **4 Scout** | 17B active | 10M | ⚡⚡ Medium | Excellent | Reasoning, math, coding |
| **4 Maverick** | 400B total | 10M | ⚡ Slow | Best | Maximum quality (if speed acceptable) |

---

## 🎯 Recommendation

**For macOS, use Llama 4 Scout:**
- ✅ Best performance/quality balance
- ✅ Reasonable size for Apple Silicon
- ✅ Significant quality improvement over 3.1 8B
- ✅ 10M context window (vs 128k)

**Skip Maverick unless:**
- You have M2 Max/M3 Max with 64GB+ RAM
- You're okay with slower inference
- You need maximum quality for specific tasks

---

## 🔧 Troubleshooting

### **Converter doesn't support Llama 4**
- Use `coremltools` directly (see Step 4)
- Check for converter updates: `cd llama-to-coreml && git pull`
- Monitor GitHub issues for Llama 4 support

### **Conversion fails with MoE error**
- MoE (Mixture of Experts) may need special handling
- Try without `--compile` flag first
- Check if converter needs updates for MoE support

### **Model too slow on macOS**
- Try quantization (if supported)
- Consider sticking with 3.1 8B for speed
- Scout may be acceptable, Maverick likely too slow

### **Out of memory during conversion**
- Close other applications
- Use smaller batch size if converter supports it
- Ensure 20GB+ free disk space

---

## 📚 Next Steps

1. **Test conversion** with Llama 4 Scout
2. **If successful:** Follow normal setup (package, upload, configure)
3. **If fails:** Wait for converter updates or use `coremltools` directly
4. **Monitor performance** - ensure inference speed is acceptable
5. **Update device gates** if needed (higher RAM/disk requirements)

---

## 🔗 Resources

- **Llama 4 Models:** https://huggingface.co/collections/meta-llama/llama-4
- **Llama 4 Release:** https://huggingface.co/blog/llama4-release
- **Converter:** https://github.com/andmev/llama-to-coreml
- **CoreML Tools:** https://coremltools.readme.io/

#!/bin/bash
# macOS LLM Operational Setup Script
# Complete step-by-step guide for preparing, uploading, and configuring models
#
# Usage: ./scripts/macos_llm_operational_setup.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MODELS_DIR="$PROJECT_ROOT/models/macos"
TEMP_DIR="$PROJECT_ROOT/temp_models"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   macOS LLM Model Setup - Operational Guide            ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Step 0: Signing Key (required for manifest)
setup_signing_key() {
    echo -e "${YELLOW}Step 0: Manifest Signing Key${NC}"
    echo "============================="
    echo ""
    echo "The manifest endpoint requires an Ed25519 signing key."
    echo "Without it, the manifest returns: Signing key not configured"
    echo ""
    
    # Check if key might already be set (we can't read secrets, but we can test endpoint)
    echo "Have you already set LOCAL_LLM_MANIFEST_SIGNING_KEY_B64?"
    read -p " (y=skip / n=generate and configure now): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Skipping signing key setup${NC}"
        echo ""
        return
    fi
    
    echo "Generating Ed25519 keypair..."
    if ! command -v dart &> /dev/null; then
        echo -e "${RED}dart not found. Install Dart SDK or run manually:${NC}"
        echo "  dart run scripts/security/generate_local_llm_manifest_keys.dart"
        echo ""
        show_signing_commands
        return
    fi
    
    local key_output
    key_output=$(cd "$PROJECT_ROOT" && dart run scripts/security/generate_local_llm_manifest_keys.dart 2>/dev/null) || {
        echo -e "${RED}Key generation failed${NC}"
        show_signing_commands
        return
    }
    
    echo "$key_output"
    echo ""
    echo -e "${GREEN}Copy the values above and run:${NC}"
    echo ""
    echo "  supabase secrets set LOCAL_LLM_MANIFEST_KEY_ID=v1"
    echo "  supabase secrets set LOCAL_LLM_MANIFEST_SIGNING_KEY_B64=<LOCAL_LLM_MANIFEST_SIGNING_KEY_B64 from above>"
    echo ""
    echo "Save LOCAL_LLM_MANIFEST_PUBLIC_KEY_B64_V1 for app build (--dart-define) later."
    echo ""
    read -p "Press Enter when done..."
    echo ""
}

show_signing_commands() {
    echo "Manual steps:"
    echo "  1. dart run scripts/security/generate_local_llm_manifest_keys.dart"
    echo "  2. supabase secrets set LOCAL_LLM_MANIFEST_KEY_ID=v1"
    echo "  3. supabase secrets set LOCAL_LLM_MANIFEST_SIGNING_KEY_B64=<base64 from step 1>"
    echo ""
}

# Step 1: Check Prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Step 1: Checking Prerequisites${NC}"
    echo "=================================="
    
    local missing=0
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}✗ python3 not found${NC}"
        missing=1
    else
        echo -e "${GREEN}✓ python3 found${NC}"
    fi
    
    # Check pip
    if ! command -v pip3 &> /dev/null; then
        echo -e "${RED}✗ pip3 not found${NC}"
        missing=1
    else
        echo -e "${GREEN}✓ pip3 found${NC}"
    fi
    
    # Check Supabase CLI
    if ! command -v supabase &> /dev/null; then
        echo -e "${YELLOW}⚠ supabase CLI not found${NC}"
        echo "  Install: npm install -g supabase"
        echo "  Or use Supabase Dashboard for manual setup"
    else
        echo -e "${GREEN}✓ supabase CLI found${NC}"
    fi
    
    # Check shasum
    if ! command -v shasum &> /dev/null; then
        echo -e "${RED}✗ shasum not found${NC}"
        missing=1
    else
        echo -e "${GREEN}✓ shasum found${NC}"
    fi
    
    if [ $missing -eq 1 ]; then
        echo -e "${RED}Please install missing prerequisites and try again${NC}"
        exit 1
    fi
    
    echo ""
}

# Step 2: Install Python Dependencies
install_dependencies() {
    echo -e "${YELLOW}Step 2: Installing Python Dependencies${NC}"
    echo "======================================"
    echo ""
    echo "Required packages:"
    echo "  - coremltools (for CoreML conversion)"
    echo "  - transformers (for model loading)"
    echo "  - torch (for model conversion)"
    echo ""
    read -p "Install Python dependencies? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Installing..."
        pip3 install coremltools transformers torch huggingface-hub || {
            echo -e "${RED}Installation failed. Please install manually:${NC}"
            echo "  pip3 install coremltools transformers torch huggingface-hub"
            exit 1
        }
        echo -e "${GREEN}✓ Dependencies installed${NC}"
    else
        echo -e "${YELLOW}Skipping dependency installation${NC}"
    fi
    echo ""
}

# Step 3: Model Conversion
convert_models() {
    echo -e "${YELLOW}Step 3: Model Conversion${NC}"
    echo "========================="
    echo ""
    echo "This step will:"
    echo "  1. Download Llama 3.1 8B model (if needed)"
    echo "  2. Convert to CoreML format (Apple Silicon)"
    echo "  3. Prepare GGUF model (Intel - optional)"
    echo ""
    echo -e "${YELLOW}Note:${NC} CoreML conversion requires:"
    echo "  - Apple Silicon Mac (M1/M2/M3)"
    echo "  - Significant disk space (~20GB)"
    echo "  - Time (~30-60 minutes)"
    echo ""
    read -p "Proceed with model conversion? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Skipping conversion. You can use pre-converted models.${NC}"
        return
    fi
    
    mkdir -p "$MODELS_DIR"
    mkdir -p "$TEMP_DIR"
    
    # Create conversion script
    cat > "$TEMP_DIR/convert_to_coreml.py" << 'PYTHON_EOF'
#!/usr/bin/env python3
"""
Convert Llama 3.1 8B to CoreML format for macOS.
"""
import os
import sys
import coremltools as ct
from transformers import AutoTokenizer, AutoModelForCausalLM
import torch

def main():
    model_name = "meta-llama/Llama-3.1-8B-Instruct"
    output_dir = sys.argv[1] if len(sys.argv) > 1 else "./models/macos"
    
    print(f"Loading model: {model_name}")
    print("This may take several minutes and require ~20GB disk space...")
    
    try:
        # Load model and tokenizer
        tokenizer = AutoTokenizer.from_pretrained(model_name)
        model = AutoModelForCausalLM.from_pretrained(
            model_name,
            torch_dtype=torch.float16,
            device_map="auto"
        )
        
        print("Converting to CoreML...")
        # Convert to CoreML
        # Note: This is a simplified conversion
        # Full conversion may require more configuration
        mlmodel = ct.convert(
            model,
            inputs=[ct.TensorType(name="input_ids", shape=(1, ct.RangeDim(1, 4096)))],
            compute_units=ct.ComputeUnit.ALL,
        )
        
        # Save
        output_path = os.path.join(output_dir, "llama-3.1-8b-instruct.mlpackage")
        mlmodel.save(output_path)
        
        print(f"✓ Model saved to: {output_path}")
        print("\nNext steps:")
        print("  1. Package as ZIP: zip -r llama-3.1-8b-instruct-coreml.zip llama-3.1-8b-instruct.mlpackage")
        print("  2. Calculate SHA-256: shasum -a 256 llama-3.1-8b-instruct-coreml.zip")
        
    except Exception as e:
        print(f"Error: {e}")
        print("\nAlternative: Use pre-converted models from HuggingFace")
        print("  https://huggingface.co/models?search=llama-3.1-8b-coreml")
        sys.exit(1)

if __name__ == "__main__":
    main()
PYTHON_EOF
    
    chmod +x "$TEMP_DIR/convert_to_coreml.py"
    
    echo "Running conversion script..."
    echo -e "${YELLOW}This will take 30-60 minutes...${NC}"
    python3 "$TEMP_DIR/convert_to_coreml.py" "$MODELS_DIR" || {
        echo -e "${RED}Conversion failed. See error above.${NC}"
        echo ""
        echo "Alternative options:"
        echo "  1. Use pre-converted models from HuggingFace"
        echo "  2. Use cloud conversion services"
        echo "  3. Download GGUF models directly"
        return
    }
    
    echo -e "${GREEN}✓ Conversion complete${NC}"
    echo ""
}

# Step 4: Calculate Hashes
calculate_hashes() {
    echo -e "${YELLOW}Step 4: Calculate SHA-256 Hashes${NC}"
    echo "=================================="
    echo ""
    
    mkdir -p "$MODELS_DIR"
    
    local hashes_file="$MODELS_DIR/hashes.txt"
    > "$hashes_file"  # Clear file
    
    # CoreML model
    if [ -f "$MODELS_DIR/llama-3.1-8b-instruct-coreml.zip" ]; then
        echo "Calculating hash for CoreML model..."
        COREML_HASH=$(shasum -a 256 "$MODELS_DIR/llama-3.1-8b-instruct-coreml.zip" | awk '{print $1}')
        COREML_SIZE=$(stat -f%z "$MODELS_DIR/llama-3.1-8b-instruct-coreml.zip")
        
        echo -e "${GREEN}CoreML Model:${NC}"
        echo "  Hash: $COREML_HASH"
        echo "  Size: $COREML_SIZE bytes ($(numfmt --to=iec-i --suffix=B $COREML_SIZE))"
        echo ""
        echo "CoreML Model:" >> "$hashes_file"
        echo "  Hash: $COREML_HASH" >> "$hashes_file"
        echo "  Size: $COREML_SIZE bytes" >> "$hashes_file"
        echo "" >> "$hashes_file"
    else
        echo -e "${YELLOW}CoreML model not found. Skipping.${NC}"
    fi
    
    # GGUF model
    if [ -f "$MODELS_DIR/llama-3.1-8b-instruct.gguf" ]; then
        echo "Calculating hash for GGUF model..."
        GGUF_HASH=$(shasum -a 256 "$MODELS_DIR/llama-3.1-8b-instruct.gguf" | awk '{print $1}')
        GGUF_SIZE=$(stat -f%z "$MODELS_DIR/llama-3.1-8b-instruct.gguf")
        
        echo -e "${GREEN}GGUF Model:${NC}"
        echo "  Hash: $GGUF_HASH"
        echo "  Size: $GGUF_SIZE bytes ($(numfmt --to=iec-i --suffix=B $GGUF_SIZE))"
        echo ""
        echo "GGUF Model:" >> "$hashes_file"
        echo "  Hash: $GGUF_HASH" >> "$hashes_file"
        echo "  Size: $GGUF_SIZE bytes" >> "$hashes_file"
        echo "" >> "$hashes_file"
    else
        echo -e "${YELLOW}GGUF model not found. Skipping.${NC}"
    fi
    
    if [ -f "$hashes_file" ] && [ -s "$hashes_file" ]; then
        echo -e "${GREEN}✓ Hashes saved to: $hashes_file${NC}"
        echo ""
        echo "Copy these values for Supabase secrets configuration:"
        cat "$hashes_file"
    fi
    echo ""
}

# Step 5: Upload Instructions
upload_instructions() {
    echo -e "${YELLOW}Step 5: Upload Models to Supabase Storage${NC}"
    echo "=========================================="
    echo ""
    
    # Check if migration needs to be run
    echo "1. Create storage bucket (if not exists):"
    echo ""
    if command -v supabase &> /dev/null; then
        echo "   Run migration:"
        echo "   ${GREEN}supabase migration up${NC}"
        echo ""
        echo "   Or manually in SQL Editor:"
        echo "   ${BLUE}See: supabase/migrations/064_local_llm_models_bucket_v1.sql${NC}"
    else
        echo "   ${YELLOW}Manual setup required:${NC}"
        echo "   ${BLUE}See: supabase/migrations/064_local_llm_models_bucket_v1.sql${NC}"
    fi
    echo ""
    
    echo "2. Upload models via Supabase Dashboard:"
    echo "   a. Go to: https://supabase.com/dashboard/project/[your-project]/storage"
    echo "   b. Select bucket: ${GREEN}local-llm-models${NC}"
    echo "   c. Click ${GREEN}Upload${NC}"
    echo "   d. Upload:"
    if [ -f "$MODELS_DIR/llama-3.1-8b-instruct-coreml.zip" ]; then
        echo "      - llama-3.1-8b-instruct-coreml.zip"
    fi
    if [ -f "$MODELS_DIR/llama-3.1-8b-instruct.gguf" ]; then
        echo "      - llama-3.1-8b-instruct.gguf"
    fi
    echo ""
    
    echo "3. Get public URLs:"
    echo "   After upload, copy the public URL for each file"
    echo "   Format: https://[project-ref].supabase.co/storage/v1/object/public/local-llm-models/[filename]"
    echo ""
    
    read -p "Have you uploaded the models? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        read -p "Enter CoreML model URL (or press Enter to skip): " COREML_URL
        if [ ! -z "$COREML_URL" ]; then
            echo "$COREML_URL" > "$TEMP_DIR/coreml_url.txt"
        fi
        
        read -p "Enter GGUF model URL (or press Enter to skip): " GGUF_URL
        if [ ! -z "$GGUF_URL" ]; then
            echo "$GGUF_URL" > "$TEMP_DIR/gguf_url.txt"
        fi
    fi
    echo ""
}

# Step 6: Configure Secrets
configure_secrets() {
    echo -e "${YELLOW}Step 6: Configure Supabase Secrets${NC}"
    echo "===================================="
    echo ""
    
    if ! command -v supabase &> /dev/null; then
        echo -e "${YELLOW}Supabase CLI not found.${NC}"
        echo "Configure secrets manually in Supabase Dashboard:"
        echo "  Project Settings → Edge Functions → Secrets"
        echo ""
        show_secret_commands
        return
    fi
    
    # Load URLs if available
    COREML_URL=""
    GGUF_URL=""
    if [ -f "$TEMP_DIR/coreml_url.txt" ]; then
        COREML_URL=$(cat "$TEMP_DIR/coreml_url.txt")
    fi
    if [ -f "$TEMP_DIR/gguf_url.txt" ]; then
        GGUF_URL=$(cat "$TEMP_DIR/gguf_url.txt")
    fi
    
    # Load hashes
    COREML_HASH=""
    COREML_SIZE=""
    GGUF_HASH=""
    GGUF_SIZE=""
    
    if [ -f "$MODELS_DIR/hashes.txt" ]; then
        COREML_HASH=$(grep -A 1 "CoreML Model:" "$MODELS_DIR/hashes.txt" | grep "Hash:" | awk '{print $2}')
        COREML_SIZE=$(grep -A 1 "CoreML Model:" "$MODELS_DIR/hashes.txt" | grep "Size:" | awk '{print $2}')
        GGUF_HASH=$(grep -A 1 "GGUF Model:" "$MODELS_DIR/hashes.txt" | grep "Hash:" | awk '{print $2}')
        GGUF_SIZE=$(grep -A 1 "GGUF Model:" "$MODELS_DIR/hashes.txt" | grep "Size:" | awk '{print $2}')
    fi
    
    echo "Configure secrets:"
    echo ""
    
    # CoreML secrets
    if [ ! -z "$COREML_URL" ] && [ ! -z "$COREML_HASH" ] && [ ! -z "$COREML_SIZE" ]; then
        echo -e "${GREEN}Setting CoreML secrets...${NC}"
        supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_URL="$COREML_URL" || echo -e "${YELLOW}Failed to set URL${NC}"
        supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SHA256="$COREML_HASH" || echo -e "${YELLOW}Failed to set hash${NC}"
        supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SIZE_BYTES="$COREML_SIZE" || echo -e "${YELLOW}Failed to set size${NC}"
        echo -e "${GREEN}✓ CoreML secrets configured${NC}"
    else
        echo -e "${YELLOW}CoreML values missing. Configure manually:${NC}"
        show_secret_commands
    fi
    
    echo ""
    
    # GGUF secrets (optional)
    if [ ! -z "$GGUF_URL" ] && [ ! -z "$GGUF_HASH" ] && [ ! -z "$GGUF_SIZE" ]; then
        read -p "Configure GGUF (Intel) secrets? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${GREEN}Setting GGUF secrets...${NC}"
            supabase secrets set LOCAL_LLM_MACOS_INTEL_GGUF_URL="$GGUF_URL" || echo -e "${YELLOW}Failed to set URL${NC}"
            supabase secrets set LOCAL_LLM_MACOS_INTEL_GGUF_SHA256="$GGUF_HASH" || echo -e "${YELLOW}Failed to set hash${NC}"
            supabase secrets set LOCAL_LLM_MACOS_INTEL_GGUF_SIZE_BYTES="$GGUF_SIZE" || echo -e "${YELLOW}Failed to set size${NC}"
            echo -e "${GREEN}✓ GGUF secrets configured${NC}"
        fi
    fi
    
    echo ""
}

show_secret_commands() {
    echo "Run these commands manually:"
    echo ""
    echo "# CoreML (Apple Silicon)"
    echo "supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_URL=\"https://...\""
    echo "supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SHA256=\"[hash]\""
    echo "supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SIZE_BYTES=\"[size]\""
    echo ""
    echo "# GGUF (Intel - optional)"
    echo "supabase secrets set LOCAL_LLM_MACOS_INTEL_GGUF_URL=\"https://...\""
    echo "supabase secrets set LOCAL_LLM_MACOS_INTEL_GGUF_SHA256=\"[hash]\""
    echo "supabase secrets set LOCAL_LLM_MACOS_INTEL_GGUF_SIZE_BYTES=\"[size]\""
    echo ""
}

# Step 7: Deploy Edge Function
deploy_edge_function() {
    echo -e "${YELLOW}Step 7: Deploy Edge Function${NC}"
    echo "============================="
    echo ""
    
    if ! command -v supabase &> /dev/null; then
        echo -e "${YELLOW}Supabase CLI not found.${NC}"
        echo "Deploy manually via Supabase Dashboard or install CLI:"
        echo "  npm install -g supabase"
        return
    fi
    
    echo "Deploying local-llm-manifest Edge Function..."
    supabase functions deploy local-llm-manifest --no-verify-jwt || {
        echo -e "${RED}Deployment failed${NC}"
        echo "Deploy manually:"
        echo "  supabase functions deploy local-llm-manifest --no-verify-jwt"
        return
    }
    
    echo -e "${GREEN}✓ Edge Function deployed${NC}"
    echo ""
}

# Step 8: Testing Instructions
testing_instructions() {
    echo -e "${YELLOW}Step 8: Testing Instructions${NC}"
    echo "============================="
    echo ""
    
    echo "1. Test manifest endpoint:"
    echo ""
    echo "   curl -X POST https://[project-ref].supabase.co/functions/v1/local-llm-manifest \\"
    echo "     -H 'Content-Type: application/json' \\"
    echo "     -d '{\"platform\": \"macos\", \"tier\": \"llama8b\"}'"
    echo ""
    
    echo "2. Test in app (Apple Silicon Mac):"
    echo "   a. Launch app"
    echo "   b. Go to Settings → On-Device AI"
    echo "   c. Enable 'Offline LLM'"
    echo "   d. Verify download starts automatically"
    echo "   e. Check model activates after download"
    echo ""
    
    echo "3. Test in app (Intel Mac - if GGUF configured):"
    echo "   a. Same steps as above"
    echo "   b. Verify GGUF model is selected"
    echo ""
    
    echo "4. Verify model works:"
    echo "   a. Use AI chat feature"
    echo "   b. Verify responses are generated"
    echo "   c. Check logs for any errors"
    echo ""
    
    echo "5. Test fallback:"
    echo "   a. Disable offline LLM"
    echo "   b. Verify cloud backend is used"
    echo ""
}

# Main execution
main() {
    check_prerequisites
    setup_signing_key
    install_dependencies
    
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    convert_models
    calculate_hashes
    upload_instructions
    configure_secrets
    deploy_edge_function
    testing_instructions
    
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   Setup Complete!                                      ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Test manifest endpoint (see Step 8)"
    echo "  2. Test in app on macOS"
    echo "  3. Monitor download logs"
    echo "  4. Verify model activation"
    echo ""
    echo "Documentation:"
    echo "  - Security Guide: docs/macos_llm_integration/SECURE_MODEL_HOSTING_GUIDE.md"
    echo "  - Setup Guide: docs/macos_llm_integration/MODEL_HOSTING_GUIDE.md"
    echo ""
}

main

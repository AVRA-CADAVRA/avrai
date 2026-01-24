#!/bin/bash
# macOS LLM Model Setup Script
# Converts and prepares models for macOS local LLM integration
#
# This script helps with:
# 1. Converting Llama 3.1 8B to CoreML format (Apple Silicon)
# 2. Preparing GGUF model for Intel Macs
# 3. Calculating SHA-256 hashes
# 4. Packaging for upload

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MODELS_DIR="$PROJECT_ROOT/models/macos"
TEMP_DIR="$PROJECT_ROOT/temp_models"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}macOS LLM Model Setup${NC}"
echo "========================"
echo ""

# Check for required tools
check_dependencies() {
    echo "Checking dependencies..."
    
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}Error: python3 is required${NC}"
        exit 1
    fi
    
    if ! command -v shasum &> /dev/null; then
        echo -e "${RED}Error: shasum is required${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Dependencies OK${NC}"
}

# Create directories
setup_directories() {
    echo "Setting up directories..."
    mkdir -p "$MODELS_DIR"
    mkdir -p "$TEMP_DIR"
    echo -e "${GREEN}✓ Directories created${NC}"
}

# Convert to CoreML (requires coremltools and model files)
convert_to_coreml() {
    echo ""
    echo -e "${YELLOW}Step 1: CoreML Conversion (Apple Silicon)${NC}"
    echo "=========================================="
    echo ""
    echo "This step requires:"
    echo "  1. Llama 3.1 8B model files (HuggingFace format)"
    echo "  2. coremltools Python package"
    echo "  3. Apple Silicon Mac for optimal conversion"
    echo ""
    echo "Install coremltools:"
    echo "  pip3 install coremltools"
    echo ""
    echo "Conversion command (example):"
    echo "  python3 -m coremltools.models.converters.mlprogram \\"
    echo "    --model-path llama-3.1-8b-instruct \\"
    echo "    --output-path $MODELS_DIR/llama-3.1-8b-instruct.mlpackage \\"
    echo "    --compute-units all"
    echo ""
    read -p "Have you converted the model? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Skipping CoreML conversion${NC}"
        return
    fi
    
    # Package CoreML model as zip
    if [ -d "$MODELS_DIR/llama-3.1-8b-instruct.mlpackage" ]; then
        echo "Packaging CoreML model..."
        cd "$MODELS_DIR"
        zip -r llama-3.1-8b-instruct-coreml.zip llama-3.1-8b-instruct.mlpackage
        echo -e "${GREEN}✓ CoreML model packaged${NC}"
    else
        echo -e "${YELLOW}CoreML model not found, skipping${NC}"
    fi
}

# Prepare GGUF model (for Intel Macs)
prepare_gguf() {
    echo ""
    echo -e "${YELLOW}Step 2: GGUF Model Preparation (Intel)${NC}"
    echo "======================================"
    echo ""
    echo "This step requires:"
    echo "  1. GGUF model file (download from HuggingFace or convert)"
    echo "  2. Model should be quantized (Q4_0 or Q4_K_M recommended)"
    echo ""
    echo "Download GGUF models from:"
    echo "  https://huggingface.co/models?search=llama-3.1-8b-gguf"
    echo ""
    read -p "Have you prepared the GGUF model? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Skipping GGUF preparation${NC}"
        return
    fi
    
    if [ -f "$MODELS_DIR/llama-3.1-8b-instruct.gguf" ]; then
        echo -e "${GREEN}✓ GGUF model found${NC}"
    else
        echo -e "${YELLOW}GGUF model not found${NC}"
    fi
}

# Calculate SHA-256 hashes
calculate_hashes() {
    echo ""
    echo -e "${YELLOW}Step 3: Calculate SHA-256 Hashes${NC}"
    echo "=================================="
    echo ""
    
    if [ -f "$MODELS_DIR/llama-3.1-8b-instruct-coreml.zip" ]; then
        echo "Calculating hash for CoreML model..."
        COREML_HASH=$(shasum -a 256 "$MODELS_DIR/llama-3.1-8b-instruct-coreml.zip" | awk '{print $1}')
        COREML_SIZE=$(stat -f%z "$MODELS_DIR/llama-3.1-8b-instruct-coreml.zip")
        echo -e "${GREEN}CoreML Hash: $COREML_HASH${NC}"
        echo -e "${GREEN}CoreML Size: $COREML_SIZE bytes${NC}"
        echo ""
        echo "Add to Supabase secrets:"
        echo "  LOCAL_LLM_MACOS_COREML_ZIP_SHA256=\"$COREML_HASH\""
        echo "  LOCAL_LLM_MACOS_COREML_ZIP_SIZE_BYTES=\"$COREML_SIZE\""
        echo ""
    fi
    
    if [ -f "$MODELS_DIR/llama-3.1-8b-instruct.gguf" ]; then
        echo "Calculating hash for GGUF model..."
        GGUF_HASH=$(shasum -a 256 "$MODELS_DIR/llama-3.1-8b-instruct.gguf" | awk '{print $1}')
        GGUF_SIZE=$(stat -f%z "$MODELS_DIR/llama-3.1-8b-instruct.gguf")
        echo -e "${GREEN}GGUF Hash: $GGUF_HASH${NC}"
        echo -e "${GREEN}GGUF Size: $GGUF_SIZE bytes${NC}"
        echo ""
        echo "Add to Supabase secrets:"
        echo "  LOCAL_LLM_MACOS_INTEL_GGUF_SHA256=\"$GGUF_HASH\""
        echo "  LOCAL_LLM_MACOS_INTEL_GGUF_SIZE_BYTES=\"$GGUF_SIZE\""
        echo ""
    fi
}

# Generate upload instructions
upload_instructions() {
    echo ""
    echo -e "${YELLOW}Step 4: Upload Instructions${NC}"
    echo "=========================="
    echo ""
    echo "1. Upload models to Supabase Storage:"
    echo "   - Bucket: local-llm-models"
    echo "   - Make files publicly accessible"
    echo ""
    echo "2. Get public URLs and add to Supabase secrets:"
    echo "   supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_URL=\"https://...\""
    echo "   supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SHA256=\"...\""
    echo "   supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SIZE_BYTES=\"...\""
    echo ""
    echo "   # Optional: Intel fallback"
    echo "   supabase secrets set LOCAL_LLM_MACOS_INTEL_GGUF_URL=\"https://...\""
    echo "   supabase secrets set LOCAL_LLM_MACOS_INTEL_GGUF_SHA256=\"...\""
    echo "   supabase secrets set LOCAL_LLM_MACOS_INTEL_GGUF_SIZE_BYTES=\"...\""
    echo ""
    echo "3. Deploy Edge Function:"
    echo "   supabase functions deploy local-llm-manifest --no-verify-jwt"
    echo ""
}

# Main execution
main() {
    check_dependencies
    setup_directories
    convert_to_coreml
    prepare_gguf
    calculate_hashes
    upload_instructions
    
    echo ""
    echo -e "${GREEN}Setup complete!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Upload models to storage"
    echo "  2. Configure Supabase secrets"
    echo "  3. Deploy Edge Function"
    echo "  4. Test model download in app"
}

main

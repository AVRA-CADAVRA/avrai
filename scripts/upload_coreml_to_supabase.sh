#!/bin/bash
# Upload CoreML model to Supabase Storage and configure secrets

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# File details
MODEL_FILE="models/macos/llama-3.1-8b-instruct-coreml.zip"
MODEL_NAME="llama-3.1-8b-instruct-coreml.zip"
SHA256="843c1773f2335dbd1ede45fb21684499641648b7e04c3a76989d9eb0a54672f8"
SIZE_BYTES="3936400726"
PROJECT_REF="nfzlwgbvezwwrutqpedy"
BUCKET_NAME="local-llm-models"
PUBLIC_URL="https://${PROJECT_REF}.supabase.co/storage/v1/object/public/${BUCKET_NAME}/${MODEL_NAME}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Upload CoreML Model to Supabase${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if file exists
if [ ! -f "$MODEL_FILE" ]; then
    echo -e "${YELLOW}❌ Model file not found: ${MODEL_FILE}${NC}"
    echo ""
    echo "Please ensure the file exists before running this script."
    exit 1
fi

echo -e "${GREEN}✅ Model file found: ${MODEL_FILE}${NC}"
echo -e "   Size: $(du -h "$MODEL_FILE" | cut -f1)"
echo ""

# Check if Supabase CLI is available
if ! command -v supabase &> /dev/null; then
    echo -e "${YELLOW}⚠️  Supabase CLI not found${NC}"
    echo ""
    echo "Please install: https://supabase.com/docs/guides/cli"
    echo ""
    echo "Or upload manually via Dashboard:"
    echo "  https://supabase.com/dashboard/project/${PROJECT_REF}/storage/buckets/${BUCKET_NAME}"
    exit 1
fi

echo -e "${GREEN}✅ Supabase CLI found${NC}"
echo ""

# Ask user which method they prefer
echo "Choose upload method:"
echo "  1) Dashboard (recommended for large files - shows progress)"
echo "  2) CLI (automated, but may be slower)"
echo ""
read -p "Enter choice (1 or 2): " choice

case $choice in
    1)
        echo ""
        echo -e "${BLUE}📤 Dashboard Upload Method${NC}"
        echo "=========================================="
        echo ""
        echo "1. Open this URL in your browser:"
        echo -e "   ${GREEN}https://supabase.com/dashboard/project/${PROJECT_REF}/storage/buckets/${BUCKET_NAME}${NC}"
        echo ""
        echo "2. Click 'Upload' button"
        echo ""
        echo "3. Select file:"
        echo -e "   ${GREEN}$(pwd)/${MODEL_FILE}${NC}"
        echo ""
        echo "4. Wait for upload to complete (5-15 minutes for 3.7GB)"
        echo ""
        echo "5. After upload, copy the public URL"
        echo ""
        read -p "Press Enter when upload is complete..."
        echo ""
        read -p "Enter the public URL (or press Enter to use default): " custom_url
        
        if [ ! -z "$custom_url" ]; then
            PUBLIC_URL="$custom_url"
        fi
        
        echo ""
        echo -e "${BLUE}🔐 Setting Supabase Secrets...${NC}"
        echo ""
        
        supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_URL="${PUBLIC_URL}"
        supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SHA256="${SHA256}"
        supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SIZE_BYTES="${SIZE_BYTES}"
        
        echo ""
        echo -e "${GREEN}✅ Secrets configured!${NC}"
        ;;
    2)
        echo ""
        echo -e "${BLUE}📤 CLI Upload Method${NC}"
        echo "=========================================="
        echo ""
        echo "Uploading via Supabase CLI..."
        echo "This may take 5-15 minutes for 3.7GB..."
        echo ""
        
        supabase storage upload "${BUCKET_NAME}" "${MODEL_NAME}" --file "${MODEL_FILE}"
        
        echo ""
        echo -e "${GREEN}✅ Upload complete!${NC}"
        echo ""
        echo -e "${BLUE}🔐 Setting Supabase Secrets...${NC}"
        echo ""
        
        supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_URL="${PUBLIC_URL}"
        supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SHA256="${SHA256}"
        supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SIZE_BYTES="${SIZE_BYTES}"
        
        echo ""
        echo -e "${GREEN}✅ Secrets configured!${NC}"
        ;;
    *)
        echo -e "${YELLOW}Invalid choice. Exiting.${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ Setup Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Model URL: ${PUBLIC_URL}"
echo "SHA-256: ${SHA256}"
echo "Size: ${SIZE_BYTES} bytes"
echo ""
echo "Test the manifest endpoint:"
echo "  curl https://${PROJECT_REF}.supabase.co/functions/v1/local-llm-manifest"
echo ""

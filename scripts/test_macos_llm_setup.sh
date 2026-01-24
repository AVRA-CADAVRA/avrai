#!/bin/bash
# Test macOS LLM Setup
# Verifies that models are configured correctly

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Testing macOS LLM Setup${NC}"
echo "========================"
echo ""

# Check Supabase CLI
if ! command -v supabase &> /dev/null; then
    echo -e "${YELLOW}⚠ Supabase CLI not found. Some tests will be skipped.${NC}"
    echo ""
    SKIP_CLI=1
else
    SKIP_CLI=0
fi

# Test 1: Check secrets
echo -e "${YELLOW}Test 1: Checking Supabase Secrets${NC}"
echo "--------------------------------"

if [ $SKIP_CLI -eq 0 ]; then
    # Check if secrets are set
    secrets=$(supabase secrets list 2>/dev/null || echo "")
    
    if echo "$secrets" | grep -q "LOCAL_LLM_MACOS_COREML_ZIP_URL"; then
        echo -e "${GREEN}✓ CoreML URL secret found${NC}"
    else
        echo -e "${RED}✗ CoreML URL secret not found${NC}"
    fi
    
    if echo "$secrets" | grep -q "LOCAL_LLM_MACOS_COREML_ZIP_SHA256"; then
        echo -e "${GREEN}✓ CoreML SHA256 secret found${NC}"
    else
        echo -e "${RED}✗ CoreML SHA256 secret not found${NC}"
    fi
    
    if echo "$secrets" | grep -q "LOCAL_LLM_MACOS_COREML_ZIP_SIZE_BYTES"; then
        echo -e "${GREEN}✓ CoreML Size secret found${NC}"
    else
        echo -e "${RED}✗ CoreML Size secret not found${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Skipped (CLI not available)${NC}"
    echo "Check secrets manually in Supabase Dashboard"
fi

echo ""

# Test 2: Test manifest endpoint
echo -e "${YELLOW}Test 2: Testing Manifest Endpoint${NC}"
echo "--------------------------------"

read -p "Enter your Supabase project URL (e.g., https://xxxxx.supabase.co): " SUPABASE_URL

if [ -z "$SUPABASE_URL" ]; then
    echo -e "${YELLOW}⚠ Skipped (no URL provided)${NC}"
else
    echo "Testing manifest endpoint..."
    response=$(curl -s -X POST "$SUPABASE_URL/functions/v1/local-llm-manifest" \
        -H "Content-Type: application/json" \
        -d '{"platform": "macos", "tier": "llama8b"}' || echo "ERROR")
    
    if echo "$response" | grep -q "payload_b64"; then
        echo -e "${GREEN}✓ Manifest endpoint working${NC}"
        echo "Response contains manifest data"
    elif echo "$response" | grep -q "error"; then
        echo -e "${RED}✗ Manifest endpoint returned error${NC}"
        echo "Response: $response"
    else
        echo -e "${YELLOW}⚠ Unexpected response${NC}"
        echo "Response: $response"
    fi
fi

echo ""

# Test 3: Check storage bucket
echo -e "${YELLOW}Test 3: Checking Storage Bucket${NC}"
echo "--------------------------------"

if [ $SKIP_CLI -eq 0 ]; then
    echo "Checking if bucket exists..."
    # This would require Supabase CLI storage commands
    echo -e "${YELLOW}⚠ Manual check required${NC}"
    echo "Verify in Supabase Dashboard: Storage → Buckets → local-llm-models"
else
    echo -e "${YELLOW}⚠ Skipped (CLI not available)${NC}"
    echo "Check manually in Supabase Dashboard"
fi

echo ""

# Test 4: Verify model files
echo -e "${YELLOW}Test 4: Checking Local Model Files${NC}"
echo "--------------------------------"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MODELS_DIR="$PROJECT_ROOT/models/macos"

if [ -f "$MODELS_DIR/llama-3.1-8b-instruct-coreml.zip" ]; then
    echo -e "${GREEN}✓ CoreML model found${NC}"
    size=$(stat -f%z "$MODELS_DIR/llama-3.1-8b-instruct-coreml.zip" 2>/dev/null || echo "unknown")
    echo "  Size: $size bytes"
else
    echo -e "${YELLOW}⚠ CoreML model not found locally${NC}"
    echo "  (This is OK if you're uploading directly)"
fi

if [ -f "$MODELS_DIR/llama-3.1-8b-instruct.gguf" ]; then
    echo -e "${GREEN}✓ GGUF model found${NC}"
    size=$(stat -f%z "$MODELS_DIR/llama-3.1-8b-instruct.gguf" 2>/dev/null || echo "unknown")
    echo "  Size: $size bytes"
else
    echo -e "${YELLOW}⚠ GGUF model not found locally${NC}"
    echo "  (Optional - only needed for Intel Macs)"
fi

echo ""

# Summary
echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo "══════════════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "  1. Fix any issues found above"
echo "  2. Test in app on macOS"
echo "  3. Verify model download and activation"
echo "  4. Test AI chat functionality"
echo ""
echo "For detailed setup instructions, see:"
echo "  docs/macos_llm_integration/OPERATIONAL_SETUP_GUIDE.md"
echo ""

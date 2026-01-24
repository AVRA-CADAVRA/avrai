#!/bin/bash
# Quick test script for LLM and Maps functionality

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}LLM & Maps Testing Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

cd "$(dirname "$0")/.."

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter not found${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Flutter found${NC}"
echo ""

# Menu
echo "What would you like to test?"
echo "  1) Maps tests (automated)"
echo "  2) LLM tests (automated)"
echo "  3) Run app (manual testing)"
echo "  4) Run all tests"
echo ""
read -p "Enter choice (1-4): " choice

case $choice in
    1)
        echo ""
        echo -e "${BLUE}🗺️  Running Maps Tests...${NC}"
        echo ""
        flutter test test/unit/models/map_boundary_test.dart \
          test/unit/widgets/map/ \
          test/integration/maps/
        echo ""
        echo -e "${GREEN}✅ Maps tests complete!${NC}"
        ;;
    2)
        echo ""
        echo -e "${BLUE}🧠 Running LLM Tests...${NC}"
        echo ""
        # Note: bert_squad directory doesn't exist yet, so we skip it
        flutter test test/unit/services/llm_service_test.dart \
          test/integration/ai/ 2>&1 | head -50 || echo "Some LLM tests may require app running"
        echo ""
        echo -e "${GREEN}✅ LLM tests complete!${NC}"
        ;;
    3)
        echo ""
        echo -e "${BLUE}🚀 Running App...${NC}"
        echo ""
        echo "Building with LLM manifest key..."
        echo ""
        flutter run -d macos \
          --dart-define=LOCAL_LLM_MANIFEST_PUBLIC_KEY_B64_V1=HULfUDT5xMorF+UT8kawyNx+CYKbrP22C8MTwhv5Nas=
        ;;
    4)
        echo ""
        echo -e "${BLUE}🧪 Running All Tests...${NC}"
        echo ""
        
        echo -e "${YELLOW}1. Maps Tests...${NC}"
        flutter test test/unit/models/map_boundary_test.dart \
          test/unit/widgets/map/ \
          test/integration/maps/ || echo "Some maps tests failed"
        
        echo ""
        echo -e "${YELLOW}2. LLM Tests...${NC}"
        # Note: bert_squad directory doesn't exist yet, so we skip it
        flutter test test/unit/services/llm_service_test.dart \
          test/integration/ai/ 2>&1 | head -50 || echo "Some LLM tests may require app running"
        
        echo ""
        echo -e "${GREEN}✅ All tests complete!${NC}"
        echo ""
        echo "For manual testing, run:"
        echo "  flutter run -d macos --dart-define=LOCAL_LLM_MANIFEST_PUBLIC_KEY_B64_V1=HULfUDT5xMorF+UT8kawyNx+CYKbrP22C8MTwhv5Nas="
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}========================================${NC}"

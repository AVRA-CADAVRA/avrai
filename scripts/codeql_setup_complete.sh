#!/bin/bash

# Complete CodeQL Setup Script
# 1. Cleans up corrupted databases
# 2. Sets up Rust analysis database
# 3. Provides guidance for Dart database (auto-created by extension)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}     CodeQL Complete Setup for AVRAI Project${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Step 1: Cleanup corrupted databases
echo -e "${BLUE}Step 1: Cleaning up corrupted CodeQL databases...${NC}"
echo ""
"$SCRIPT_DIR/codeql_cleanup.sh"
CLEANUP_EXIT=$?

if [ $CLEANUP_EXIT -ne 0 ]; then
    echo -e "${YELLOW}⚠️  Cleanup had issues, but continuing...${NC}"
fi

echo ""
echo -e "${CYAN}───────────────────────────────────────────────────────${NC}"
echo ""

# Step 2: Setup Rust database
echo -e "${BLUE}Step 2: Setting up Rust CodeQL database...${NC}"
echo ""
"$SCRIPT_DIR/codeql_setup_rust.sh"
RUST_SETUP_EXIT=$?

if [ $RUST_SETUP_EXIT -ne 0 ]; then
    echo -e "${YELLOW}⚠️  Rust database setup had issues${NC}"
    echo "You can run it manually later with: ./scripts/codeql_setup_rust.sh"
fi

echo ""
echo -e "${CYAN}───────────────────────────────────────────────────────${NC}"
echo ""

# Step 3: Dart database info
echo -e "${BLUE}Step 3: Dart Database Information${NC}"
echo ""
echo -e "${GREEN}✓ Dart database will be auto-created by CodeQL extension${NC}"
echo ""
echo "The CodeQL extension in Cursor will automatically create a Dart database"
echo "when you:"
echo "  • Open Dart files in your project"
echo "  • Run CodeQL queries"
echo "  • Use the CodeQL extension features"
echo ""
echo -e "${YELLOW}To manually trigger Dart database creation:${NC}"
echo "1. Open Command Palette (Cmd+Shift+P)"
echo "2. Run: 'CodeQL: Create Database'"
echo "3. Select language: 'Dart'"
echo "4. Select source root: Your project root"
echo ""

# Summary
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}                    Setup Summary${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo ""

if [ $CLEANUP_EXIT -eq 0 ]; then
    echo -e "${GREEN}✓ Cleanup: Complete${NC}"
else
    echo -e "${YELLOW}⚠️  Cleanup: Had issues (check output above)${NC}"
fi

if [ $RUST_SETUP_EXIT -eq 0 ]; then
    echo -e "${GREEN}✓ Rust Database: Created${NC}"
else
    echo -e "${YELLOW}⚠️  Rust Database: Not created (run codeql_setup_rust.sh manually)${NC}"
fi

echo -e "${GREEN}✓ Dart Database: Will be auto-created by extension${NC}"
echo ""

echo -e "${BLUE}Next Steps:${NC}"
echo "1. Reload CodeQL extension in Cursor (or restart Cursor)"
echo "2. The extension will create Dart database automatically"
echo "3. Use CodeQL queries to analyze your code"
echo ""
echo -e "${YELLOW}Useful CodeQL Commands:${NC}"
echo "  • Cleanup only:     ./scripts/codeql_cleanup.sh"
echo "  • Rust setup only:  ./scripts/codeql_setup_rust.sh"
echo "  • Full setup:       ./scripts/codeql_setup_complete.sh (this script)"
echo ""

echo -e "${CYAN}Setup complete!${NC}"

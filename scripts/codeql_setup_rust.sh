#!/bin/bash

# CodeQL Rust Database Setup Script
# Creates a CodeQL database for Rust code analysis
# This enables security and code quality analysis for native Rust code

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}CodeQL Rust Database Setup Script${NC}"
echo "======================================"
echo ""

# Get project root (assuming script is in scripts/ directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RUST_SOURCE_DIR="$PROJECT_ROOT/native"

# Check if CodeQL CLI is available
CODEQL_CMD=""
if command -v codeql &> /dev/null; then
    CODEQL_CMD="codeql"
else
    # Try to find CodeQL CLI in Cursor extension directory
    CURSOR_CODEQL=$(find "$HOME/Library/Application Support/Cursor/User/globalStorage/github.vscode-codeql" -name "codeql" -type f 2>/dev/null | head -1)
    if [ -n "$CURSOR_CODEQL" ] && [ -x "$CURSOR_CODEQL" ]; then
        CODEQL_CMD="$CURSOR_CODEQL"
        echo -e "${YELLOW}Found CodeQL CLI in Cursor extension directory${NC}"
    else
        echo -e "${RED}Error: CodeQL CLI not found${NC}"
        echo ""
        echo "Please install CodeQL CLI:"
        echo "  1. Download from: https://github.com/github/codeql-cli-binaries/releases"
        echo "  2. Extract and add to PATH"
        echo "  3. Or use: brew install codeql (if using Homebrew)"
        echo ""
        echo "Alternatively, the CodeQL extension in Cursor should have CodeQL CLI."
        echo "Check: ~/Library/Application Support/Cursor/User/globalStorage/github.vscode-codeql/distribution*/codeql"
        exit 1
    fi
fi

echo -e "${GREEN}✓ CodeQL CLI found: $CODEQL_CMD${NC}"
echo "  Version: $("$CODEQL_CMD" version --format=json 2>/dev/null | grep -o '"version":"[^"]*"' | head -1 || echo 'unknown')"
echo ""

# Check if Rust source directory exists
if [ ! -d "$RUST_SOURCE_DIR" ]; then
    echo -e "${RED}Error: Rust source directory not found${NC}"
    echo "Expected: $RUST_SOURCE_DIR"
    exit 1
fi

echo -e "${GREEN}✓ Rust source directory found: $RUST_SOURCE_DIR${NC}"
echo ""

# Find Rust projects (directories with Cargo.toml)
RUST_PROJECTS=$(find "$RUST_SOURCE_DIR" -name "Cargo.toml" -type f 2>/dev/null | head -5)

if [ -z "$RUST_PROJECTS" ]; then
    echo -e "${YELLOW}⚠️  No Rust projects (Cargo.toml) found in $RUST_SOURCE_DIR${NC}"
    echo "This is okay if you haven't set up Rust projects yet."
    exit 0
fi

echo -e "${BLUE}Found Rust projects:${NC}"
echo "$RUST_PROJECTS" | while read -r cargo_file; do
    project_dir=$(dirname "$cargo_file")
    echo "  - $project_dir"
done
echo ""

# Set database output directory
DB_OUTPUT_DIR="$PROJECT_ROOT/.codeql-databases"
RUST_DB_DIR="$DB_OUTPUT_DIR/rust"

# Create output directory
mkdir -p "$DB_OUTPUT_DIR"

echo -e "${BLUE}Database Configuration:${NC}"
echo "  Source: $RUST_SOURCE_DIR"
echo "  Output: $RUST_DB_DIR"
echo ""

# Check if database already exists
if [ -d "$RUST_DB_DIR" ]; then
    echo -e "${YELLOW}⚠️  Rust database already exists at: $RUST_DB_DIR${NC}"
    read -p "Do you want to recreate it? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Removing existing database..."
        rm -rf "$RUST_DB_DIR"
    else
        echo "Using existing database."
        exit 0
    fi
fi

echo -e "${BLUE}Creating CodeQL database for Rust...${NC}"
echo "This may take several minutes depending on codebase size."
echo ""

# Create the database
# Note: CodeQL Rust support requires the code to be buildable
# We'll try to build it first to ensure dependencies are available

cd "$RUST_SOURCE_DIR"

# Check if we can build (optional, but helps ensure database quality)
if command -v cargo &> /dev/null; then
    echo -e "${YELLOW}Checking Rust build environment...${NC}"
    if cargo --version &> /dev/null; then
        echo -e "${GREEN}✓ Cargo found: $(cargo --version)${NC}"
        echo ""
        echo -e "${YELLOW}Note: CodeQL will attempt to build your Rust code.${NC}"
        echo "If build fails, the database may be incomplete but still usable."
        echo ""
    fi
fi

# Create database
echo -e "${BLUE}Running: codeql database create${NC}"
"$CODEQL_CMD" database create "$RUST_DB_DIR" \
    --language=rust \
    --source-root="$RUST_SOURCE_DIR" \
    --command="echo 'CodeQL will analyze Rust code'" \
    || {
        echo ""
        echo -e "${YELLOW}Note: If the above failed, try building your Rust code first:${NC}"
        echo "  cd $RUST_SOURCE_DIR"
        echo "  cargo build"
        echo ""
        echo "Then run this script again, or manually create the database:"
        echo "  \"$CODEQL_CMD\" database create \"$RUST_DB_DIR\" --language=rust --source-root=\"$RUST_SOURCE_DIR\""
        exit 1
    }

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Rust CodeQL database created successfully!${NC}"
    echo ""
    echo -e "${BLUE}Database location: $RUST_DB_DIR${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. The database is ready for analysis"
    echo "2. You can run queries using CodeQL CLI:"
    echo "   codeql query run <query.ql> --database=$RUST_DB_DIR"
    echo "3. Or use the CodeQL extension in Cursor to open this database"
    echo ""
    echo -e "${BLUE}To open in CodeQL extension:${NC}"
    echo "1. Open Command Palette (Cmd+Shift+P)"
    echo "2. Run: 'CodeQL: Choose Database'"
    echo "3. Select: $RUST_DB_DIR"
    echo ""
    echo -e "${BLUE}CodeQL CLI used: \"$CODEQL_CMD\"${NC}"
    echo ""
else
    echo -e "${RED}✗ Failed to create database${NC}"
    exit 1
fi

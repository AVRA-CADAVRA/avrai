#!/bin/bash

# CodeQL Database Cleanup Script
# Removes corrupted CodeQL databases that contain ambiguous datasets
# This fixes the "contains ambiguous datasets" error in CodeQL extension

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}CodeQL Database Cleanup Script${NC}"
echo "=================================="
echo ""

# Find Cursor workspace storage directory
CURSOR_STORAGE_BASE="$HOME/Library/Application Support/Cursor/User/workspaceStorage"

if [ ! -d "$CURSOR_STORAGE_BASE" ]; then
    echo -e "${RED}Error: Cursor workspace storage directory not found${NC}"
    echo "Expected: $CURSOR_STORAGE_BASE"
    exit 1
fi

echo "Searching for CodeQL databases in Cursor workspace storage..."
echo ""

# Find all codeql_db directories
FOUND_DBS=$(find "$CURSOR_STORAGE_BASE" -type d -name "codeql_db" 2>/dev/null || true)

if [ -z "$FOUND_DBS" ]; then
    echo -e "${GREEN}No CodeQL databases found. Nothing to clean up.${NC}"
    exit 0
fi

echo -e "${YELLOW}Found CodeQL databases:${NC}"
echo "$FOUND_DBS" | while read -r db_path; do
    echo "  - $db_path"
done
echo ""

# Check for ambiguous datasets (multiple db-* directories)
AMBIGUOUS_DBS=()
while IFS= read -r db_path; do
    # Count dataset directories (db-java, db-javascript, etc.)
    DATASET_COUNT=$(find "$db_path" -maxdepth 1 -type d -name "db-*" 2>/dev/null | wc -l | tr -d ' ')
    
    if [ "$DATASET_COUNT" -gt 1 ]; then
        AMBIGUOUS_DBS+=("$db_path")
        echo -e "${RED}⚠️  Ambiguous database found: $db_path${NC}"
        echo "   Contains $DATASET_COUNT datasets:"
        find "$db_path" -maxdepth 1 -type d -name "db-*" 2>/dev/null | while read -r dataset; do
            echo "     - $(basename "$dataset")"
        done
    fi
done <<< "$FOUND_DBS"

echo ""

if [ ${#AMBIGUOUS_DBS[@]} -eq 0 ]; then
    echo -e "${GREEN}No ambiguous databases found. All databases are clean.${NC}"
    exit 0
fi

echo -e "${YELLOW}Found ${#AMBIGUOUS_DBS[@]} ambiguous database(s)${NC}"
echo ""
read -p "Do you want to delete these corrupted databases? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

# Delete ambiguous databases
DELETED_COUNT=0
for db_path in "${AMBIGUOUS_DBS[@]}"; do
    echo -e "${YELLOW}Deleting: $db_path${NC}"
    rm -rf "$db_path"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Deleted successfully${NC}"
        ((DELETED_COUNT++))
    else
        echo -e "${RED}✗ Failed to delete${NC}"
    fi
done

echo ""
echo -e "${GREEN}Cleanup complete!${NC}"
echo "Deleted $DELETED_COUNT database(s)."
echo ""
echo "The CodeQL extension will automatically recreate databases when needed."
echo "You may need to reload the CodeQL extension or restart Cursor."

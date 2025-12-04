#!/bin/bash

# Cleanup Legacy Scripts and Backup Directories
# Removes legacy scripts and backup directories that cause Gradle issues
# Date: $(date +%Y-%m-%d)

set -e

echo "🧹 Cleaning up legacy scripts and backup directories..."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
log_info() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_action() {
    echo -e "${BLUE}→${NC} $1"
}

# 1. Check if we're in the SPOTS project root
if [ ! -f "pubspec.yaml" ]; then
    log_error "Must run from SPOTS project root directory"
    exit 1
fi

log_info "Found SPOTS project root"

# 2. Remove legacy scripts folder
if [ -d "scripts/legacy" ]; then
    log_action "Removing scripts/legacy/ directory..."
    rm -rf scripts/legacy/
    log_info "Removed scripts/legacy/ directory"
else
    log_info "No scripts/legacy/ directory found"
fi

# 3. Remove "final_*" scripts (one-time fixes that are no longer needed)
log_action "Checking for legacy 'final_*' scripts..."

FINAL_SCRIPTS=(
    "scripts/final_android_fix.sh"
    "scripts/final_cleanup_fix.sh"
    "scripts/final_comprehensive_fix.sh"
    "scripts/final_error_fixes.sh"
    "scripts/final_fixes.sh"
    "scripts/quick_final_fix.sh"
)

REMOVED_COUNT=0
for script in "${FINAL_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        log_action "Removing $script..."
        rm -f "$script"
        REMOVED_COUNT=$((REMOVED_COUNT + 1))
    fi
done

if [ $REMOVED_COUNT -gt 0 ]; then
    log_info "Removed $REMOVED_COUNT legacy 'final_*' scripts"
else
    log_info "No legacy 'final_*' scripts found"
fi

# 4. Remove backup directories
log_action "Checking for backup directories..."

BACKUP_DIRS=$(find . -maxdepth 2 -type d -name "backups" 2>/dev/null)
if [ -n "$BACKUP_DIRS" ]; then
    echo "$BACKUP_DIRS" | while read backup_dir; do
        if [ -d "$backup_dir" ]; then
            SIZE=$(du -sh "$backup_dir" 2>/dev/null | cut -f1)
            log_warn "Found backup directory: $backup_dir ($SIZE)"
            log_action "Removing $backup_dir..."
            rm -rf "$backup_dir"
            log_info "Removed $backup_dir"
        fi
    done
else
    log_info "No backup directories found"
fi

# 5. Check for any nested backup directories
log_action "Checking for nested backup directories..."

NESTED_BACKUPS=$(find . -type d -path "*/backups/*" 2>/dev/null | grep -v ".git")
if [ -n "$NESTED_BACKUPS" ]; then
    echo "$NESTED_BACKUPS" | while read backup_dir; do
        SIZE=$(du -sh "$backup_dir" 2>/dev/null | cut -f1)
        log_warn "Found nested backup: $backup_dir ($SIZE)"
        log_action "Removing $backup_dir..."
        rm -rf "$backup_dir"
        log_info "Removed $backup_dir"
    done
else
    log_info "No nested backup directories found"
fi

# 6. Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Cleanup Complete!"
echo ""
echo "Removed:"
echo "  - Legacy scripts directory (scripts/legacy/)"
echo "  - Legacy 'final_*' scripts ($REMOVED_COUNT scripts)"
echo "  - Backup directories (if any were found)"
echo ""
echo "Next steps:"
echo "  1. In Android Studio/IntelliJ: File → Invalidate Caches / Restart"
echo "  2. Close and reopen the project"
echo "  3. Run: flutter clean && flutter pub get"
echo "  4. Try building again: flutter build apk --debug"
echo ""
echo "The Gradle duplicate project name error should now be resolved!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"


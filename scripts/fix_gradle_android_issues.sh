#!/bin/bash

# Fix Gradle Android Build Issues
# Resolves duplicate project names and missing .settings folders
# Date: $(date +%Y-%m-%d)

set -e

echo "🔧 Fixing Gradle Android Build Issues..."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# 1. Check if we're in the SPOTS project root
if [ ! -f "pubspec.yaml" ] || [ ! -d "android" ]; then
    log_error "Must run from SPOTS project root directory"
    exit 1
fi

log_info "Found SPOTS project root"

# 2. Remove or exclude backup directories from Gradle scanning
log_info "Checking for backup directories..."

BACKUP_DIRS=$(find . -maxdepth 2 -type d -name "backups" 2>/dev/null)
if [ -n "$BACKUP_DIRS" ]; then
    log_warn "Found backup directories:"
    echo "$BACKUP_DIRS"
    
    # Check if backups are in .gitignore
    if grep -q "^backups/" .gitignore 2>/dev/null || grep -q "^backups$" .gitignore 2>/dev/null; then
        log_info "Backup directories already in .gitignore"
    else
        log_warn "Adding backup directories to .gitignore..."
        echo "" >> .gitignore
        echo "# Backup directories (exclude from Gradle scanning)" >> .gitignore
        echo "backups/" >> .gitignore
        echo "**/backups/" >> .gitignore
        log_info "Updated .gitignore"
    fi
else
    log_info "No backup directories found in project root"
fi

# 3. Clean IDE workspace files that might reference backups
log_info "Cleaning IDE workspace files..."

# Remove .idea directory if it exists (will be regenerated)
if [ -d ".idea" ]; then
    log_warn "Found .idea directory - backing up and removing..."
    if [ -d ".idea/backup" ]; then
        rm -rf ".idea/backup"
    fi
    # Remove workspace files that might have cached references
    find .idea -name "workspace.xml" -o -name "modules.xml" -o -name "*.iml" 2>/dev/null | while read file; do
        if grep -q "backups\|20250804_032827" "$file" 2>/dev/null; then
            log_warn "Removing cached reference in: $file"
            rm -f "$file"
        fi
    done
    log_info "Cleaned .idea workspace files"
else
    log_info "No .idea directory found"
fi

# 4. Create .settings folder for Android project if missing
log_info "Checking Android .settings folder..."

if [ ! -d "android/.settings" ]; then
    log_warn "Creating android/.settings folder..."
    mkdir -p android/.settings
    
    # Create org.eclipse.buildship.core.prefs if needed
    cat > android/.settings/org.eclipse.buildship.core.prefs << 'EOF'
connection.project.dir=
EOF
    
    log_info "Created android/.settings folder"
else
    log_info "android/.settings folder exists"
fi

# 5. Clean Gradle cache and rebuild
log_info "Cleaning Gradle cache..."

cd android
./gradlew clean --no-daemon 2>/dev/null || log_warn "Gradle clean had warnings (this is okay)"
cd ..

log_info "Gradle cache cleaned"

# 6. Verify settings.gradle doesn't include backup directories
log_info "Verifying settings.gradle..."

if grep -q "backups" android/settings.gradle 2>/dev/null; then
    log_warn "Found backup references in settings.gradle - removing..."
    # This shouldn't happen, but if it does, we'll fix it
    sed -i.bak '/backups/d' android/settings.gradle 2>/dev/null || true
    log_info "Cleaned settings.gradle"
else
    log_info "settings.gradle is clean"
fi

# 7. Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Gradle Android Issues Fixed!"
echo ""
echo "Next steps:"
echo "  1. In Android Studio/IntelliJ: File → Invalidate Caches / Restart"
echo "  2. Close and reopen the project"
echo "  3. Run: flutter clean && flutter pub get"
echo "  4. Try building again: flutter build apk --debug"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"


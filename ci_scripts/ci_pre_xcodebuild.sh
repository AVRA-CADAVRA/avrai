#!/bin/bash
set -e

echo "🔧 Applying Xcode 16.2 workaround..."

# Create module cache directory (Xcode 16.2 bug workaround)
# This fixes: "no such file or directory: Session.modulevalidation"
MODULE_CACHE_DIR="$HOME/Library/Developer/Xcode/DerivedData/ModuleCache.noindex"
mkdir -p "$MODULE_CACHE_DIR"
chmod 755 "$MODULE_CACHE_DIR"

if [ ! -f "$MODULE_CACHE_DIR/Session.modulevalidation" ]; then
    touch "$MODULE_CACHE_DIR/Session.modulevalidation"
    chmod 644 "$MODULE_CACHE_DIR/Session.modulevalidation"
    echo "✅ Created Session.modulevalidation file"
else
    echo "✅ Session.modulevalidation already exists"
fi

# Create SDK stat cache directory
SDK_CACHE_DIR="$HOME/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex"
mkdir -p "$SDK_CACHE_DIR"
chmod 755 "$SDK_CACHE_DIR"

echo "✅ Module cache directories created"
echo "✅ Xcode 16.2 workaround applied"

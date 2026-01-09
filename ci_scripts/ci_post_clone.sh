#!/bin/bash
# Don't use set -e initially - we want to see all errors
set -x  # Enable debug output to see every command

echo "🚀 Starting Flutter setup for Xcode Cloud..."
echo "📂 Current directory: $(pwd)"
echo "📂 CI_WORKSPACE: ${CI_WORKSPACE:-NOT SET}"
echo "📂 HOME: $HOME"

# Find the repository root (where ci_scripts directory is)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
echo "📂 Script directory: $SCRIPT_DIR"
echo "📂 Repository root: $REPO_ROOT"

# Use repository root as working directory
cd "$REPO_ROOT"
echo "📂 Changed to: $(pwd)"

# Verify we're in the right place
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found. Wrong directory?"
    echo "📂 Contents of current directory:"
    ls -la
    exit 1
fi

echo "✅ Found pubspec.yaml - we're in the right directory"

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "📥 Flutter not found. Installing Flutter from GitHub..."
    
    # Install Flutter using git (stable channel)
    if [ ! -d "$HOME/flutter" ]; then
        echo "📦 Cloning Flutter repository..."
        git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter" || {
            echo "❌ Error: Failed to clone Flutter"
            exit 1
        }
    else
        echo "✅ Flutter directory exists, updating..."
        cd "$HOME/flutter"
        git pull || echo "⚠️  git pull failed, continuing..."
        cd "$REPO_ROOT"
    fi
    
    # Add Flutter to PATH
    export PATH="$HOME/flutter/bin:$PATH"
    
    # Verify Flutter is now available
    if ! command -v flutter &> /dev/null; then
        echo "❌ Error: Flutter installation failed - flutter command still not found"
        echo "📂 Checking if Flutter exists:"
        ls -la "$HOME/flutter/bin/flutter" || echo "Flutter binary not found"
        exit 1
    fi
    
    echo "✅ Flutter installed successfully"
else
    echo "✅ Flutter found in PATH"
    export PATH="$HOME/flutter/bin:${PATH:-}"
fi

# Verify Flutter version
FLUTTER_VERSION=$(flutter --version | head -n 1)
echo "✅ Flutter version: $FLUTTER_VERSION"

# Accept Flutter licenses (non-blocking)
echo "📝 Accepting Flutter licenses..."
flutter doctor --android-licenses 2>/dev/null || echo "⚠️  Android licenses skipped (iOS build only)"

# Pre-cache Flutter dependencies (non-blocking)
echo "📦 Pre-caching Flutter dependencies..."
flutter precache --ios 2>&1 || echo "⚠️  Pre-cache warning (continuing...)"

# Get Flutter dependencies (creates Generated.xcconfig)
echo "📦 Running flutter pub get..."
echo "📂 Current directory before flutter pub get: $(pwd)"
flutter pub get || {
    echo "❌ Error: flutter pub get failed"
    exit 1
}

# Verify Generated.xcconfig was created (use absolute path)
GENERATED_XCCONFIG="$REPO_ROOT/ios/Flutter/Generated.xcconfig"
echo "📂 Looking for Generated.xcconfig at: $GENERATED_XCCONFIG"

if [ ! -f "$GENERATED_XCCONFIG" ]; then
    echo "❌ Error: Generated.xcconfig not created by flutter pub get"
    echo "📂 Checking ios/Flutter directory:"
    ls -la ios/Flutter/ 2>&1 || echo "ios/Flutter directory doesn't exist"
    echo "📂 Checking ios directory:"
    ls -la ios/ 2>&1
    exit 1
fi

echo "✅ Generated.xcconfig created at: $GENERATED_XCCONFIG"
echo "📄 Generated.xcconfig contents (first 10 lines):"
head -10 "$GENERATED_XCCONFIG" || true

# Install CocoaPods dependencies
echo "📦 Installing CocoaPods dependencies..."
cd "$REPO_ROOT/ios"
echo "📂 Changed to iOS directory: $(pwd)"

# Check if pod is available
if ! command -v pod &> /dev/null; then
    echo "📥 CocoaPods not found. Installing CocoaPods..."
    
    if ! command -v gem &> /dev/null; then
        echo "❌ Error: gem (Ruby) not found. CocoaPods requires Ruby."
        exit 1
    fi
    
    echo "📦 Installing CocoaPods via gem..."
    gem install cocoapods --no-document || {
        echo "⚠️  gem install cocoapods failed, trying with sudo..."
        sudo gem install cocoapods --no-document || {
            echo "❌ Error: CocoaPods installation failed"
            exit 1
        }
    }
    
    echo "✅ CocoaPods installed successfully"
else
    echo "✅ CocoaPods found in PATH"
fi

# Run pod install
echo "📦 Running pod install..."
pod install --repo-update || pod install || {
    echo "❌ Error: pod install failed"
    echo "📂 Checking Podfile:"
    cat Podfile || true
    exit 1
}

cd "$REPO_ROOT"

# Verify Pods directory was created
if [ ! -d "ios/Pods" ]; then
    echo "❌ Error: Pods directory not created by pod install"
    echo "📂 Checking ios directory contents:"
    ls -la ios/ 2>&1
    exit 1
fi

echo "✅ CocoaPods dependencies installed"
echo "📂 Pods directory exists: ios/Pods"

# Verify Pods file lists exist
echo "📂 Verifying Pods file lists..."
if [ -f "ios/Pods/Target Support Files/Pods-Runner/Pods-Runner-frameworks-Release-input-files.xcfilelist" ]; then
    echo "✅ Pods file lists created successfully"
else
    echo "⚠️  Warning: Some Pods file lists not found, but Pods directory exists"
    echo "📂 Checking Target Support Files:"
    ls -la "ios/Pods/Target Support Files/Pods-Runner/" 2>&1 || true
fi

echo "✅ Flutter setup complete!"
echo "📂 Final verification - files that should exist:"
echo "  - Generated.xcconfig: $([ -f "$GENERATED_XCCONFIG" ] && echo "✅ EXISTS" || echo "❌ MISSING")"
echo "  - Pods directory: $([ -d "ios/Pods" ] && echo "✅ EXISTS" || echo "❌ MISSING")"
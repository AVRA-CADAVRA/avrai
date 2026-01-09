#!/bin/bash
set -e

echo "🚀 Starting Flutter setup for Xcode Cloud..."

# Check if Flutter is available (Xcode Cloud may have it pre-installed)
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Attempting to install Flutter..."
    
    # Check if Flutter SDK is in common locations
    FLUTTER_PATHS=(
        "$HOME/flutter/bin/flutter"
        "/usr/local/bin/flutter"
        "/opt/flutter/bin/flutter"
    )
    
    FLUTTER_FOUND=false
    for FLUTTER_PATH in "${FLUTTER_PATHS[@]}"; do
        if [ -f "$FLUTTER_PATH" ]; then
            echo "✅ Found Flutter at: $FLUTTER_PATH"
            export PATH="$(dirname "$FLUTTER_PATH"):$PATH"
            FLUTTER_FOUND=true
            break
        fi
    done
    
    if [ "$FLUTTER_FOUND" = false ]; then
        echo "⚠️  Flutter not found in common locations."
        echo "Please ensure Flutter is installed and available in PATH."
        echo "Xcode Cloud may need Flutter configured in workflow settings."
        exit 1
    fi
fi

echo "✅ Flutter found: $(flutter --version | head -n 1)"

# Get Flutter dependencies (creates Generated.xcconfig)
echo "📦 Running flutter pub get..."
flutter pub get

# Verify Generated.xcconfig was created
if [ ! -f "ios/Flutter/Generated.xcconfig" ]; then
    echo "❌ Error: Generated.xcconfig not created by flutter pub get"
    echo "Flutter dependencies may not have been set up correctly."
    exit 1
fi

echo "✅ Generated.xcconfig created"

# Install CocoaPods dependencies
echo "📦 Installing CocoaPods dependencies..."
cd ios

# Check if pod is available
if ! command -v pod &> /dev/null; then
    echo "❌ CocoaPods not found. Attempting to install..."
    if command -v gem &> /dev/null; then
        gem install cocoapods
    else
        echo "⚠️  gem not found. CocoaPods may need to be pre-installed."
        exit 1
    fi
fi

pod install
cd ..

# Verify Pods directory was created
if [ ! -d "ios/Pods" ]; then
    echo "❌ Error: Pods directory not created by pod install"
    echo "CocoaPods installation may have failed."
    exit 1
fi

echo "✅ CocoaPods dependencies installed"
echo "✅ Flutter setup complete!"

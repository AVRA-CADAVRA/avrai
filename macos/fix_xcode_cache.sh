#!/bin/bash
# Workaround script for Xcode 16.2+ module cache bug (macOS)
# Run this before building macOS

echo "Fixing Xcode module cache issues for macOS..."

# Create module cache directory
mkdir -p ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex
chmod 755 ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex

# Create Session.modulevalidation file
touch ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex/Session.modulevalidation
chmod 644 ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex/Session.modulevalidation

# Create SDK stat cache directory
mkdir -p ~/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex
chmod 755 ~/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex

echo "✅ Cache files created. Try building again."

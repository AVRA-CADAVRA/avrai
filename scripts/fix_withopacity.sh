#!/bin/bash

# Fix withOpacity deprecation - Replace with withValues(alpha:)
# Date: December 2, 2025

echo "Fixing withOpacity deprecations across all Dart files..."

# Find all Dart files with withOpacity
files=$(find lib -name "*.dart" -type f -exec grep -l "withOpacity(" {} \;)

total_files=$(echo "$files" | wc -l | tr -d ' ')
current=0

echo "Found $total_files files with withOpacity usage"

for file in $files; do
  current=$((current + 1))
  echo "[$current/$total_files] Processing: $file"
  
  # Use sed to replace all instances
  # Pattern: .withOpacity(0.1) -> .withValues(alpha: 0.1)
  # Pattern: .withOpacity(0.3) -> .withValues(alpha: 0.3)
  # etc.
  
  # Replace all numeric opacity values
  sed -i '' 's/\.withOpacity(\([0-9.]*\))/.withValues(alpha: \1)/g' "$file"
done

echo "Done! Fixed all withOpacity deprecations."


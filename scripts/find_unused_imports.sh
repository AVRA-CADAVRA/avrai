#!/bin/bash

# Find all unused imports across the codebase
# This script extracts unused import warnings from flutter analyze

echo "Analyzing codebase for unused imports..."
echo ""

# Run flutter analyze and extract unused import warnings
flutter analyze --no-fatal-infos 2>&1 | grep -i "unused import" | while read -r line; do
  # Extract file path and line number
  file=$(echo "$line" | sed -n 's/.*• \(.*\):.*/\1/p')
  line_num=$(echo "$line" | sed -n 's/.*:\([0-9]*\):.*/\1/p')
  import_name=$(echo "$line" | sed -n "s/.*'\(.*\)'.*/\1/p")
  
  if [ -n "$file" ] && [ -n "$line_num" ] && [ -n "$import_name" ]; then
    echo "$file|$line_num|$import_name"
  fi
done | sort -u > /tmp/unused_imports.txt

echo "Found $(wc -l < /tmp/unused_imports.txt | tr -d ' ') unused imports"
echo ""
echo "Results saved to /tmp/unused_imports.txt"
echo ""
echo "Sample results:"
head -10 /tmp/unused_imports.txt


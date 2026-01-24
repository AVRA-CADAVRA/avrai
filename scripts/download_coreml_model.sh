#!/bin/bash
# Download pre-converted CoreML model from HuggingFace
# Model: andmev/Llama-3.1-8B-Instruct-CoreML

set -e

MODEL_REPO="andmev/Llama-3.1-8B-Instruct-CoreML"
MODEL_FILE="llama_3.1_coreml.mlpackage"
OUTPUT_DIR="./models/macos"
ZIP_NAME="llama-3.1-8b-instruct-coreml.zip"

echo "📦 Downloading CoreML model from HuggingFace"
echo "   Repository: $MODEL_REPO"
echo "   File: $MODEL_FILE"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Check if HuggingFace CLI is available
if command -v huggingface-cli &> /dev/null; then
    echo "✅ Using HuggingFace CLI"
    echo ""
    echo "Downloading model..."
    huggingface-cli download "$MODEL_REPO" "$MODEL_FILE" --local-dir "$OUTPUT_DIR" --local-dir-use-symlinks False
    
    if [ -f "$OUTPUT_DIR/$MODEL_FILE" ]; then
        echo "✅ Model downloaded successfully"
    else
        echo "❌ Model file not found after download"
        exit 1
    fi
else
    echo "⚠️  HuggingFace CLI not found"
    echo ""
    echo "Install it with:"
    echo "  pip3 install huggingface-hub"
    echo ""
    echo "Or download manually:"
    echo "  1. Go to: https://huggingface.co/$MODEL_REPO/tree/main"
    echo "  2. Download: $MODEL_FILE"
    echo "  3. Place it in: $OUTPUT_DIR/"
    echo ""
    read -p "Press Enter after you've downloaded the model manually..."
    
    if [ ! -f "$OUTPUT_DIR/$MODEL_FILE" ]; then
        echo "❌ Model file not found at: $OUTPUT_DIR/$MODEL_FILE"
        exit 1
    fi
fi

# Package as ZIP
echo ""
echo "📦 Packaging model as ZIP..."
cd "$OUTPUT_DIR"

if [ -d "$MODEL_FILE" ]; then
    # It's a directory (mlpackage)
    zip -r "$ZIP_NAME" "$MODEL_FILE"
    echo "✅ Created: $ZIP_NAME"
elif [ -f "$MODEL_FILE" ]; then
    # It's a single file
    zip "$ZIP_NAME" "$MODEL_FILE"
    echo "✅ Created: $ZIP_NAME"
else
    echo "❌ Model file not found: $MODEL_FILE"
    exit 1
fi

cd - > /dev/null

# Calculate hash and size
echo ""
echo "📊 Calculating SHA-256 hash and file size..."
HASH=$(shasum -a 256 "$OUTPUT_DIR/$ZIP_NAME" | awk '{print $1}')
SIZE=$(stat -f%z "$OUTPUT_DIR/$ZIP_NAME")

echo ""
echo "✅ Model ready for upload!"
echo ""
echo "File: $OUTPUT_DIR/$ZIP_NAME"
echo "SHA-256: $HASH"
echo "Size: $SIZE bytes ($(echo "scale=2; $SIZE/1024/1024/1024" | bc) GB)"
echo ""
echo "Next steps:"
echo "  1. Upload to Supabase Storage: $OUTPUT_DIR/$ZIP_NAME"
echo "  2. Set secrets with these values:"
echo "     supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_URL=\"https://...\""
echo "     supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SHA256=\"$HASH\""
echo "     supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SIZE_BYTES=\"$SIZE\""

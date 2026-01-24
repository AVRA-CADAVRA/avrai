#!/bin/bash
# Run [llama-to-coreml](https://github.com/andmev/llama-to-coreml) to convert Llama models → CoreML.
# Supports: Llama 3.1/3.2, Llama 4 Scout/Maverick
# Output goes to models/macos; optionally ZIP for Supabase upload.
#
# Prereqs:
#   git clone https://github.com/andmev/llama-to-coreml.git
#   cd llama-to-coreml && pip install -e . && pip install -r requirements.txt
#
# Usage:
#   LLAMA_TO_COREML=/path/to/llama-to-coreml HF_TOKEN=your_token ./scripts/run_llama_to_coreml.sh
#   # Options:
#   MODEL=8B LLAMA_TO_COREML=... HF_TOKEN=... ./scripts/run_llama_to_coreml.sh  # Llama 3.1 8B
#   MODEL=3B LLAMA_TO_COREML=... HF_TOKEN=... ./scripts/run_llama_to_coreml.sh  # Llama 3.2 3B
#   MODEL=scout LLAMA_TO_COREML=... HF_TOKEN=... ./scripts/run_llama_to_coreml.sh  # Llama 4 Scout
#   MODEL=maverick LLAMA_TO_COREML=... HF_TOKEN=... ./scripts/run_llama_to_coreml.sh  # Llama 4 Maverick

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AVRAI_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MODELS_MACOS="$AVRAI_ROOT/models/macos"

# Load .env file if it exists (for HF_TOKEN)
if [[ -f "$AVRAI_ROOT/.env" ]]; then
  export $(grep -v '^#' "$AVRAI_ROOT/.env" | grep -E '^HF_TOKEN=' | xargs)
fi

LLAMA_TO_COREML="${LLAMA_TO_COREML:-}"
HF_TOKEN="${HF_TOKEN:-}"
MODEL="${MODEL:-8B}"   # 8B, 3B, scout, or maverick

if [[ -z "$LLAMA_TO_COREML" ]]; then
  echo "❌ LLAMA_TO_COREML not set."
  echo ""
  echo "Clone and set up llama-to-coreml first:"
  echo "  git clone https://github.com/andmev/llama-to-coreml.git"
  echo "  cd llama-to-coreml"
  echo "  pip install -e . && pip install -r requirements.txt"
  echo ""
  echo "Then run:"
  echo "  LLAMA_TO_COREML=/path/to/llama-to-coreml HF_TOKEN=your_token ./scripts/run_llama_to_coreml.sh"
  echo ""
  echo "Model options:"
  echo "  MODEL=8B      # Llama 3.1 8B Instruct (default)"
  echo "  MODEL=3B      # Llama 3.2 3B Instruct"
  echo "  MODEL=scout   # Llama 4 Scout (17B active, MoE)"
  echo "  MODEL=maverick # Llama 4 Maverick (17B active, 400B total, MoE)"
  exit 1
fi

if [[ ! -d "$LLAMA_TO_COREML" ]]; then
  echo "❌ Not a directory: $LLAMA_TO_COREML"
  exit 1
fi

mkdir -p "$MODELS_MACOS"

# Determine model path and output names based on MODEL variable
if [[ "$MODEL" == "3B" ]]; then
  MODEL_PATH="meta-llama/Llama-3.2-3B-Instruct"
  OUTPUT_NAME="Llama-3.2-3B-Instruct"
  ZIP_NAME="llama-3.2-3b-instruct-coreml.zip"
elif [[ "$MODEL" == "scout" ]]; then
  MODEL_PATH="meta-llama/Llama-4-Scout-Instruct"
  OUTPUT_NAME="Llama-4-Scout-Instruct"
  ZIP_NAME="llama-4-scout-instruct-coreml.zip"
elif [[ "$MODEL" == "maverick" ]]; then
  MODEL_PATH="meta-llama/Llama-4-Maverick-Instruct"
  OUTPUT_NAME="Llama-4-Maverick-Instruct"
  ZIP_NAME="llama-4-maverick-instruct-coreml.zip"
else
  # Default: 8B
  MODEL_PATH="meta-llama/Llama-3.1-8B-Instruct"
  OUTPUT_NAME="Llama-3.1-8B-Instruct"
  ZIP_NAME="llama-3.1-8b-instruct-coreml.zip"
fi

OUTPUT_MLP="$MODELS_MACOS/${OUTPUT_NAME}.mlpackage"

echo "📦 llama-to-coreml: $MODEL ($MODEL_PATH)"
echo "   Output: $OUTPUT_MLP"
echo ""

# Warn about Llama 4 MoE conversion if needed
if [[ "$MODEL" == "scout" || "$MODEL" == "maverick" ]]; then
  echo "⚠️  Note: Llama 4 uses Mixture of Experts (MoE) architecture."
  echo "   Conversion may fail if llama-to-coreml doesn't support MoE yet."
  echo "   If conversion fails, you may need to use coremltools directly."
  echo ""
fi

TOKEN_ARGS=""
if [[ -n "$HF_TOKEN" ]]; then
  TOKEN_ARGS="--token $HF_TOKEN"
fi

cd "$LLAMA_TO_COREML"

# Use Python from venv-llama if it exists, otherwise use system Python
if [[ -f "$LLAMA_TO_COREML/venv-llama/bin/python" ]]; then
  PYTHON_CMD="$LLAMA_TO_COREML/venv-llama/bin/python"
  echo "   Using Python 3.12 venv: $PYTHON_CMD"
else
  PYTHON_CMD="python"
  echo "   Using system Python: $PYTHON_CMD"
fi

$PYTHON_CMD -m scripts.convert_model \
  --model-path "$MODEL_PATH" \
  --output-path "$OUTPUT_MLP" \
  $TOKEN_ARGS \
  --compile

echo ""
echo "✅ Conversion done: $OUTPUT_MLP"
echo ""
echo "📦 Creating ZIP for Supabase..."
cd "$MODELS_MACOS"
zip -r "$ZIP_NAME" "${OUTPUT_NAME}.mlpackage"
echo "✅ Created: $MODELS_MACOS/$ZIP_NAME"
echo ""
echo "Next: compute hash/size, upload to Supabase, set secrets."
echo "  shasum -a 256 $ZIP_NAME"
echo "  stat -f%z $ZIP_NAME"
echo "  # Upload to bucket local-llm-models, then:"
echo "  supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_URL=\"...\""
echo "  supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SHA256=\"...\""
echo "  supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SIZE_BYTES=\"...\""

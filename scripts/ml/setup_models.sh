#!/bin/bash

# AVRAI ML Model Setup Script
# Handles model setup, verification, and registration for multiple models

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/../.."
PYTHON_SCRIPT="$SCRIPT_DIR/model_manager.py"
MODELS_DIR="$PROJECT_ROOT/assets/models"
EXPORT_SCRIPT="$SCRIPT_DIR/export_sample_onnx.py"

# Known models used by the app (in order of priority)
KNOWN_MODELS=(
    "calling_score_model.onnx"
    "outcome_prediction_model.onnx"
    "default.onnx"
)

# Model descriptions
declare -A MODEL_DESCRIPTIONS=(
    ["calling_score_model.onnx"]="Calling score neural network model (Phase 12) - predicts compatibility scores"
    ["outcome_prediction_model.onnx"]="Outcome prediction model (Phase 12) - predicts probability of positive outcomes"
    ["default.onnx"]="Default inference model for AI2AI system"
)

# Ensure script is executable
chmod +x "$PYTHON_SCRIPT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}==>${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

print_error() {
    echo -e "${RED}Error:${NC} $1"
}

verify_python() {
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is required but not installed."
        exit 1
    fi
}

verify_dependencies() {
    python3 -m pip install --quiet requests
}

# Verify and register existing model
verify_and_register_model() {
    local model_name="$1"
    local model_path="$MODELS_DIR/$model_name"
    
    if [ ! -f "$model_path" ]; then
        return 1
    fi
    
    print_status "Found existing model: $model_name"
    
    # Verify model
    if python3 "$PYTHON_SCRIPT" verify "$model_name" 2>&1 | grep -q "not registered"; then
        # Model exists but not registered - register it
        local version="1.0.0"
        if [[ "$model_name" == *"_v"* ]]; then
            # Extract version from filename if present (e.g., model_v1_2.onnx -> v1.2)
            version=$(echo "$model_name" | sed -n 's/.*_v\([0-9_]*\)\.onnx/v\1/p' | sed 's/_/./g' || echo "1.0.0")
        fi
        
        local description="${MODEL_DESCRIPTIONS[$model_name]:-ONNX model: $model_name}"
        python3 "$PYTHON_SCRIPT" register "$model_name" --version "$version" --description "$description" > /dev/null 2>&1
        print_status "  Registered $model_name (version $version)"
    else
        print_status "  ✓ Already registered"
    fi
    
    return 0
}

# Setup a specific model
setup_model() {
    local model_name="$1"
    local model_path="$MODELS_DIR/$model_name"
    
    # Check if model already exists
    if verify_and_register_model "$model_name"; then
        return 0
    fi
    
    print_status "Setting up $model_name..."
    
    # Try downloading first
    if python3 "$PYTHON_SCRIPT" download "$model_name" > /dev/null 2>&1; then
        print_status "  Downloaded $model_name successfully"
        verify_and_register_model "$model_name"
        return 0
    fi
    
    # If download fails and this is default.onnx, try generating
    if [ "$model_name" == "default.onnx" ] && [ -f "$EXPORT_SCRIPT" ]; then
        print_status "  Attempting to generate default model..."
        python3 "$EXPORT_SCRIPT" --out "$model_path" > /dev/null 2>&1
        if [ -f "$model_path" ]; then
            print_status "  Generated $model_name successfully"
            verify_and_register_model "$model_name"
            return 0
        fi
    fi
    
    print_warning "  Could not obtain $model_name (download URL not configured or generation failed)"
    return 1
}

# Discover and register all existing .onnx files
discover_existing_models() {
    print_status "Discovering existing models..."
    
    local discovered_count=0
    for model_file in "$MODELS_DIR"/*.onnx; do
        if [ -f "$model_file" ]; then
            local model_name=$(basename "$model_file")
            if verify_and_register_model "$model_name"; then
                ((discovered_count++))
            fi
        fi
    done
    
    if [ $discovered_count -eq 0 ]; then
        print_warning "No existing .onnx models found"
    else
        print_status "Discovered and registered $discovered_count model(s)"
    fi
}

main() {
    print_status "Starting AVRAI ML model setup..."
    
    verify_python
    verify_dependencies
    
    mkdir -p "$MODELS_DIR"
    
    # Step 1: Discover and register any existing models
    discover_existing_models
    
    echo ""
    
    # Step 2: Setup known models that are missing
    print_status "Setting up known models..."
    local missing_count=0
    for model in "${KNOWN_MODELS[@]}"; do
        if [ ! -f "$MODELS_DIR/$model" ]; then
            if ! setup_model "$model"; then
                ((missing_count++))
            fi
        else
            print_status "  ✓ $model already exists"
        fi
    done
    
    echo ""
    
    # Step 3: Summary
    print_status "Model setup summary:"
    python3 "$PYTHON_SCRIPT" list
    
    if [ $missing_count -gt 0 ]; then
        echo ""
        print_warning "Some models could not be set up automatically"
        print_warning "See docs/plans/ml_models/ for manual setup instructions"
        exit 1
    else
        print_status "All model setup completed successfully"
    fi
}

main "$@"

#!/bin/bash

# SPOTS ML Model Setup Script
# Handles model setup, verification, and registration

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/../.."
PYTHON_SCRIPT="$SCRIPT_DIR/model_manager.py"
MODELS_DIR="$PROJECT_ROOT/assets/models"
EXPORT_SCRIPT="$SCRIPT_DIR/export_sample_onnx.py"

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

setup_model() {
    local model_name="default.onnx"
    local model_path="$MODELS_DIR/$model_name"

    # Check if model exists and is valid
    if [ -f "$model_path" ] && python3 "$PYTHON_SCRIPT" verify "$model_name"; then
        print_status "Model already exists and is valid"
        return 0
    fi

    # Try downloading first
    print_status "Attempting to download model..."
    if python3 "$PYTHON_SCRIPT" download "$model_name"; then
        print_status "Model downloaded successfully"
        return 0
    fi

    # If download fails, try generating
    print_status "Download unavailable, attempting to generate model..."
    if [ -f "$EXPORT_SCRIPT" ]; then
        python3 "$EXPORT_SCRIPT"
        if [ -f "$model_path" ]; then
            print_status "Model generated successfully"
            python3 "$PYTHON_SCRIPT" register "$model_name" --version "1.0.0"
            return 0
        fi
    fi

    print_error "Failed to obtain model. Please check documentation for manual setup."
    return 1
}

main() {
    print_status "Starting SPOTS ML model setup..."
    
    verify_python
    verify_dependencies
    
    mkdir -p "$MODELS_DIR"
    
    if setup_model; then
        print_status "Model setup completed successfully"
    else
        print_error "Model setup failed"
        exit 1
    fi
}

main "$@"

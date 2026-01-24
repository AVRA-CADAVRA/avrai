#!/usr/bin/env python3
"""
Convert Llama 3.1 8B to CoreML format for macOS.

Requirements:
- Apple Silicon Mac (M1/M2/M3)
- Python 3.8+
- ~20GB free disk space
- 30-60 minutes

Install dependencies:
  pip3 install coremltools transformers torch huggingface-hub

Usage:
  python3 scripts/convert_llama_to_coreml.py [output_dir]
"""

import os
import sys
import argparse
from pathlib import Path

def main():
    parser = argparse.ArgumentParser(description='Convert Llama 3.1 8B to CoreML')
    parser.add_argument('output_dir', nargs='?', default='./models/macos',
                       help='Output directory for converted model')
    parser.add_argument('--model', default='meta-llama/Llama-3.1-8B-Instruct',
                       help='Model name or path')
    parser.add_argument('--quantize', action='store_true',
                       help='Quantize model (reduces size)')
    args = parser.parse_args()
    
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    print("=" * 60)
    print("Llama 3.1 8B → CoreML Conversion")
    print("=" * 60)
    print()
    print(f"Model: {args.model}")
    print(f"Output: {output_dir}")
    print()
    
    # Check if on Apple Silicon
    import platform
    if platform.processor() != 'arm':
        print("⚠️  Warning: Not on Apple Silicon. Conversion may be slow or fail.")
        print("   Recommended: Run on M1/M2/M3 Mac")
        response = input("Continue anyway? (y/n): ")
        if response.lower() != 'y':
            sys.exit(0)
    
    try:
        print("Step 1: Loading model and tokenizer...")
        print("This may take several minutes and download ~16GB...")
        print()
        
        from transformers import AutoTokenizer, AutoModelForCausalLM
        import torch
        
        tokenizer = AutoTokenizer.from_pretrained(args.model)
        model = AutoModelForCausalLM.from_pretrained(
            args.model,
            torch_dtype=torch.float16,
            device_map="auto",
            low_cpu_mem_usage=True,
        )
        
        print("✓ Model loaded")
        print()
        
        print("Step 2: Converting to CoreML...")
        print("This will take 30-60 minutes...")
        print()
        
        import coremltools as ct
        
        # Prepare input specification
        # Note: Actual conversion may require more configuration
        # This is a simplified example
        input_spec = [
            ct.TensorType(
                name="input_ids",
                shape=(1, ct.RangeDim(1, 4096)),
                dtype=ct.types.int32
            )
        ]
        
        # Convert model
        mlmodel = ct.convert(
            model,
            inputs=input_spec,
            compute_units=ct.ComputeUnit.ALL,  # Use all available compute units
            minimum_deployment_target=ct.target.macOS13,  # macOS 13+
        )
        
        print("✓ Conversion complete")
        print()
        
        # Save model
        output_path = output_dir / "llama-3.1-8b-instruct.mlpackage"
        print(f"Step 3: Saving model to {output_path}...")
        mlmodel.save(str(output_path))
        
        print()
        print("=" * 60)
        print("✓ Conversion Complete!")
        print("=" * 60)
        print()
        print("Next steps:")
        print(f"  1. Package as ZIP:")
        print(f"     cd {output_dir}")
        print(f"     zip -r llama-3.1-8b-instruct-coreml.zip llama-3.1-8b-instruct.mlpackage")
        print()
        print("  2. Calculate SHA-256:")
        print(f"     shasum -a 256 llama-3.1-8b-instruct-coreml.zip")
        print()
        print("  3. Upload to Supabase Storage")
        print("  4. Configure Supabase secrets")
        print()
        
    except ImportError as e:
        print(f"❌ Missing dependency: {e}")
        print()
        print("Install dependencies:")
        print("  pip3 install coremltools transformers torch huggingface-hub")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error: {e}")
        print()
        print("Troubleshooting:")
        print("  1. Ensure you're on Apple Silicon Mac")
        print("  2. Check you have enough disk space (~20GB)")
        print("  3. Verify model name is correct")
        print("  4. Try using pre-converted models instead")
        print()
        print("Alternative: Download pre-converted models from HuggingFace")
        print("  https://huggingface.co/models?search=llama-3.1-8b-coreml")
        sys.exit(1)

if __name__ == "__main__":
    main()

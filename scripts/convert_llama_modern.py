#!/usr/bin/env python3
"""
Modern Llama to CoreML Converter - Using TorchScript tracing

This script creates a simple wrapper that can be traced to TorchScript,
then converts to CoreML. This avoids the complex operations that break tracing.

Usage:
    python scripts/convert_llama_modern.py
"""

import os
import sys
from pathlib import Path
import torch
import coremltools as ct
import numpy as np
from transformers import AutoTokenizer, AutoModelForCausalLM


def load_hf_token():
    """Load HF_TOKEN from .env file."""
    env_file = Path(__file__).parent.parent / ".env"
    if env_file.exists():
        with open(env_file, "r") as f:
            for line in f:
                if line.startswith("HF_TOKEN="):
                    return line.split("=", 1)[1].strip()
    return os.getenv("HF_TOKEN")


class LlamaCoreMLWrapper(torch.nn.Module):
    """Simplified wrapper that extracts only the model's forward pass."""
    
    def __init__(self, model):
        super().__init__()
        # Extract just the model (not the full LlamaForCausalLM)
        self.model = model.model  # Get the LlamaModel, not LlamaForCausalLM
        self.lm_head = model.lm_head  # Get the language model head
        self.model.eval()
        self.lm_head.eval()
        # Ensure on CPU
        self.model = self.model.cpu()
        self.lm_head = self.lm_head.cpu()
    
    def forward(self, input_ids):
        """Simplified forward pass that avoids problematic operations."""
        # Use the model's forward directly
        # This avoids the LlamaForCausalLM wrapper that has complex masking
        outputs = self.model(
            input_ids=input_ids,
            use_cache=False,
            return_dict=True,
        )
        # Get hidden states and apply lm_head
        hidden_states = outputs.last_hidden_state
        logits = self.lm_head(hidden_states)
        return logits


def main():
    print("=" * 60)
    print("Llama → CoreML Converter (TorchScript Tracing)")
    print("=" * 60)
    print()
    
    # Check for local model first
    local_model = Path(__file__).parent.parent / "models" / "raw" / "llama3.1-8b-instruct"
    if local_model.exists():
        print(f"✅ Found local model: {local_model}")
        model_path = str(local_model)
        use_local = True
    else:
        print("📥 Will download from HuggingFace")
        model_path = "meta-llama/Llama-3.1-8B-Instruct"
        use_local = False
    
    token = load_hf_token()
    if not token and not use_local:
        print("❌ HF_TOKEN required for HuggingFace download")
        print("   Set it in .env file or HF_TOKEN environment variable")
        return 1
    
    print()
    print("Step 1: Loading model...")
    print("   Loading on CPU...")
    print("   This may take a few minutes...")
    print()
    
    try:
        tokenizer = AutoTokenizer.from_pretrained(
            model_path,
            token=token if not use_local else None,
        )
        
        # Load model on CPU explicitly
        model = AutoModelForCausalLM.from_pretrained(
            model_path,
            dtype=torch.float16,
            device_map=None,  # Load on CPU
            low_cpu_mem_usage=True,
            token=token if not use_local else None,
        )
        
        # Explicitly move to CPU and set to eval mode
        model = model.cpu()
        model.eval()
        
        print("✅ Model loaded on CPU")
        print()
        
        # Create simplified wrapper
        print("Step 2: Creating simplified wrapper...")
        wrapped_model = LlamaCoreMLWrapper(model)
        print("✅ Wrapper created")
        print()
        
        print("Step 3: Tracing to TorchScript...")
        print("   This prepares the model for CoreML conversion...")
        print()
        
        # Create example input
        example_input = torch.randint(
            low=0,
            high=min(tokenizer.vocab_size, 1000),
            size=(1, 10),
            dtype=torch.long,
            device="cpu"
        )
        
        # Trace to TorchScript
        print("   Tracing (this may take a minute)...")
        with torch.no_grad():
            try:
                traced_model = torch.jit.trace(
                    wrapped_model,
                    example_input,
                    strict=False,
                )
                print("✅ Model traced to TorchScript")
            except Exception as trace_error:
                print(f"   ❌ Tracing failed: {trace_error}")
                print()
                print("💡 The model may have operations that can't be traced.")
                print("   Alternative: Use pre-converted model from HuggingFace")
                print("   https://huggingface.co/andmev/Llama-3.1-8B-Instruct-CoreML")
                raise
        
        print()
        print("Step 4: Converting to CoreML...")
        print("   This will take 30-60 minutes...")
        print()
        
        # Define input specification
        input_spec = [
            ct.TensorType(
                name="input_ids",
                shape=(1, ct.RangeDim(lower_bound=1, upper_bound=2048, default=10)),
                dtype=np.int32,
            )
        ]
        
        # Convert TorchScript to CoreML
        try:
            print("   Attempting conversion with mlprogram format...")
            mlmodel = ct.convert(
                traced_model,
                source="pytorch",
                inputs=input_spec,
                outputs=[ct.TensorType(name="logits", dtype=np.float16)],
                compute_units=ct.ComputeUnit.ALL,
                minimum_deployment_target=ct.target.macOS13,
                convert_to="mlprogram",
                compute_precision=ct.precision.FLOAT16,
            )
            print("✅ Conversion complete with mlprogram format!")
        except Exception as convert_error:
            print(f"   ⚠️  mlprogram conversion failed: {convert_error}")
            print("   Trying without mlprogram format...")
            try:
                mlmodel = ct.convert(
                    traced_model,
                    source="pytorch",
                    inputs=input_spec,
                    outputs=[ct.TensorType(name="logits", dtype=np.float16)],
                    compute_units=ct.ComputeUnit.ALL,
                    minimum_deployment_target=ct.target.macOS13,
                    compute_precision=ct.precision.FLOAT16,
                )
                print("✅ Conversion complete!")
            except Exception as convert_error2:
                print(f"   ❌ Conversion failed: {convert_error2}")
                print()
                print("💡 This may be the coremltools bug with certain PyTorch operations.")
                print("   Alternative: Use pre-converted model from HuggingFace")
                print("   https://huggingface.co/andmev/Llama-3.1-8B-Instruct-CoreML")
                raise
        
        print()
        
        # Save model
        output_dir = Path(__file__).parent.parent / "models" / "macos"
        output_dir.mkdir(parents=True, exist_ok=True)
        output_path = output_dir / "Llama-3.1-8B-Instruct.mlpackage"
        
        print(f"Step 5: Saving to {output_path}...")
        mlmodel.save(str(output_path))
        
        print()
        print("=" * 60)
        print("✅ SUCCESS!")
        print("=" * 60)
        print()
        print(f"📁 Model saved: {output_path}")
        print()
        
        # Check file size
        size_mb = output_path.stat().st_size / (1024 * 1024)
        print(f"📦 File size: {size_mb:.2f} MB")
        print()
        
        print("📦 Next: Package as ZIP")
        print(f"   cd {output_dir}")
        print(f"   zip -r llama-3.1-8b-instruct-coreml.zip Llama-3.1-8B-Instruct.mlpackage")
        print()
        print("   Then calculate hash and size:")
        print(f"   shasum -a 256 llama-3.1-8b-instruct-coreml.zip")
        print(f"   stat -f%z llama-3.1-8b-instruct-coreml.zip")
        print()
        
        return 0
        
    except Exception as e:
        print()
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        print()
        print("💡 Troubleshooting:")
        print("   - Ensure you have coremltools, transformers, torch, accelerate installed")
        print("   - Check that you have enough RAM (16GB+ recommended)")
        print("   - Verify the model files are complete in models/raw/")
        print("   - The coremltools bug may require using a pre-converted model")
        print("   - Try: https://huggingface.co/andmev/Llama-3.1-8B-Instruct-CoreML")
        return 1


if __name__ == "__main__":
    exit(main())

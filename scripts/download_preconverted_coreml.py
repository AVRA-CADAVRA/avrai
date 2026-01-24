#!/usr/bin/env python3
"""
Download Pre-Converted Llama CoreML Model

Since direct conversion has compatibility issues with current library versions,
this script downloads a pre-converted CoreML model from HuggingFace.

Usage:
    python scripts/download_preconverted_coreml.py
"""

import os
import sys
from pathlib import Path
from huggingface_hub import snapshot_download


def load_hf_token():
    """Load HF_TOKEN from .env file."""
    env_file = Path(__file__).parent.parent / ".env"
    if env_file.exists():
        with open(env_file, "r") as f:
            for line in f:
                if line.startswith("HF_TOKEN="):
                    return line.split("=", 1)[1].strip()
    return os.getenv("HF_TOKEN")


def main():
    print("=" * 60)
    print("Download Pre-Converted Llama CoreML Model")
    print("=" * 60)
    print()
    
    # Pre-converted model from HuggingFace
    repo_id = "andmev/Llama-3.1-8B-Instruct-CoreML"
    
    token = load_hf_token()
    if not token:
        print("⚠️  HF_TOKEN not found in .env or environment")
        print("   Some models may require authentication")
        print("   Continuing without token...")
        print()
    
    output_dir = Path(__file__).parent.parent / "models" / "macos"
    output_dir.mkdir(parents=True, exist_ok=True)
    
    print(f"📥 Downloading from: {repo_id}")
    print(f"📁 Output directory: {output_dir}")
    print()
    print("   This will download the pre-converted CoreML model.")
    print("   Size: ~8-16 GB (depending on quantization)")
    print()
    
    try:
        print("   Downloading...")
        local_dir = snapshot_download(
            repo_id=repo_id,
            token=token,
            local_dir=str(output_dir / "Llama-3.1-8B-Instruct-CoreML"),
            local_dir_use_symlinks=False,
        )
        
        print()
        print("=" * 60)
        print("✅ SUCCESS!")
        print("=" * 60)
        print()
        print(f"📁 Model downloaded to: {local_dir}")
        print()
        
        # Find .mlpackage file
        mlpackage_files = list(Path(local_dir).rglob("*.mlpackage"))
        if mlpackage_files:
            mlpackage_path = mlpackage_files[0]
            print(f"📦 Found CoreML model: {mlpackage_path}")
            
            # Move to main macos directory if it's in a subdirectory
            if mlpackage_path.parent != output_dir:
                target_path = output_dir / mlpackage_path.name
                if not target_path.exists():
                    import shutil
                    print(f"   Moving to: {target_path}")
                    shutil.move(str(mlpackage_path), str(target_path))
                    mlpackage_path = target_path
                else:
                    print(f"   Already exists at: {target_path}")
                    mlpackage_path = target_path
            
            print()
            print("📦 Next: Package as ZIP")
            print(f"   cd {output_dir}")
            print(f"   zip -r llama-3.1-8b-instruct-coreml.zip {mlpackage_path.name}")
            print()
            print("   Then calculate hash and size:")
            print(f"   shasum -a 256 llama-3.1-8b-instruct-coreml.zip")
            print(f"   stat -f%z llama-3.1-8b-instruct-coreml.zip")
            print()
        else:
            print("⚠️  No .mlpackage file found in download")
            print(f"   Check: {local_dir}")
            print()
        
        return 0
        
    except Exception as e:
        print()
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        print()
        print("💡 Troubleshooting:")
        print("   - Check your internet connection")
        print("   - Verify HF_TOKEN is correct if authentication is required")
        print("   - Check available disk space (need ~20GB free)")
        return 1


if __name__ == "__main__":
    exit(main())

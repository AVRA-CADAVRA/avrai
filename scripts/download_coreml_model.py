#!/usr/bin/env python3
"""
Download pre-converted CoreML model from HuggingFace.
Model: andmev/Llama-3.1-8B-Instruct-CoreML
"""

import os
import sys
import zipfile
from pathlib import Path

# Load .env file if it exists (for HF_TOKEN)
def load_env_file():
    env_path = Path(__file__).parent.parent / '.env'
    if env_path.exists():
        with open(env_path) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    os.environ.setdefault(key.strip(), value.strip())

load_env_file()

try:
    from huggingface_hub import hf_hub_download
except ImportError:
    print("❌ huggingface_hub not installed")
    print("")
    print("Install with:")
    print("  pip3 install --user huggingface-hub")
    print("  # or")
    print("  python3 -m pip install --user huggingface-hub")
    sys.exit(1)

def main():
    model_repo = "andmev/Llama-3.1-8B-Instruct-CoreML"
    model_file = "llama_3.1_coreml.mlpackage"
    output_dir = Path("./models/macos")
    zip_name = "llama-3.1-8b-instruct-coreml.zip"
    
    output_dir.mkdir(parents=True, exist_ok=True)
    
    print("📦 Downloading CoreML model from HuggingFace")
    print(f"   Repository: {model_repo}")
    print(f"   File: {model_file}")
    print("")
    
    try:
        # Download the model
        print("Downloading model (this may take a while, ~4.5 GB)...")
        downloaded_path = hf_hub_download(
            repo_id=model_repo,
            filename=model_file,
            local_dir=str(output_dir),
            local_dir_use_symlinks=False,
        )
        
        print(f"✅ Model downloaded to: {downloaded_path}")
        
        # Check if it's a directory or file
        model_path = Path(downloaded_path)
        if model_path.is_dir():
            # Package directory as ZIP
            print("")
            print("📦 Packaging model directory as ZIP...")
            zip_path = output_dir / zip_name
            with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
                for root, dirs, files in os.walk(model_path):
                    for file in files:
                        file_path = Path(root) / file
                        arcname = file_path.relative_to(model_path.parent)
                        zipf.write(file_path, arcname)
            print(f"✅ Created: {zip_path}")
        else:
            # It's a single file, create ZIP
            print("")
            print("📦 Packaging model file as ZIP...")
            zip_path = output_dir / zip_name
            with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
                zipf.write(model_path, model_path.name)
            print(f"✅ Created: {zip_path}")
        
        # Calculate hash and size
        import hashlib
        import stat
        
        print("")
        print("📊 Calculating SHA-256 hash and file size...")
        
        sha256_hash = hashlib.sha256()
        with open(zip_path, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
        hash_value = sha256_hash.hexdigest()
        
        file_size = zip_path.stat().st_size
        size_gb = file_size / (1024 ** 3)
        
        print("")
        print("✅ Model ready for upload!")
        print("")
        print(f"File: {zip_path}")
        print(f"SHA-256: {hash_value}")
        print(f"Size: {file_size:,} bytes ({size_gb:.2f} GB)")
        print("")
        print("Next steps:")
        print("  1. Upload to Supabase Storage bucket: local-llm-models")
        print("  2. Copy the public URL after upload")
        print("  3. Set secrets:")
        print(f"     supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_URL=\"<URL>\"")
        print(f"     supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SHA256=\"{hash_value}\"")
        print(f"     supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SIZE_BYTES=\"{file_size}\"")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        print("")
        print("Alternative: Download manually from:")
        print(f"  https://huggingface.co/{model_repo}/tree/main")
        sys.exit(1)

if __name__ == "__main__":
    main()

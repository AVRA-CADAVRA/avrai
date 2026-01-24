#!/usr/bin/env python3
"""
Download Llama model files directly from HuggingFace.

Usage:
    python scripts/download_llama_model.py --model-id Llama3.1-8B-Instruct
    python scripts/download_llama_model.py --model-id Llama-4-Scout-17B-16E-Instruct
"""

import argparse
import os
import shutil
from pathlib import Path

from huggingface_hub import HfApi, snapshot_download


def load_hf_token():
    """Load HF_TOKEN from .env file."""
    env_file = Path(__file__).parent.parent / ".env"
    if env_file.exists():
        with open(env_file, "r") as f:
            for line in f:
                if line.startswith("HF_TOKEN="):
                    return line.split("=", 1)[1].strip()
    
    # Try environment variable
    token = os.getenv("HF_TOKEN")
    if token:
        return token
    
    raise ValueError(
        "HF_TOKEN not found. Set it in .env file or HF_TOKEN environment variable."
    )


# Model ID mapping (from llama-model list output)
MODEL_MAP = {
    "Llama3.1-8B-Instruct": "meta-llama/Llama-3.1-8B-Instruct",
    "Llama3.1-8B": "meta-llama/Llama-3.1-8B",
    "Llama3.2-3B-Instruct": "meta-llama/Llama-3.2-3B-Instruct",
    "Llama3.2-3B": "meta-llama/Llama-3.2-3B",
    "Llama-4-Scout-17B-16E-Instruct": "meta-llama/Llama-4-Scout-17B-16E-Instruct",
    "Llama-4-Scout-17B-16E": "meta-llama/Llama-4-Scout-17B-16E",
    "Llama-4-Maverick-17B-128E-Instruct": "meta-llama/Llama-4-Maverick-17B-128E-Instruct",
    "Llama-4-Maverick-17B-128E": "meta-llama/Llama-4-Maverick-17B-128E",
}


def main():
    parser = argparse.ArgumentParser(
        description="Download Llama model files from HuggingFace"
    )
    parser.add_argument(
        "--model-id",
        required=True,
        help="Model ID (e.g., Llama3.1-8B-Instruct, Llama-4-Scout-17B-16E-Instruct)",
    )
    parser.add_argument(
        "--output-dir",
        help="Output directory (default: models/raw/{model_name})",
    )
    parser.add_argument(
        "--hf-token",
        help="HuggingFace token (default: from .env or HF_TOKEN env var)",
    )
    
    args = parser.parse_args()
    
    # Get HuggingFace repo ID
    if args.model_id in MODEL_MAP:
        repo_id = MODEL_MAP[args.model_id]
    elif args.model_id.startswith("meta-llama/"):
        repo_id = args.model_id
    else:
        print(f"❌ Unknown model ID: {args.model_id}")
        print(f"\nAvailable models:")
        for model_id in sorted(MODEL_MAP.keys()):
            print(f"  - {model_id}")
        return 1
    
    # Get token
    token = args.hf_token or load_hf_token()
    
    # Determine output directory
    if args.output_dir:
        output_dir = Path(args.output_dir)
    else:
        # Create safe directory name from model ID
        safe_name = args.model_id.lower().replace(":", "-").replace("_", "-")
        output_dir = Path(__file__).parent.parent / "models" / "raw" / safe_name
    
    output_dir = output_dir.expanduser().resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    
    print(f"📥 Downloading: {repo_id}")
    print(f"📁 Output: {output_dir}")
    print("🔑 Using HuggingFace token (from .env / HF_TOKEN)")

    # Best-effort: show expected download size + free space up-front.
    try:
        api = HfApi()
        items = list(
            api.list_repo_tree(
                repo_id=repo_id,
                repo_type="model",
                recursive=True,
                token=token,
            )
        )
        total_bytes = sum((getattr(i, "size", 0) or 0) for i in items)
        free_bytes = shutil.disk_usage(str(output_dir)).free

        total_gib = total_bytes / (1024**3)
        free_gib = free_bytes / (1024**3)

        print(f"📦 Expected download size: ~{total_gib:.2f} GiB")
        print(f"💾 Free space at output: ~{free_gib:.2f} GiB")

        # Downloads often need extra headroom for temp/cache files.
        recommended_free_gib = total_gib + 20.0
        if free_gib < recommended_free_gib:
            print(
                "⚠️  Low disk space: this download likely will fail before completion.\n"
                f"   Recommended free space: ~{recommended_free_gib:.0f} GiB (model + ~20 GiB headroom)."
            )
    except Exception:
        # Non-fatal: still try the download.
        pass
    print()
    
    try:
        snapshot_download(
            repo_id=repo_id,
            token=token,
            local_dir=str(output_dir),
        )
        print()
        print(f"✅ Download complete!")
        print(f"📁 Files saved to: {output_dir}")
        return 0
    except Exception as e:
        error_msg = str(e)
        print(f"❌ Download failed: {error_msg}")
        
        # Check for access errors
        if "403" in error_msg or "gated repo" in error_msg.lower() or "not in the authorized list" in error_msg.lower():
            print()
            print("🔒 ACCESS REQUIRED:")
            print(f"   This model requires approval from Meta.")
            print(f"   Visit: https://huggingface.co/{repo_id}")
            print(f"   Click 'Agree and access repository' to request access.")
            print()
            print("   After approval (usually within hours):")
            print(f"   Run this command again to download.")
        
        return 1


if __name__ == "__main__":
    exit(main())

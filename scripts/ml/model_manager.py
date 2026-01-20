#!/usr/bin/env python3
"""
Model Manager for SPOTS

Handles downloading, verifying, and managing ML models.
"""

import os
import sys
import hashlib
import argparse
import json
from pathlib import Path
import requests
from typing import Dict, Optional, List
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Constants
CONFIG_FILE = "model_registry.json"
MODELS_DIR = Path(__file__).parent.parent.parent / "assets" / "models"
TEMP_DIR = MODELS_DIR / ".temp"

class ModelManager:
    def __init__(self, config_path: Optional[str] = None):
        self.config_path = config_path or str(MODELS_DIR / CONFIG_FILE)
        self.models_dir = MODELS_DIR
        self.temp_dir = TEMP_DIR
        self.config: Dict = {}
        self._load_config()
        
    def _load_config(self):
        """Load model registry configuration."""
        if not os.path.exists(self.config_path):
            self.config = {
                "models": {}
            }
            self._save_config()
        else:
            with open(self.config_path) as f:
                self.config = json.load(f)
        
        # Ensure models key exists
        if "models" not in self.config:
            self.config["models"] = {}

    def _save_config(self):
        """Save current configuration."""
        os.makedirs(os.path.dirname(self.config_path), exist_ok=True)
        with open(self.config_path, 'w') as f:
            json.dump(self.config, f, indent=2)

    def _calculate_md5(self, file_path: str) -> str:
        """Calculate MD5 hash of a file."""
        md5 = hashlib.md5()
        with open(file_path, 'rb') as f:
            for chunk in iter(lambda: f.read(4096), b''):
                md5.update(chunk)
        return md5.hexdigest()

    def verify_model(self, model_name: str) -> bool:
        """Verify model file exists and matches expected hash."""
        model_path = self.models_dir / model_name
        if not model_path.exists():
            logger.error(f"Model {model_name} not found")
            return False

        # Check if model is registered in config
        if model_name not in self.config["models"]:
            logger.warning(f"Model {model_name} exists but not registered in registry")
            return True  # File exists, just not registered

        expected_md5 = self.config["models"][model_name].get("md5")
        if not expected_md5:
            logger.warning(f"No MD5 hash configured for {model_name}")
            return True

        actual_md5 = self._calculate_md5(str(model_path))
        if actual_md5 != expected_md5:
            logger.error(f"MD5 mismatch for {model_name}")
            return False

        logger.info(f"Successfully verified {model_name}")
        return True

    def list_models(self) -> List[str]:
        """List all .onnx model files in the models directory."""
        if not self.models_dir.exists():
            return []
        
        models = []
        for file in self.models_dir.glob("*.onnx"):
            if file.is_file() and not file.name.startswith("."):
                models.append(file.name)
        return sorted(models)

    def download_model(self, model_name: str, force: bool = False) -> bool:
        """Download model from configured URL."""
        if not force and (self.models_dir / model_name).exists():
            if self.verify_model(model_name):
                logger.info(f"Model {model_name} already exists and is valid")
                return True
            
        model_config = self.config["models"].get(model_name)
        if not model_config or not model_config.get("url"):
            logger.error(f"No download URL configured for {model_name}")
            return False

        os.makedirs(self.temp_dir, exist_ok=True)
        temp_path = self.temp_dir / f"{model_name}.tmp"
        
        try:
            response = requests.get(model_config["url"], stream=True)
            response.raise_for_status()
            
            with open(temp_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)

            actual_md5 = self._calculate_md5(str(temp_path))
            if model_config.get("md5") and actual_md5 != model_config["md5"]:
                logger.error(f"Downloaded file MD5 mismatch for {model_name}")
                return False

            os.makedirs(self.models_dir, exist_ok=True)
            temp_path.rename(self.models_dir / model_name)
            logger.info(f"Successfully downloaded {model_name}")
            return True

        except Exception as e:
            logger.error(f"Error downloading {model_name}: {e}")
            return False
        finally:
            if temp_path.exists():
                temp_path.unlink()

    def register_model(self, model_name: str, version: str, url: Optional[str] = None, description: Optional[str] = None):
        """Register a new model or update existing registration."""
        model_path = self.models_dir / model_name
        if not model_path.exists():
            logger.error(f"Model file {model_name} not found")
            return

        md5 = self._calculate_md5(str(model_path))
        existing_desc = self.config["models"].get(model_name, {}).get("description", "")
        self.config["models"][model_name] = {
            "version": version,
            "md5": md5,
            "url": url,
            "description": description or existing_desc or f"ONNX model: {model_name}"
        }
        self._save_config()
        logger.info(f"Registered {model_name} version {version}")

def main():
    parser = argparse.ArgumentParser(description="SPOTS Model Manager")
    parser.add_argument("action", choices=["verify", "download", "register", "list"])
    parser.add_argument("model", nargs="?", help="Model name (e.g., default.onnx) - not required for 'list' action")
    parser.add_argument("--version", help="Model version for registration")
    parser.add_argument("--url", help="Download URL for registration")
    parser.add_argument("--description", help="Model description for registration")
    parser.add_argument("--force", action="store_true", help="Force download even if file exists")
    
    args = parser.parse_args()
    manager = ModelManager()

    if args.action == "list":
        models = manager.list_models()
        if not models:
            logger.info("No .onnx models found in assets/models/")
        else:
            logger.info(f"Found {len(models)} model(s):")
            for model in models:
                registered = model in manager.config["models"]
                status = "✓ registered" if registered else "○ unregistered"
                logger.info(f"  - {model} ({status})")
        sys.exit(0)
    elif args.action == "verify":
        if not args.model:
            logger.error("Model name required for verify action")
            sys.exit(1)
        success = manager.verify_model(args.model)
        sys.exit(0 if success else 1)
    elif args.action == "download":
        if not args.model:
            logger.error("Model name required for download action")
            sys.exit(1)
        success = manager.download_model(args.model, args.force)
        sys.exit(0 if success else 1)
    elif args.action == "register":
        if not args.model:
            logger.error("Model name required for register action")
            sys.exit(1)
        if not args.version:
            logger.error("--version required for registration")
            sys.exit(1)
        manager.register_model(args.model, args.version, args.url, args.description)

if __name__ == "__main__":
    main()

# Machine Learning Models

This directory contains machine learning models used by the SPOTS application for AI2AI functionality.

## Required Models

### default.onnx
- **Purpose**: Core inference model for AI2AI system
- **Size**: ~418MB
- **Not included in repository** due to size limitations
- **Location**: Place in this directory (`assets/models/default.onnx`)

## Getting the Model

### Option 1: Generate the Model
Run the provided export script:
```bash
python scripts/ml/export_sample_onnx.py
```

### Option 2: Download Pre-trained Model
1. Access our model registry (contact team for credentials)
2. Download `default.onnx` version 1.0.0
3. Place in `assets/models/` directory

## Model Versioning
- Current production version: 1.0.0
- Model hash (MD5): [contact team for verification hash]
- Compatibility: ONNX Runtime 1.12.0+

## Development Notes
- Models are excluded from git via `.gitignore`
- Keep local backups of your models
- See `lib/core/ml/onnx_backend_io.dart` for model loading implementation
- Test with `test/unit/ml/onnx_backend_test.dart`

## Troubleshooting
If you encounter model loading issues:
1. Verify model file exists in correct location
2. Check model version compatibility
3. Ensure ONNX Runtime is properly initialized
4. See logs in `logs/ml/model_loading.log`

## Security Notes
- Never commit model files to git
- Use secure channels for model distribution
- Validate model hashes before use
- Keep model access credentials secure
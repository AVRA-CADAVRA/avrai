# SPOTS

SPOTS (Smart Personalized Optimization and Tracking System) - An AI2AI-powered location and preference tracking system.

## Quick Start

1. Clone the repository:
```bash
git clone https://github.com/your-org/spots.git
cd spots
```

2. Set up ML models:
```bash
./scripts/ml/setup_models.sh
```

3. Install dependencies:
```bash
flutter pub get
```

4. Run the app:
```bash
flutter run
```

## ML Model Setup

SPOTS uses ONNX models for AI2AI functionality. The setup script will automatically:
1. Download pre-trained models if available
2. Generate models if download fails
3. Verify model integrity

For manual setup, see [ML Models Documentation](assets/models/README.md).

## Development

### Prerequisites
- Flutter SDK
- Python 3.8+ (for ML tools)
- ONNX Runtime

### Project Structure
```
spots/
├── lib/               # Dart source code
│   ├── core/         # Core functionality
│   │   ├── ai/      # AI2AI system
│   │   ├── ml/      # Machine learning
│   │   └── ...
│   ├── data/         # Data layer
│   ├── domain/       # Business logic
│   └── presentation/ # UI layer
├── assets/           # Static assets
│   └── models/       # ML models
├── scripts/          # Development scripts
│   └── ml/          # ML management tools
└── test/            # Test suites
```

### Key Features
- AI2AI network for distributed intelligence
- ONNX-based inference engine
- Real-time preference learning
- Secure data handling

## Testing

Run tests:
```bash
flutter test
```

Run integration tests:
```bash
flutter drive --target=test_driver/app.dart
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## License

[Your License] - See LICENSE file for details
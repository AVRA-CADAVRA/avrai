# SPOTS

**Smart Personalized Optimization and Tracking System**

An AI2AI-powered, offline-first mobile application that helps people discover meaningful places, build authentic communities, and find belonging through personalized recommendations and event hosting.

[![GitHub](https://img.shields.io/badge/GitHub-reis--ship--it-blue)](https://github.com/reis-ship-it/SPOTS)
[![Flutter](https://img.shields.io/badge/Flutter-3.8+-blue)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.6+-blue)](https://dart.dev)

---

## 🚪 Philosophy: "Doors, Not Badges"

> **"There is no secret to life. Just doors that haven't been opened yet."**

SPOTS is **the key** that helps you open those doors. Every spot is a door:
- To experiences
- To communities  
- To people
- To meaning
- To more doors

**The Journey:** Spots → Community → Life

You discover your favorite spots, those spots have communities, those communities have events, and through SPOTS, you find your people and enrich your life.

**SPOTS just provides access. You decide which doors to open.**

---

## ✨ Key Features

### 🔐 Privacy-First AI2AI Network
- **Offline-First Architecture:** Works without internet, syncs when connected
- **AI2AI Learning:** Privacy-preserving peer-to-peer AI learning between devices
- **On-Device Intelligence:** All personal data stays on-device, no surveillance
- **Real-Time Discovery:** Find compatible people and places instantly, anywhere

### 🧠 Quantum-Inspired AI System
- **Quantum Compatibility Calculation:** 12-dimensional personality state vectors for accurate matching
- **Contextual Personality Drift Resistance:** Maintains user authenticity over time
- **Multi-Entity Quantum Entanglement Matching:** Advanced group compatibility algorithms
- **Hybrid Quantum-Classical Neural Networks:** Best of both worlds for recommendations

### 📍 Location & Discovery
- **Personalized Spot Recommendations:** AI learns your preferences and suggests meaningful places
- **Expertise Recognition:** Become an expert through genuine contributions (no gamification)
- **Community Discovery:** Find writing groups, food clubs, local meetups at your spots
- **Event Hosting:** Host events once you become a local expert

### 🎯 Authentic Contributions
- **"Doors, Not Badges":** Authentic contributions unlock features, not gamification
- **No Pay-to-Play:** Recommendations never for sale, authentic discovery only
- **Expertise Levels:** Local / City / Regional / National / Global / Universal
- **Trust-Based System:** Respected lists and trusted feedback drive recommendations

### 💼 Business & Events
- **Event Ticketing:** Host-powered event management and ticketing
- **Partnership System:** Multi-path expertise partnerships with revenue distribution
- **Business Integration:** Venue partnerships, brand sponsorships, expert matching
- **Payment Processing:** Secure Stripe integration for events and transactions

---

## 🏆 Patent Portfolio

**30 Potentially Patentable Innovations** across 6 categories:

### Category 1: Quantum-Inspired AI Systems (8 patents)
- Quantum Compatibility Calculation System
- Contextual Personality Drift Resistance
- Multi-Entity Quantum Entanglement Matching
- Physiological Intelligence Integration
- Quantum Expertise Enhancement
- Hybrid Quantum-Classical Neural Networks
- Quantum Atomic Clock System (Patent #30)

### Category 2: Offline-First & Privacy Systems (5 patents)
- Offline-First AI2AI Peer-to-Peer Learning
- Privacy-Preserving Vibe Signatures
- Differential Privacy with Entropy Validation
- Automatic Passive Check-In System
- Location Obfuscation with Differential Privacy

### Category 3: Expertise & Economic Systems (6 patents)
- Multi-Path Dynamic Expertise System
- N-Way Revenue Distribution
- Multi-Path Quantum Partnership Ecosystem
- Exclusive Long-Term Partnerships
- 6-Factor Saturation Algorithm
- Calling Score Calculation

### Category 4: Recommendation & Discovery (4 patents)
- 12-Dimensional Personality Multi-Factor Matching
- Hyper-Personalized Recommendation Engine
- Tiered Discovery Compatibility System

### Category 5: Network Intelligence (5 patents)
- Quantum Emotional Scale Self-Assessment
- AI2AI Chat Learning System
- Self-Improving Network Architecture
- Real-Time Trend Detection
- Privacy-Preserving Admin Viewer

### Category 6: Location Context Systems (2 patents)
- Location Inference Agent Network
- Location Obfuscation System

**Status:** 6 Tier 1 patents ready for filing (including Patent #30: Quantum Atomic Clock System). See [`docs/patents/`](docs/patents/) for complete documentation.

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (3.8+)
- Dart SDK (3.6+)
- Python 3.8+ (for ML tools)
- iOS/Android development environment

### Installation

1. **Clone the repository:**
```bash
git clone https://github.com/reis-ship-it/SPOTS.git
cd SPOTS
```

2. **Install dependencies:**
```bash
flutter pub get
```

3. **Set up environment variables:**
```bash
# Copy example config files and add your API keys
cp supabase_config.example lib/supabase_config.dart
# Edit lib/supabase_config.dart with your Supabase credentials
# Edit lib/google_places_config.dart with your Google Places API key
# Edit lib/weather_config.dart with your weather API key
```

4. **Run the app:**
```bash
flutter run
```

### ML Model Setup (Optional)

SPOTS uses ONNX models for AI2AI functionality:

```bash
./scripts/ml/setup_models.sh
```

The setup script will:
1. Download pre-trained models if available
2. Generate models if download fails
3. Verify model integrity

For manual setup, see [`assets/models/README.md`](assets/models/README.md).

---

## 📁 Project Structure

```
SPOTS/
├── lib/                      # Dart source code
│   ├── core/                 # Core functionality
│   │   ├── ai/              # AI2AI system & quantum algorithms
│   │   ├── ml/              # Machine learning pipelines
│   │   ├── models/          # Data models
│   │   └── services/        # Core services
│   ├── data/                 # Data layer
│   │   ├── datasources/     # Local & remote data sources
│   │   └── repositories/    # Repository implementations
│   ├── domain/              # Business logic
│   │   ├── repositories/    # Repository interfaces
│   │   └── usecases/        # Use cases
│   └── presentation/        # UI layer
│       ├── pages/           # App screens
│       ├── widgets/         # Reusable widgets
│       └── blocs/          # State management (BLoC)
├── assets/                   # Static assets
│   └── models/              # ML models (ONNX)
├── docs/                     # Documentation
│   ├── patents/             # Patent portfolio (29 patents)
│   ├── plans/               # Implementation plans
│   └── architecture/        # Architecture documentation
├── test/                     # Test suites
│   ├── unit/                # Unit tests
│   ├── integration/         # Integration tests
│   └── widget/              # Widget tests
├── scripts/                  # Development scripts
└── supabase/                 # Supabase configuration
    ├── migrations/          # Database migrations
    └── functions/           # Edge functions
```

---

## 🧪 Testing

### Run all tests:
```bash
flutter test
```

### Run integration tests:
```bash
flutter drive --target=integration_test_driver/integration_test.dart
```

### Run specific test suites:
```bash
# Unit tests only
flutter test test/unit/

# Integration tests only
flutter test test/integration/

# Widget tests only
flutter test test/widget/
```

### Test quality checks:
```bash
dart run scripts/check_test_quality.dart [file]
```

---

## 🏗️ Architecture

### Clean Architecture
- **Presentation Layer:** Flutter UI with BLoC state management
- **Domain Layer:** Business logic and use cases
- **Data Layer:** Repositories and data sources
- **Core Layer:** Shared utilities, models, and services

### Key Technologies
- **Flutter/Dart:** Cross-platform mobile framework
- **BLoC:** State management pattern
- **Sembast:** Local NoSQL database (offline-first)
- **Supabase:** Backend-as-a-Service (auth, database, storage)
- **Firebase:** Additional services (analytics, crash reporting)
- **Stripe:** Payment processing
- **ONNX Runtime:** On-device ML inference

### AI2AI Network
- **Offline-First:** Core functionality works without internet
- **Peer-to-Peer:** Bluetooth/local network connections
- **Privacy-Preserving:** Only anonymized compatibility signals shared
- **Self-Improving:** Network learns from successful connections

---

## 📚 Documentation

### Core Philosophy
- [`OUR_GUTS.md`](OUR_GUTS.md) - Core values and philosophy
- [`docs/plans/philosophy_implementation/DOORS.md`](docs/plans/philosophy_implementation/DOORS.md) - Doors philosophy
- [`docs/plans/philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md`](docs/plans/philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md) - Complete architecture guide

### Implementation
- [`docs/MASTER_PLAN.md`](docs/MASTER_PLAN.md) - Master execution plan
- [`docs/plans/methodology/DEVELOPMENT_METHODOLOGY.md`](docs/plans/methodology/DEVELOPMENT_METHODOLOGY.md) - Development methodology
- [`README_DEVELOPMENT.md`](README_DEVELOPMENT.md) - Development guide
- [`docs/CURSOR_RULES_SETUP.md`](docs/CURSOR_RULES_SETUP.md) - Cursor AI rules setup guide

### Patents
- [`docs/patents/PATENT_PORTFOLIO_INDEX.md`](docs/patents/PATENT_PORTFOLIO_INDEX.md) - Complete patent portfolio
- [`docs/patents/PATENT_PORTFOLIO_FINAL_REVIEW.md`](docs/patents/PATENT_PORTFOLIO_FINAL_REVIEW.md) - Filing readiness review

### Business
- [`docs/SPOTS_COMPREHENSIVE_OVERVIEW.md`](docs/SPOTS_COMPREHENSIVE_OVERVIEW.md) - Comprehensive overview
- [`docs/SPOTS_BUSINESS_OVERVIEW.md`](docs/SPOTS_BUSINESS_OVERVIEW.md) - Business overview

---

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

1. **Read the philosophy:** Understand "Doors, Not Badges" before contributing
2. **Follow the methodology:** See [`docs/plans/methodology/DEVELOPMENT_METHODOLOGY.md`](docs/plans/methodology/DEVELOPMENT_METHODOLOGY.md)
3. **Check the master plan:** See [`docs/MASTER_PLAN.md`](docs/MASTER_PLAN.md) for current priorities
4. **Write tests:** All new features must include tests
5. **Follow code standards:** See `.cursorrules` for coding standards

### Development Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes following the development methodology
4. Write/update tests
5. Ensure all tests pass (`flutter test`)
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

---

## 📊 Project Status

- **Codebase:** 185,162+ lines of code across 549+ files
- **Test Coverage:** Comprehensive test suites (unit, integration, widget)
- **Platforms:** iOS, Android (macOS support in progress)
- **Backend:** Supabase + Firebase
- **Payment:** Stripe integration complete
- **AI/ML:** Quantum-inspired algorithms + ONNX models
- **Patents:** 29 innovations documented, 5 ready for filing

---

## 🔒 Security & Privacy

- **Offline-First:** Personal data never leaves device without explicit consent
- **AI2AI Privacy:** Only anonymized compatibility signals shared
- **No Surveillance:** No tracking, no data harvesting
- **GDPR Compliant:** Privacy by design
- **End-to-End Encryption:** Secure communication channels

---

## 📄 License

See [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

SPOTS is built on the philosophy that technology should open doors, not create barriers. Special thanks to all contributors who believe in authentic connections over algorithms.

---

## 📞 Contact & Links

- **GitHub:** [reis-ship-it/SPOTS](https://github.com/reis-ship-it/SPOTS)
- **Documentation:** See [`docs/`](docs/) directory
- **Issues:** [GitHub Issues](https://github.com/reis-ship-it/SPOTS/issues)

---

**"There is no secret to life. Just doors that haven't been opened yet."**

*SPOTS helps you find the keys.*

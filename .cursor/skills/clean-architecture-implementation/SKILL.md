---
name: clean-architecture-implementation
description: Enforces Clean Architecture layer separation (core, data, domain, presentation). Use when creating new features, organizing code, or ensuring proper dependency direction.
---

# Clean Architecture Implementation

## Layer Structure

```
lib/
├── core/          # Core business logic, models, services
├── data/          # Data sources, repositories (implementation)
├── domain/        # Use cases, repository interfaces
└── presentation/  # UI, BLoCs, widgets, pages
```

## Layer Responsibilities

### Core (`lib/core/`)
- Business logic
- Models (entities)
- Services
- Common utilities
- No framework dependencies (as much as possible)

### Domain (`lib/domain/`)
- Use cases (business logic workflows)
- Repository interfaces (abstract)
- Domain models/interfaces
- No implementation details
- Framework-independent

### Data (`lib/data/`)
- Repository implementations
- Data sources (local/remote)
- Data models (DTOs)
- Framework-specific (Sembast, HTTP, etc.)

### Presentation (`lib/presentation/`)
- UI components (widgets, pages)
- BLoCs (state management)
- Controllers
- Flutter-specific code

## Dependency Direction

**Dependencies flow inward:**
- Presentation → Domain ← Data
- Presentation → Core
- Data → Domain
- Domain → Core
- Core has no dependencies on other layers

```
Presentation → Domain ← Data
     ↓           ↓
    Core ←──────┘
```

## Examples

### ✅ GOOD: Correct Dependency Direction

```dart
// Domain (abstract interface)
abstract class SpotsRepository {
  Future<List<Spot>> getSpots();
}

// Data (implements domain interface)
class SpotsRepositoryImpl implements SpotsRepository {
  final SpotsRemoteDataSource remoteDataSource;
  final SpotsLocalDataSource localDataSource;
  
  // Implementation
}

// Domain (use case uses repository interface)
class GetSpotsUseCase {
  final SpotsRepository repository;
  
  Future<List<Spot>> call() => repository.getSpots();
}

// Presentation (uses use case)
class SpotsBloc extends Bloc<SpotsEvent, SpotsState> {
  final GetSpotsUseCase getSpotsUseCase;
  
  // Uses use case
}
```

### ❌ BAD: Wrong Dependency Direction

```dart
// Domain depending on data (WRONG)
import 'package:avrai/data/models/spot_model.dart'; // ❌

// Presentation depending on data (WRONG)
import 'package:avrai/data/repositories/spots_repository_impl.dart'; // ❌
```

## File Organization

### ✅ GOOD: Layer-Based Organization
```
lib/
├── core/
│   ├── models/
│   │   └── spot.dart
│   └── services/
│       └── spot_service.dart
├── domain/
│   ├── repositories/
│   │   └── spots_repository.dart
│   └── usecases/
│       └── get_spots_usecase.dart
├── data/
│   ├── datasources/
│   │   └── spots_remote_datasource.dart
│   └── repositories/
│       └── spots_repository_impl.dart
└── presentation/
    ├── pages/
    │   └── spots_page.dart
    └── blocs/
        └── spots_bloc.dart
```

## Service Patterns

### Core Services
Core services belong in `lib/core/services/`:
```dart
// lib/core/services/my_service.dart
class MyService {
  // Business logic
  // No Flutter dependencies
}
```

### Domain Use Cases
Use cases belong in `lib/domain/usecases/`:
```dart
// lib/domain/usecases/get_data_usecase.dart
class GetDataUseCase {
  final RepositoryInterface repository;
  
  Future<Data> call() {
    // Orchestrates business logic
  }
}
```

## Testing by Layer

```
test/
├── unit/
│   ├── models/          # Domain entities
│   ├── repositories/    # Data layer
│   ├── usecases/        # Business logic
│   ├── blocs/          # State management
│   └── services/       # Core services
├── integration/        # Cross-layer
└── widget/            # Presentation layer
```

## Reference

See existing architecture in:
- `lib/core/` - Core layer examples
- `lib/domain/` - Domain layer examples
- `lib/data/` - Data layer examples
- `lib/presentation/` - Presentation layer examples

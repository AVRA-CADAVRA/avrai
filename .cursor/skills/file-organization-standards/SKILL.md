---
name: file-organization-standards
description: Enforces file naming conventions, directory structure, one class per file, Clean Architecture layer placement. Use when creating new files, organizing code, or refactoring file structure.
---

# File Organization Standards

## Clean Architecture Layers

Follow Clean Architecture layer structure:

```
lib/
├── core/          # Core business logic, models, services
├── data/          # Data sources, repositories (implementation)
├── domain/        # Use cases, repository interfaces
└── presentation/  # UI, BLoCs, widgets, pages
```

## File Naming Conventions

### File Names
- Use `lowercase_with_underscores` for file names
- Match file name to primary class name
- Use descriptive names

**Examples:**
- `create_event_page.dart` → `CreateEventPage`
- `spot_details_page.dart` → `SpotDetailsPage`
- `auth_service.dart` → `AuthService`
- `spots_bloc.dart` → `SpotsBloc`

### Class Names
- Use `PascalCase` for classes, enums, typedefs
- Match class name to file name

**Examples:**
- File: `user_service.dart` → Class: `UserService`
- File: `spot_card.dart` → Class: `SpotCard`

## Directory Structure

### Core Layer
```
lib/core/
├── models/
│   ├── user.dart
│   └── spot.dart
├── services/
│   ├── auth_service.dart
│   └── storage_service.dart
└── utils/
    └── validators.dart
```

### Domain Layer
```
lib/domain/
├── repositories/
│   └── spots_repository.dart
└── usecases/
    ├── get_spots_usecase.dart
    └── create_spot_usecase.dart
```

### Data Layer
```
lib/data/
├── datasources/
│   ├── spots_remote_datasource.dart
│   └── spots_local_datasource.dart
└── repositories/
    └── spots_repository_impl.dart
```

### Presentation Layer
```
lib/presentation/
├── pages/
│   ├── auth/
│   │   ├── login_page.dart
│   │   └── signup_page.dart
│   └── spots/
│       ├── spots_page.dart
│       └── spot_details_page.dart
├── widgets/
│   ├── common/
│   │   └── custom_button.dart
│   └── spots/
│       └── spot_card.dart
└── blocs/
    ├── auth/
    │   └── auth_bloc.dart
    └── spots/
        └── spots_bloc.dart
```

## One Class Per File

**Rule:** One class per file (except closely related classes like models)

**✅ GOOD:**
```dart
// user.dart
class User {
  // User class
}

// user_service.dart
class UserService {
  // Service class
}
```

**✅ GOOD (Related Classes):**
```dart
// auth_events.dart
class SignInEvent {}
class SignUpEvent {}
class SignOutEvent {}

// auth_states.dart
class AuthInitial {}
class AuthLoading {}
class AuthAuthenticated {}
```

**❌ BAD:**
```dart
// services.dart (Multiple unrelated services)
class UserService {}
class SpotService {}
class EventService {}
```

## Grouping Related Files

Group related files in subdirectories:

```
lib/presentation/pages/auth/
├── login_page.dart
├── signup_page.dart
└── auth_wrapper.dart

lib/presentation/widgets/spots/
├── spot_card.dart
├── spot_list.dart
└── spot_picker.dart
```

## Naming Examples

### Pages
- `login_page.dart` → `LoginPage`
- `spot_details_page.dart` → `SpotDetailsPage`
- `create_event_page.dart` → `CreateEventPage`

### Services
- `auth_service.dart` → `AuthService`
- `storage_service.dart` → `StorageService`
- `payment_service.dart` → `PaymentService`

### BLoCs
- `auth_bloc.dart` → `AuthBloc`
- `spots_bloc.dart` → `SpotsBloc`
- `search_bloc.dart` → `SearchBloc`

### Widgets
- `spot_card.dart` → `SpotCard`
- `custom_button.dart` → `CustomButton`
- `offline_indicator.dart` → `OfflineIndicator`

## File Placement Rules

1. **Models** → `lib/core/models/` or `lib/domain/entities/`
2. **Services** → `lib/core/services/`
3. **Use Cases** → `lib/domain/usecases/`
4. **Repository Interfaces** → `lib/domain/repositories/`
5. **Repository Implementations** → `lib/data/repositories/`
6. **Data Sources** → `lib/data/datasources/`
7. **Pages** → `lib/presentation/pages/[feature]/`
8. **Widgets** → `lib/presentation/widgets/[feature]/` or `lib/presentation/widgets/common/`
9. **BLoCs** → `lib/presentation/blocs/[feature]/`

## Reference

Check existing structure before creating new files:
- `lib/core/` - Core layer examples
- `lib/presentation/pages/` - Page examples
- `lib/presentation/widgets/` - Widget examples

---
name: dependency-injection-getit
description: Guides GetIt dependency injection patterns for service registration. Use when creating new services, registering dependencies, or refactoring service architecture.
---

# Dependency Injection with GetIt

## Core Pattern

All services must be registered in dependency injection containers using GetIt.

## Registration Locations

- **Core Services:** `lib/injection_container_core.dart`
- **Domain Services:** `lib/injection_container.dart`
- **AI Services:** `lib/injection_container_ai.dart`
- **Payment Services:** `lib/injection_container_payment.dart`
- **Admin Services:** `lib/injection_container_admin.dart`
- **Other Modules:** Separate containers as needed

## Registration Pattern

### Basic Registration
```dart
// Use registerLazySingleton (NOT registerSingleton)
sl.registerLazySingleton<MyService>(() => MyService(
  dependencyService: sl<DependencyService>(),
));
```

### With Dependencies
```dart
// Register dependencies BEFORE dependents
sl.registerLazySingleton(() => DependencyService());
sl.registerLazySingleton(() => MyService(
  dependencyService: sl<DependencyService>(),
));
```

### Check Before Registration
```dart
// Check if already registered to avoid duplicates
if (!sl.isRegistered<MyService>()) {
  sl.registerLazySingleton<MyService>(() => MyService(
    dependencyService: sl<DependencyService>(),
  ));
}
```

### With Documentation Comment
```dart
// Register MyService (for specific purpose description)
sl.registerLazySingleton<MyService>(() => MyService(
  dependencyService: sl<DependencyService>(),
));
```

## Service Constructor Pattern

```dart
class MyService {
  final DependencyService _dependencyService;
  final OptionalService? _optionalService;
  
  MyService({
    required DependencyService dependencyService,
    OptionalService? optionalService,
  })  : _dependencyService = dependencyService,
        _optionalService = optionalService;
}
```

## Dependency Order Rules

1. **Core services first** - Register foundational services (StorageService, Logger, Database) before others
2. **Dependencies before dependents** - Always register dependencies before services that depend on them
3. **Module separation** - Register core services, then domain services, then feature services

## Common Pitfalls

**❌ Circular Dependency:**
```dart
sl.registerLazySingleton(() => ServiceA(serviceB: sl<ServiceB>()));
sl.registerLazySingleton(() => ServiceB(serviceA: sl<ServiceA>())); // ERROR
```

**❌ Wrong Order:**
```dart
sl.registerLazySingleton(() => MyService(dep: sl<Dependency>())); // ERROR: Dependency not registered yet
sl.registerLazySingleton(() => Dependency());
```

**❌ Wrong Lifecycle:**
```dart
sl.registerFactory(() => MyService()); // BAD: Should be singleton
```

## Reference

See existing registrations in:
- `lib/injection_container_core.dart`
- `lib/injection_container.dart`

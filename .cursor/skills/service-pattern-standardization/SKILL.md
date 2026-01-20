---
name: service-pattern-standardization
description: Standardizes service patterns: constructor injection, error handling, logging with developer.log(), service-to-service communication. Use when creating new services or refactoring existing services.
---

# Service Pattern Standardization

## Core Pattern

All services use constructor injection with required and optional dependencies.

## Service Structure

```dart
import 'dart:developer' as developer;
import 'package:avrai/core/services/logger.dart';

class MyService {
  final RequiredService _requiredService;
  final OptionalService? _optionalService;
  final AppLogger _logger = const AppLogger(
    defaultTag: 'MyService',
    minimumLevel: LogLevel.debug,
  );
  
  MyService({
    required RequiredService requiredService,
    OptionalService? optionalService,
  })  : _requiredService = requiredService,
        _optionalService = optionalService;
  
  Future<void> performOperation() async {
    _logger.info('Starting operation');
    try {
      // Service logic
      _logger.debug('Operation completed');
    } catch (e, st) {
      _logger.error('Operation failed', error: e, stackTrace: st);
      rethrow;
    }
  }
}
```

## Constructor Injection Pattern

### Required Dependencies
```dart
class MyService {
  final DependencyService _dependencyService;
  
  MyService({
    required DependencyService dependencyService,
  }) : _dependencyService = dependencyService;
}
```

### Optional Dependencies
```dart
class MyService {
  final RequiredService _requiredService;
  final OptionalService? _optionalService;
  
  MyService({
    required RequiredService requiredService,
    OptionalService? optionalService,
  })  : _requiredService = requiredService,
        _optionalService = optionalService;
  
  void useOptional() {
    _optionalService?.doSomething(); // Null-safe access
  }
}
```

## Error Handling

Always handle errors explicitly:

```dart
Future<Result<String>> performOperation() async {
  try {
    final result = await _dependencyService.getData();
    return Result.success(result);
  } on NetworkException catch (e) {
    _logger.error('Network error', error: e);
    return Result.failure('Connection failed');
  } catch (e, st) {
    _logger.error('Unexpected error', error: e, stackTrace: st);
    return Result.failure('Operation failed');
  }
}
```

## Logging Pattern

Use `AppLogger` for consistent logging:

```dart
class MyService {
  final AppLogger _logger = const AppLogger(
    defaultTag: 'MyService',
    minimumLevel: LogLevel.debug,
  );
  
  Future<void> operation() async {
    _logger.info('Starting operation');
    _logger.debug('Processing data: $data');
    _logger.error('Operation failed', error: e, stackTrace: st);
  }
}
```

## Service-to-Service Communication

Services communicate through dependency injection:

```dart
// Service A depends on Service B
class ServiceA {
  final ServiceB _serviceB;
  
  ServiceA({required ServiceB serviceB}) : _serviceB = serviceB;
  
  Future<void> operation() async {
    await _serviceB.doSomething(); // Use injected service
  }
}
```

## Registration Pattern

Register in dependency injection:

```dart
// Register dependencies first
sl.registerLazySingleton(() => ServiceB());

// Register service with dependencies
sl.registerLazySingleton(() => ServiceA(
  serviceB: sl<ServiceB>(),
));
```

## Special Patterns

### Infrastructure Services (Singleton Pattern)
Some infrastructure services may use singleton pattern:

```dart
class StorageService {
  static StorageService? _instance;
  StorageService._();
  
  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }
}
```

**Note:** Still register in DI container:
```dart
final storageService = StorageService.instance;
await storageService.init();
sl.registerLazySingleton<StorageService>(() => storageService);
```

## Reference

See existing service patterns in:
- `lib/core/services/` - Core service examples
- `lib/injection_container_core.dart` - Registration examples

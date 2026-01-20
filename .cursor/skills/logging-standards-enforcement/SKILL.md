---
name: logging-standards-enforcement
description: Enforces mandatory logging standards using developer.log() instead of print(). Use when writing production code, reviewing code, or fixing logging violations.
---

# Logging Standards Enforcement

## Mandatory Rule

**❌ NEVER use `print()` or `debugPrint()` in production code**
**✅ ALWAYS use `developer.log()` from `dart:developer` for logging**

## Logging Pattern

```dart
import 'dart:developer' as developer;

// ✅ GOOD
developer.log('User signed in', name: 'AuthService');
developer.log('Operation failed', error: e, stackTrace: st, name: 'ServiceName');
developer.log('Data loaded successfully', name: 'DataService', level: 1000);

// ❌ BAD
print('User signed in');
debugPrint('Operation failed');
```

## Log Levels

Use appropriate log levels:
- `developer.log(..., level: 700)` - `LogLevel.debug`
- `developer.log(..., level: 800)` - `LogLevel.info`
- `developer.log(..., level: 900)` - `LogLevel.warning`
- `developer.log(..., level: 1000)` - `LogLevel.error`

## Structured Logging with AppLogger

When `AppLogger` service is available, use it for consistent patterns:

```dart
import 'package:avrai/core/services/logger.dart';

class MyService {
  final AppLogger _logger = const AppLogger(
    defaultTag: 'MyService',
    minimumLevel: LogLevel.debug,
  );

  Future<void> doSomething() async {
    _logger.info('Starting operation', tag: 'doSomething');
    try {
      // operation
      _logger.debug('Operation completed', tag: 'doSomething');
    } catch (e, st) {
      _logger.error('Operation failed', error: e, stackTrace: st, tag: 'doSomething');
    }
  }
}
```

## Exception

Test files may use `print()` for debugging test output only:
```dart
// ✅ OK in test files
void main() {
  print('Running test suite...');
}
```

## Error Logging Pattern

Always include context when logging errors:

```dart
try {
  await operation();
} catch (e, st) {
  developer.log(
    'Operation failed',
    error: e,
    stackTrace: st,
    name: 'ServiceName',
  );
}
```

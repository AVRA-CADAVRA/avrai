# Error Handling Standardization Guide

**Date:** November 30, 2025, 1:58 PM CST  
**Agent:** Agent 1 (Backend & Integration Specialist)  
**Purpose:** Standard error handling pattern for all services  
**Status:** 🟢 Active Standard

---

## 🎯 Standard Error Handling Pattern

### Pattern: AppLogger with Structured Logging

**All services MUST use this pattern:**

```dart
import 'package:spots/core/services/logger.dart';

class ServiceName {
  static const String _logName = 'ServiceName';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );
  
  Future<ReturnType> methodName() async {
    try {
      _logger.info('Starting operation: methodName', tag: _logName);
      
      // ... operation logic ...
      
      _logger.info('Operation completed successfully', tag: _logName);
      return result;
    } catch (e, stackTrace) {
      _logger.error(
        'Operation failed: methodName',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
      rethrow; // Or handle appropriately
    }
  }
}
```

---

## 📋 Error Handling Requirements

### 1. Use AppLogger (Not developer.log)

**✅ CORRECT:**
```dart
final AppLogger _logger = const AppLogger(
  defaultTag: 'SPOTS',
  minimumLevel: LogLevel.debug,
);

_logger.info('Message', tag: _logName);
_logger.error('Error', error: e, tag: _logName);
```

**❌ INCORRECT:**
```dart
import 'dart:developer' as developer;

developer.log('Message', name: 'ServiceName');
```

### 2. Consistent Log Levels

- **debug**: Detailed debugging information
- **info**: Normal operation messages
- **warn**: Warning messages (non-critical issues)
- **error**: Error messages (exceptions, failures)

### 3. Error Message Format

**User-friendly error messages:**
- Clear and actionable
- No technical jargon when exposed to users
- Include context when helpful

**Example:**
```dart
throw Exception('Unable to process payment. Please check your payment method and try again.');
```

### 4. Try-Catch Blocks

**All async operations MUST have try-catch:**
```dart
Future<Result> operation() async {
  try {
    // ... operation ...
  } catch (e, stackTrace) {
    _logger.error('Operation failed', error: e, stackTrace: stackTrace, tag: _logName);
    rethrow; // Or handle gracefully
  }
}
```

### 5. Error Recovery

**Where appropriate, add error recovery:**
- Retry logic for transient errors
- Fallback mechanisms
- Graceful degradation

---

## 🔄 Migration Checklist

For each service:

- [ ] Replace `developer.log` with `AppLogger`
- [ ] Add try-catch blocks to all async methods
- [ ] Standardize error messages (user-friendly)
- [ ] Add stack traces to error logs
- [ ] Document error handling in service comments
- [ ] Add error recovery where appropriate

---

## 📝 Examples

### Before (Inconsistent):
```dart
import 'dart:developer' as developer;

class ServiceName {
  static const String _logName = 'ServiceName';
  
  Future<void> method() async {
    developer.log('Starting', name: _logName);
    // ... no error handling ...
  }
}
```

### After (Standardized):
```dart
import 'package:spots/core/services/logger.dart';

class ServiceName {
  static const String _logName = 'ServiceName';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );
  
  Future<void> method() async {
    try {
      _logger.info('Starting operation: method', tag: _logName);
      // ... operation ...
      _logger.info('Operation completed successfully', tag: _logName);
    } catch (e, stackTrace) {
      _logger.error(
        'Operation failed: method',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
      rethrow;
    }
  }
}
```

---

**Status:** Active standard - Apply to all services


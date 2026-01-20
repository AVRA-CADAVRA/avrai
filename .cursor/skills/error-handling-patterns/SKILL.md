---
name: error-handling-patterns
description: Enforces comprehensive error handling: explicit catch blocks, user-friendly messages, Result/Either patterns. Use when writing async code, service methods, or handling exceptions.
---

# Error Handling Patterns

## Mandatory Rules

**✅ ALWAYS handle errors explicitly** - never silently swallow exceptions
**✅ Use try-catch blocks** for async operations that can fail
**✅ Provide user-friendly error messages** in UI
**✅ Log errors with context** using `developer.log()`
**❌ NEVER use empty catch blocks** without logging

## Basic Pattern

```dart
try {
  await operation();
} on SpecificException catch (e) {
  developer.log('Operation failed', error: e, name: 'ServiceName');
  // Handle specific error
} catch (e, st) {
  developer.log('Unexpected error', error: e, stackTrace: st, name: 'ServiceName');
  // Handle generic error
}
```

## Async Operations

Always handle errors in async methods:

```dart
Future<Result<String>> fetchData() async {
  try {
    final data = await repository.fetch();
    return Result.success(data);
  } on NetworkException catch (e) {
    developer.log('Network error', error: e, name: 'DataService');
    return Result.failure('Connection failed. Please check your internet.');
  } on ValidationException catch (e) {
    developer.log('Validation error', error: e, name: 'DataService');
    return Result.failure('Invalid data format.');
  } catch (e, st) {
    developer.log('Unexpected error', error: e, stackTrace: st, name: 'DataService');
    return Result.failure('Something went wrong. Please try again.');
  }
}
```

## Service Error Handling

```dart
class MyService {
  final AppLogger _logger = const AppLogger(defaultTag: 'MyService');
  
  Future<void> performOperation() async {
    try {
      await riskyOperation();
      _logger.info('Operation completed successfully');
    } on SpecificException catch (e) {
      _logger.error('Specific error occurred', error: e);
      throw ServiceException('User-friendly message');
    } catch (e, st) {
      _logger.error('Unexpected error', error: e, stackTrace: st);
      throw ServiceException('Something went wrong');
    }
  }
}
```

## BLoC Error Handling

```dart
Future<void> _onLoadData(
  LoadData event,
  Emitter<MyState> emit,
) async {
  emit(MyLoading());
  try {
    final data = await useCase.getData();
    emit(MyLoaded(data));
  } on NetworkException catch (e) {
    emit(MyError('Connection failed. Please check your internet.'));
  } catch (e, st) {
    developer.log('Unexpected error', error: e, stackTrace: st, name: 'MyBloc');
    emit(MyError('Something went wrong. Please try again.'));
  }
}
```

## Result/Either Patterns

For operations that can fail, consider Result pattern:

```dart
// Result pattern
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

class Failure<T> extends Result<T> {
  final String error;
  const Failure(this.error);
}

// Usage
Future<Result<User>> getUser(String id) async {
  try {
    final user = await repository.getUser(id);
    return Success(user);
  } catch (e) {
    return Failure('Failed to load user: ${e.toString()}');
  }
}
```

## UI Error Display

Always show user-friendly messages:

```dart
// In widget
if (state is MyError) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(state.message), // User-friendly message
      backgroundColor: AppColors.error,
    ),
  );
}
```

## Anti-Patterns

**❌ Silent Failure:**
```dart
try {
  await operation();
} catch (e) {
  // Silent failure - BAD!
}
```

**❌ Generic Catch Only:**
```dart
try {
  await operation();
} catch (e) {
  // Missing specific exception handling - BAD!
}
```

**❌ No Logging:**
```dart
try {
  await operation();
} catch (e) {
  showError('Error'); // Missing error logging - BAD!
}
```

## Best Practices

1. **Catch specific exceptions first**, then generic
2. **Always log errors** with context and stack trace
3. **Provide user-friendly messages** (hide technical details)
4. **Use Result/Either patterns** for operations that can fail
5. **Don't swallow exceptions** without handling or logging

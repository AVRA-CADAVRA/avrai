---
name: async-await-patterns
description: Enforces async/await patterns over .then() chains, proper error handling, mounted checks. Use when writing async code, handling Futures, or working with async operations.
---

# Async/Await Patterns

## Core Rule

**✅ ALWAYS use `async`/`await` instead of `.then()` chains**
**✅ ALWAYS handle errors in async operations** (try-catch)
**✅ Check `mounted` before `setState()`** in async callbacks (Flutter widgets)

## Basic Pattern

```dart
// ✅ GOOD
Future<void> loadData() async {
  try {
    final data = await repository.fetch();
    if (mounted) {
      setState(() => _data = data);
    }
  } catch (e, st) {
    developer.log('Failed to load data', error: e, stackTrace: st);
  }
}

// ❌ BAD
void loadData() {
  repository.fetch().then((data) {
    setState(() => _data = data); // Missing mounted check
  }).catchError((e) {
    // Silent failure
  });
}
```

## Error Handling

Always wrap async operations in try-catch:

```dart
Future<Result<User>> getUser(String id) async {
  try {
    final user = await repository.getUser(id);
    return Success(user);
  } on NetworkException catch (e) {
    return Failure('Network error: ${e.message}');
  } catch (e, st) {
    developer.log('Unexpected error', error: e, stackTrace: st, name: 'UserService');
    return Failure('Failed to load user');
  }
}
```

## Widget Mounted Checks

Always check `mounted` before `setState()` in async callbacks:

```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void initState() {
    super.initState();
    loadData();
  }
  
  Future<void> loadData() async {
    try {
      final data = await repository.fetch();
      if (mounted) { // ✅ Check mounted
        setState(() {
          _data = data;
        });
      }
    } catch (e, st) {
      if (mounted) { // ✅ Check mounted
        setState(() {
          _error = e.toString();
        });
      }
    }
  }
}
```

## Multiple Async Operations

```dart
// ✅ GOOD: Sequential with error handling
Future<void> loadAllData() async {
  try {
    final user = await loadUser();
    final settings = await loadSettings();
    final preferences = await loadPreferences();
    
    if (mounted) {
      setState(() {
        _user = user;
        _settings = settings;
        _preferences = preferences;
      });
    }
  } catch (e, st) {
    developer.log('Failed to load data', error: e, stackTrace: st);
  }
}

// ✅ GOOD: Parallel with error handling
Future<void> loadAllDataParallel() async {
  try {
    final results = await Future.wait([
      loadUser(),
      loadSettings(),
      loadPreferences(),
    ]);
    
    if (mounted) {
      setState(() {
        _user = results[0];
        _settings = results[1];
        _preferences = results[2];
      });
    }
  } catch (e, st) {
    developer.log('Failed to load data', error: e, stackTrace: st);
  }
}
```

## FutureOr Pattern

When method can be sync or async:

```dart
FutureOr<String> getData() {
  if (_cache != null) {
    return _cache!; // Sync return
  }
  return fetchFromServer(); // Async return
}
```

## Completer Pattern (Rare)

Only use `Completer` when necessary (prefer async/await):

```dart
Future<String> convertCallback() {
  final completer = Completer<String>();
  
  someCallbackApi((result) {
    completer.complete(result);
  });
  
  return completer.future;
}
```

## Anti-Patterns

**❌ .then() Chains:**
```dart
repository.fetch()
  .then((data) => processData(data))
  .then((processed) => saveData(processed))
  .catchError((e) => handleError(e)); // BAD
```

**❌ Missing Error Handling:**
```dart
Future<void> loadData() async {
  final data = await repository.fetch(); // No try-catch - BAD
  setState(() => _data = data);
}
```

**❌ Missing Mounted Check:**
```dart
Future<void> loadData() async {
  final data = await repository.fetch();
  setState(() => _data = data); // No mounted check - BAD
}
```

**❌ Future.value(null).then():**
```dart
Future.value(null).then((_) => doSomething()); // Use await instead
```

## Best Practices

1. Always use async/await for async operations
2. Always wrap async operations in try-catch
3. Always check `mounted` before `setState()` in widgets
4. Use `FutureOr<T>` when method can be sync or async
5. Prefer async/await over Completer when possible
6. Use `Future.wait()` for parallel operations
7. Never use `.then()` chains in new code

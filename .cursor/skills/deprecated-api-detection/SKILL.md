---
name: deprecated-api-detection
description: Detects and flags deprecated Flutter/Dart APIs, suggests modern equivalents. Use when reviewing code, refactoring, or ensuring code uses modern APIs.
---

# Deprecated API Detection

## Mandatory Rule

**✅ Zero deprecated API warnings** - always use modern Flutter/Dart APIs
**✅ Check Flutter/Dart migration guides** for modern equivalents

## Common Deprecations

### Flutter Widgets

**❌ Deprecated:**
```dart
RaisedButton(
  onPressed: () {},
  child: Text('Click'),
)
```

**✅ Modern:**
```dart
ElevatedButton(
  onPressed: () {},
  child: Text('Click'),
)
```

### Flutter Testing

**❌ Deprecated:**
```dart
tester.binding.window.physicalSize = Size(800, 600);
```

**✅ Modern:**
```dart
tester.view.physicalSize = Size(800, 600);
```

### Flutter Text Theme

**❌ Deprecated:**
```dart
Theme.of(context).textTheme.headline
```

**✅ Modern:**
```dart
Theme.of(context).textTheme.headlineMedium
```

## Detection Methods

### IDE Warnings
Most IDEs highlight deprecated APIs automatically:
- Yellow squiggly lines
- Deprecation warnings in Problems panel
- Hover tooltips showing deprecation info

### Static Analysis
Run static analysis to detect deprecations:
```bash
flutter analyze
dart analyze
```

### Migration Guides
Check Flutter/Dart migration guides for common deprecations:
- Flutter Migration Guide
- Dart Migration Guide
- Breaking Changes documentation

## Modern API Patterns

### Material 3
Use Material 3 widgets when available:
```dart
// ✅ Modern Material 3
Card(
  elevation: 0, // Use shadowColor instead
  shape: RoundedRectangleBorder(...),
)
```

### Null Safety
Use null-safe APIs:
```dart
// ✅ Modern null-safe
String? getValue() => _value;
final result = getValue() ?? 'default';
```

### Async/Await
Use async/await instead of deprecated patterns:
```dart
// ✅ Modern async/await
Future<String> fetchData() async {
  return await repository.getData();
}
```

## Refactoring Pattern

When encountering deprecated API:

1. **Identify deprecation** - Read deprecation message
2. **Find modern equivalent** - Check migration guide
3. **Update code** - Replace with modern API
4. **Test changes** - Verify behavior unchanged
5. **Remove old code** - Clean up deprecated usage

## Common Deprecations Checklist

- [ ] No `RaisedButton` (use `ElevatedButton`)
- [ ] No `FlatButton` (use `TextButton`)
- [ ] No `OutlineButton` (use `OutlinedButton`)
- [ ] No `tester.binding.window` (use `tester.view`)
- [ ] No deprecated text theme names (use `headlineMedium` not `headline`)
- [ ] No deprecated HTTP methods
- [ ] No deprecated image loading APIs
- [ ] No deprecated route APIs

## Tools

- **Flutter analyze** - Detects deprecations
- **IDE warnings** - Highlights deprecated APIs
- **Migration guides** - Provides modern equivalents

## Reference

- Flutter Migration Guide
- Dart Migration Guide
- Breaking Changes documentation

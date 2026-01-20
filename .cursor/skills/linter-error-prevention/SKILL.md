---
name: linter-error-prevention
description: Enforces zero linter errors, common issue prevention, code cleanup. Use when writing code, reviewing code, or ensuring code quality standards.
---

# Linter Error Prevention

## Mandatory Rule

**✅ Zero linter errors before completion**
**✅ Zero warnings before completion**
**✅ Follow Dart style guide**

## Common Linter Issues

### Unused Imports
```dart
// ❌ BAD: Unused import
import 'package:unused/package.dart';

class MyClass {
  // Doesn't use unused package
}

// ✅ GOOD: Remove unused imports
class MyClass {
  // No unused imports
}
```

### Unused Variables
```dart
// ❌ BAD: Unused variable
void method() {
  final unused = calculateValue();
  doSomething();
}

// ✅ GOOD: Use variable or remove
void method() {
  final value = calculateValue();
  doSomething(value);
}
```

### Missing Required Parameters
```dart
// ❌ BAD: Missing required parameter
createUser(name: 'John');

// ✅ GOOD: Provide required parameters
createUser(name: 'John', email: 'john@example.com');
```

### Const Constructor Warnings
```dart
// ❌ BAD: Const constructor error
const MyWidget(
  required this.value, // Required parameters can't be const
)

// ✅ GOOD: Remove const if constructor isn't const
MyWidget(
  required this.value,
)
```

## Linter Rules

### Enable Linter Rules
Check `analysis_options.yaml` for enabled linter rules:
```yaml
linter:
  rules:
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - avoid_print
    - prefer_single_quotes
```

### Common Rules

**prefer_const_constructors:**
```dart
// ✅ GOOD: Use const when possible
const Text('Hello')

// ❌ BAD: Not using const
Text('Hello')
```

**avoid_print:**
```dart
// ✅ GOOD: Use developer.log
developer.log('Message', name: 'ServiceName');

// ❌ BAD: Using print
print('Message');
```

**prefer_single_quotes:**
```dart
// ✅ GOOD: Single quotes
final text = 'Hello';

// ❌ BAD: Double quotes
final text = "Hello";
```

## Running Linter

### Command Line
```bash
flutter analyze
dart analyze
```

### IDE Integration
Most IDEs run linter automatically and show warnings.

## Fix Common Issues

### Automatic Fixes
Many linter issues can be auto-fixed:
```bash
dart fix --apply
flutter pub run dart_code_metrics:metrics analyze lib/
```

### Manual Fixes
For issues that can't be auto-fixed:
1. Read linter warning message
2. Understand the issue
3. Fix according to Dart style guide
4. Re-run linter to verify

## Pre-Commit Checklist

Before committing:
- [ ] Run `flutter analyze` - no errors
- [ ] Run `flutter analyze` - no warnings
- [ ] No unused imports
- [ ] No unused variables
- [ ] No const constructor errors
- [ ] Follow Dart style guide
- [ ] All linter rules satisfied

## Code Quality Standards

### Zero Tolerance
- Zero linter errors
- Zero deprecated API warnings
- Zero unused code (unless documented exception)

### Continuous Improvement
- Fix linter issues immediately
- Don't accumulate technical debt
- Keep codebase clean

## Reference

- `analysis_options.yaml` - Linter configuration
- Dart Style Guide
- Effective Dart Guide

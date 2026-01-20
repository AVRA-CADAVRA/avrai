---
name: test-quality-enforcement
description: Enforces test quality standards: behavior-focused tests, no property-only tests, round-trip JSON, comprehensive test blocks. Use when writing tests, reviewing test code, or ensuring test quality.
---

# Test Quality Enforcement

## Core Principle

**Test what the code DOES, not what it IS.**

## ✅ DO Test

- **Behavior** - What happens when you call a method?
- **Business Logic** - Calculations, validation, transformations
- **Error Handling** - How code handles failures, invalid inputs
- **User Interactions** - Widget taps, input, gestures, state changes
- **Round-trip JSON** - Serialization AND deserialization together
- **Edge Cases** - Empty states, error states, boundary conditions

## ❌ DON'T Test

- **Property Assignment** - `expect(model.id, equals('1'))` - Tests language, not behavior
- **Constructor-Only** - `test('should create', () { expect(obj, isNotNull); })` - Tests Dart works, not your code
- **Field-by-Field JSON** - Individual `expect(json['field'], ...)` checks - Use round-trip instead
- **Trivial Null Checks** - `expect(value, isNotNull)` without behavior - Test behavior with null
- **Over-Granular UI** - Separate tests for each UI element - Consolidate into comprehensive tests

## Test Patterns

### Comprehensive Test Blocks
Combine related checks into single tests:

```dart
// ✅ GOOD: Comprehensive test
test('should validate coordinates and throw ArgumentError for invalid values', () {
  expect(() => Spot(latitude: 200, longitude: 0), throwsArgumentError);
  expect(() => Spot(latitude: -100, longitude: 0), throwsArgumentError);
  expect(() => Spot(latitude: 0, longitude: 200), throwsArgumentError);
  expect(() => Spot(latitude: 0, longitude: -200), throwsArgumentError);
});

// ❌ BAD: Separate tests for each property
test('should have id', () {
  expect(model.id, equals('1'));
});
test('should have name', () {
  expect(model.name, equals('Test'));
});
```

### Round-Trip JSON
Always test serialization and deserialization together:

```dart
// ✅ GOOD: Round-trip JSON test
test('should serialize and deserialize correctly (round-trip)', () {
  final spot = Spot(
    id: '1',
    name: 'Test',
    latitude: 40.0,
    longitude: -74.0,
  );
  final restored = Spot.fromJson(spot.toJson());
  expect(restored, equals(spot));
});

// ❌ BAD: Field-by-field JSON checks
test('should serialize to JSON', () {
  final json = spot.toJson();
  expect(json['id'], equals('1'));
  expect(json['name'], equals('Test'));
  // ... many more lines
});
```

### Behavior-Driven Tests
Focus on what code does:

```dart
// ✅ GOOD: Tests behavior
test('should calculate compatibility score based on personality dimensions', () {
  final user1 = User(personality: Personality(...));
  final user2 = User(personality: Personality(...));
  
  final score = compatibilityCalculator.calculate(user1, user2);
  
  expect(score, greaterThan(0.0));
  expect(score, lessThanOrEqualTo(1.0));
});

// ❌ BAD: Tests structure
test('should have personality property', () {
  expect(user.personality, isNotNull);
});
```

## Test Documentation

Every test file must have comprehensive header:

```dart
/// SPOTS Component Testing
/// Date: [Current Date]
/// Purpose: [Specific testing goals]
/// 
/// Test Coverage:
/// - Feature 1: [Description]
/// - Feature 2: [Description]
/// - Edge Cases: [Description]
/// 
/// Dependencies:
/// - Mock 1: [Purpose]
/// - Service 2: [Purpose]
```

## Coverage Requirements

```yaml
Models: 100% required
Repositories: 95% required  
BLoCs: 100% required
Use Cases: 100% required
Services: 90% required
UI Components: 85% required
```

## Resources

- **Full Guide:** `docs/plans/test_refactoring/TEST_WRITING_GUIDE.md`
- **Quick Reference:** `docs/plans/test_refactoring/TEST_QUALITY_QUICK_REFERENCE.md`
- **Templates:** `test/templates/`
- **Quality Checker:** `dart run scripts/check_test_quality.dart [file]`

## Checklist

Before committing tests:
- [ ] Tests focus on behavior, not properties
- [ ] No constructor-only tests
- [ ] JSON tests use round-trip pattern
- [ ] Related checks consolidated into single tests
- [ ] Error handling cases included
- [ ] Test names are descriptive and behavior-focused
- [ ] File has documentation header with purpose

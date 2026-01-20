---
name: test-implementation-requirements
description: Enforces test implementation requirements: real dependencies, no mocks/stubs unless approved. Use when writing tests, reviewing test implementations, or ensuring tests use real functionality.
---

# Test Implementation Requirements

## Core Principle

**Tests must test real functionality. Mocks and stubs have strict limitations.**

## Mandatory Requirements

### ✅ REQUIRED
- **Real Functionality** - Tests exercise actual code paths and real dependencies
- **Real Dependencies** - Use actual services, repositories, and data sources
- **Integration Testing** - Prefer integration tests that test multiple components together
- **Real Data** - Use real data structures, real serialization, real validation

## Mocks - Rare Cases Only

**⚠️ Mocks require explicit approval and justification:**

**Before using any mock, you MUST:**
1. Explain why a mock is necessary (what makes this a rare case)
2. Explain what real functionality would be tested if not for the mock
3. Get explicit user approval before implementing

**Potentially acceptable rare cases:**
- External APIs that charge per request
- Hardware dependencies that don't exist in test environment
- Time-dependent operations requiring specific timing control
- Network failures difficult to simulate with real dependencies

**Even in rare cases:** Prefer real implementations with test doubles (fake implementations) over mocks.

## Stubs - Never Acceptable

**❌ STUBS - FORBIDDEN:**
- Stubs are **FORBIDDEN** in all cases
- Never use stubs as a replacement for real functionality
- Use real test implementations or get approval for mocks

## Test Pattern Examples

### ✅ GOOD: Real Dependencies
```dart
test('repository fetches data from database', () async {
  // Use real database (in-memory for tests)
  final database = await SembastDatabase.useInMemoryForTests();
  final repository = MyRepositoryImpl(
    dataSource: MyLocalDataSource(database),
  );
  
  // Test with real implementation
  final result = await repository.getData();
  expect(result, isNotNull);
});
```

### ❌ BAD: Mock Dependencies
```dart
test('repository fetches data', () {
  // ❌ Mock without justification
  final mockDataSource = MockDataSource();
  final repository = MyRepositoryImpl(dataSource: mockDataSource);
  
  when(() => mockDataSource.getData()).thenReturn('test');
  // Tests mock, not real functionality
});
```

## Checklist

- [ ] Tests use real functionality and real dependencies
- [ ] No stubs used anywhere
- [ ] If mocks are used, approval was obtained with explanation
- [ ] Mock usage is documented with justification
- [ ] Real behavior is tested, not just mocked behavior

## Reference

- `.cursorrules` - Test Implementation Requirements section

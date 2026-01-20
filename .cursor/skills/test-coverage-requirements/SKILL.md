---
name: test-coverage-requirements
description: Enforces test coverage requirements: models (100%), repositories (95%), BLoCs (100%), use cases (100%), services (90%). Use when writing tests, reviewing test coverage, or ensuring adequate test coverage.
---

# Test Coverage Requirements

## Coverage Targets

### Line Coverage
```yaml
Models: 100% required
Repositories: 95% required  
BLoCs: 100% required
Use Cases: 100% required
Services: 90% required
UI Components: 85% required
```

### Branch Coverage
```yaml
Critical Paths: 100% required
Error Handling: 95% required
Business Logic: 90% required
UI Interactions: 85% required
```

### Function Coverage
```yaml
Public Methods: 100% required
Private Methods: 80% required
Static Methods: 95% required
```

## Coverage by Component Type

### Models (100% Required)
Every model must have 100% coverage:
- All constructors
- All methods
- All serialization/deserialization
- All validation logic

### BLoCs (100% Required)
Every BLoC must have 100% coverage:
- All event handlers
- All state transitions
- All error handling paths

### Use Cases (100% Required)
Every use case must have 100% coverage:
- All business logic paths
- All error scenarios
- All validation

### Repositories (95% Required)
Repository implementations need 95% coverage:
- All CRUD operations
- All error handling
- All data transformation

### Services (90% Required)
Services need 90% coverage:
- Core functionality
- Error handling
- Integration points

## Running Coverage

```bash
# Generate coverage report
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Coverage Verification

### Pre-Commit Checklist
- [ ] Models: 100% coverage
- [ ] BLoCs: 100% coverage
- [ ] Use Cases: 100% coverage
- [ ] Repositories: ≥95% coverage
- [ ] Services: ≥90% coverage
- [ ] UI Components: ≥85% coverage

## Reference

- `test/quality_assurance/documentation_standards.dart` - Coverage requirements

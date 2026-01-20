---
name: test-template-generation
description: Generates test templates: unit, widget, integration, service tests following project patterns. Use when creating new tests or ensuring tests follow project standards.
---

# Test Template Generation

## Available Templates

Test templates are located in `test/templates/`:
- `unit_test_template.dart`
- `widget_test_template.dart`
- `integration_test_template.dart`
- `service_test_template.dart`

## Unit Test Template

```dart
/// SPOTS Component Unit Tests
/// Date: [Current Date]
/// Purpose: Test Component functionality
/// 
/// Test Coverage:
/// - Feature 1: [Description]
/// - Feature 2: [Description]
/// - Edge Cases: [Description]
/// 
/// Dependencies:
/// - Mock 1: [Purpose]
/// - Service 2: [Purpose]
/// 
/// ⚠️  TEST QUALITY GUIDELINES:
/// ❌ DON'T: Test property assignment (e.g., expect(model.id, equals('1')))
/// ❌ DON'T: Test constructor-only (e.g., test('should create', () { expect(obj, isNotNull); }))
/// ✅ DO: Test behavior, business logic, validation, error handling
/// ✅ DO: Consolidate related checks into comprehensive test blocks
/// 
/// See: docs/plans/test_refactoring/TEST_WRITING_GUIDE.md

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Import component under test
import 'package:avrai/core/path/component.dart';

// Mock dependencies
class MockDependency extends Mock implements Dependency {}

void main() {
  group('Component', () {
    late Component component;
    late MockDependency mockDependency;
    
    setUp(() {
      mockDependency = MockDependency();
      component = Component(dependency: mockDependency);
    });
    
    group('performAction', () {
      test('should return success result when operation succeeds', () async {
        // Arrange
        when(() => mockDependency.method()).thenAnswer((_) async => 'result');
        
        // Act
        final result = await component.performAction('input');
        
        // Assert
        expect(result.value, equals('result'));
        expect(result.input, equals('input'));
        verify(() => mockDependency.method()).called(1);
      });
      
      test('should handle errors gracefully', () async {
        // Arrange
        when(() => mockDependency.method()).thenThrow(Exception('Error'));
        
        // Act & Assert
        expect(
          () => component.performAction('input'),
          throwsException,
        );
      });
    });
    
    group('calculateValue', () {
      test('should throw ArgumentError for invalid input', () {
        expect(
          () => component.calculateValue(-1),
          throwsArgumentError,
        );
      });
    });
  });
}
```

## Widget Test Template

```dart
/// SPOTS Widget Tests
/// Date: [Current Date]
/// Purpose: Test Widget behavior
/// 
/// Test Coverage:
/// - User interactions: [Description]
/// - State changes: [Description]
/// - Error states: [Description]

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:avrai/presentation/widgets/my_widget.dart';

void main() {
  group('MyWidget', () {
    testWidgets('should display widget content', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: MyWidget(),
        ),
      );
      
      // Assert
      expect(find.text('Expected Text'), findsOneWidget);
    });
    
    testWidgets('should handle user interaction', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: MyWidget(),
        ),
      );
      
      // Act
      await tester.tap(find.byType(Button));
      await tester.pump();
      
      // Assert
      expect(find.text('Updated Text'), findsOneWidget);
    });
  });
}
```

## Integration Test Template

```dart
/// SPOTS Integration Tests
/// Date: [Current Date]
/// Purpose: Test complete workflows
/// 
/// Test Coverage:
/// - End-to-end workflow: [Description]
/// - Integration points: [Description]

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:avrai/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Complete Workflow', () {
    testWidgets('should complete user journey', (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();
      
      // Act & Assert
      // Test complete user workflow
    });
  });
}
```

## Service Test Template

```dart
/// SPOTS Service Tests
/// Date: [Current Date]
/// Purpose: Test Service functionality
/// 
/// Test Coverage:
/// - Service methods: [Description]
/// - Error handling: [Description]
/// - Integration: [Description]

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:avrai/core/services/my_service.dart';

// Mock dependencies
class MockDependency extends Mock implements Dependency {}

void main() {
  group('MyService', () {
    late MyService service;
    late MockDependency mockDependency;
    
    setUp(() {
      mockDependency = MockDependency();
      service = MyService(dependency: mockDependency);
    });
    
    group('serviceMethod', () {
      test('should perform operation successfully', () async {
        // Test implementation
      });
    });
  });
}
```

## Using Templates

1. Copy template from `test/templates/`
2. Replace placeholder text
3. Update imports
4. Implement test cases
5. Remove template comments

## Reference

- `test/templates/unit_test_template.dart`
- `test/templates/widget_test_template.dart`
- `test/templates/integration_test_template.dart`
- `test/templates/service_test_template.dart`
- `docs/plans/test_refactoring/TEST_WRITING_GUIDE.md`

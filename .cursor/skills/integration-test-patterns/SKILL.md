---
name: integration-test-patterns
description: Guides integration test patterns: end-to-end workflows, cross-layer testing, real dependencies, no mocks unless approved. Use when writing integration tests, testing complete features, or validating system integration.
---

# Integration Test Patterns

## Core Principle

**Integration tests verify complete features work in the system.** Use real dependencies whenever possible.

## Integration Test Types

### End-to-End Workflows
Test complete user journeys from UI to data layer:

```dart
/// Complete user workflow: Sign up → Create spot → Add to list
testWidgets('complete user workflow', (tester) async {
  // Initialize app
  await tester.pumpWidget(MyApp());
  
  // Step 1: Sign up
  await tester.enterText(find.byKey(Key('email')), 'test@example.com');
  await tester.enterText(find.byKey(Key('password')), 'password123');
  await tester.tap(find.byKey(Key('signup_button')));
  await tester.pumpAndSettle();
  
  // Step 2: Create spot
  await tester.tap(find.byKey(Key('create_spot_button')));
  await tester.enterText(find.byKey(Key('spot_name')), 'Test Spot');
  await tester.tap(find.byKey(Key('save_button')));
  await tester.pumpAndSettle();
  
  // Step 3: Add to list
  await tester.tap(find.byKey(Key('add_to_list_button')));
  await tester.pumpAndSettle();
  
  // Verify: Spot appears in list
  expect(find.text('Test Spot'), findsOneWidget);
});
```

### Cross-Layer Testing
Test integration between layers:

```dart
/// Integration test: UI → BLoC → Use Case → Repository → Data Source
test('complete data flow integration', () async {
  // Arrange: Real dependencies (use test database)
  final database = await SembastDatabase.useInMemoryForTests();
  final repository = SpotsRepositoryImpl(
    localDataSource: SpotsLocalDataSource(database),
  );
  final useCase = GetSpotsUseCase(repository: repository);
  final bloc = SpotsBloc(getSpotsUseCase: useCase);
  
  // Act: Load spots
  bloc.add(LoadSpots());
  await bloc.stream.first;
  
  // Assert: Verify state
  expect(bloc.state, isA<SpotsLoaded>());
});
```

## Real Dependencies

**✅ Prefer real dependencies:**

```dart
/// Integration test with real database
test('save and retrieve spot from database', () async {
  // Use real Sembast database (in-memory for tests)
  final database = await SembastDatabase.useInMemoryForTests();
  final storageService = StorageService();
  
  // Save spot
  final spot = Spot(id: '1', name: 'Test Spot');
  await storageService.saveSpot(spot);
  
  // Retrieve spot
  final retrieved = await storageService.getSpot('1');
  
  // Verify
  expect(retrieved, equals(spot));
});
```

## Mocks - Rare Cases Only

**⚠️ Mocks require explicit approval and justification:**

```dart
/// Example: External API that charges per request
test('payment processing integration', () async {
  // Mock external payment API (can't call real API in tests)
  final mockPaymentAPI = MockPaymentAPI();
  when(() => mockPaymentAPI.processPayment(any()))
      .thenAnswer((_) async => PaymentResult.success());
  
  // Test with mocked external dependency
  final paymentService = PaymentService(
    paymentAPI: mockPaymentAPI, // Mock required here
  );
  
  // Test payment flow
  final result = await paymentService.processPayment(amount: 100);
  expect(result.isSuccess, isTrue);
});
```

**Justification required:**
- Why mock is necessary
- What real functionality would be tested if not for the mock
- Alternative approaches considered

## Service Integration

Test services working together:

```dart
/// Integration test: Multiple services working together
test('reservation creation workflow', () async {
  // Arrange: Real services
  final reservationService = ReservationService(...);
  final paymentService = PaymentService(...);
  final eventService = EventService(...);
  
  // Act: Complete workflow
  final reservation = await reservationService.createReservation(
    eventId: 'event1',
    ticketCount: 2,
  );
  
  // Assert: Verify all services updated correctly
  final event = await eventService.getEvent('event1');
  expect(event.availableTickets, equals(8)); // Was 10, now 8
  
  final payment = await paymentService.getPayment(reservation.paymentId);
  expect(payment.status, equals(PaymentStatus.completed));
});
```

## Test Organization

### Integration Test Structure
```
test/integration/
├── ai/
│   └── ai2ai_complete_integration_test.dart
├── auth/
│   └── auth_flow_integration_test.dart
└── spots/
    └── spot_creation_integration_test.dart
```

## Performance Targets

```yaml
Integration Tests:
  Target: <2000ms average
  Acceptable: <5000ms average
  Poor: >10000ms average
```

## Cleanup

Always clean up test data:

```dart
tearDown(() async {
  // Clean up test database
  await SembastDatabase.resetForTests();
  
  // Clean up test files
  await cleanupTestFiles();
});
```

## Reference

- `test/integration/ai/ai2ai_complete_integration_test.dart` - Complete integration example
- `docs/plans/test_refactoring/TEST_WRITING_GUIDE.md` - Test quality guide

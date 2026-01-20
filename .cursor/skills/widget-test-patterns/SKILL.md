---
name: widget-test-patterns
description: Guides widget test patterns: BLoC testing, user interactions, state changes, material app setup. Use when writing widget tests, testing UI components, or validating widget behavior.
---

# Widget Test Patterns

## Core Pattern

Widget tests verify UI behavior: user interactions, state changes, and visual display.

## Basic Widget Test Setup

```dart
testWidgets('widget displays correctly', (WidgetTester tester) async {
  // Arrange: Create widget
  await tester.pumpWidget(
    MaterialApp(
      home: MyWidget(),
    ),
  );
  
  // Assert: Verify UI elements
  expect(find.text('Hello'), findsOneWidget);
  expect(find.byType(Button), findsOneWidget);
});
```

## BLoC Integration Testing

```dart
testWidgets('widget reacts to BLoC state changes', (tester) async {
  // Arrange: Create BLoC
  final bloc = MyBloc(useCase: mockUseCase);
  
  // Create widget with BLoC
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider(
        create: (_) => bloc,
        child: MyWidget(),
      ),
    ),
  );
  
  // Act: Emit state change
  bloc.add(LoadData());
  await tester.pumpAndSettle();
  
  // Assert: Verify UI updated
  expect(find.text('Data loaded'), findsOneWidget);
});
```

## User Interaction Testing

```dart
testWidgets('widget handles user interactions', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MyWidget(),
    ),
  );
  
  // Act: Tap button
  await tester.tap(find.byKey(Key('submit_button')));
  await tester.pump();
  
  // Assert: Verify interaction result
  expect(find.text('Submitted'), findsOneWidget);
});
```

## Form Testing

```dart
testWidgets('form validates and submits correctly', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MyForm(),
    ),
  );
  
  // Act: Enter text
  await tester.enterText(find.byKey(Key('email_field')), 'test@example.com');
  await tester.enterText(find.byKey(Key('password_field')), 'password123');
  
  // Tap submit
  await tester.tap(find.byKey(Key('submit_button')));
  await tester.pumpAndSettle();
  
  // Assert: Verify submission
  expect(find.text('Success'), findsOneWidget);
});
```

## State Change Testing

```dart
testWidgets('widget updates on state change', (tester) async {
  final bloc = MyBloc();
  
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider(
        create: (_) => bloc,
        child: MyWidget(),
      ),
    ),
  );
  
  // Initial state
  expect(find.text('Loading'), findsOneWidget);
  
  // Change state
  bloc.add(DataLoadedEvent(data: 'Test Data'));
  await tester.pumpAndSettle();
  
  // Updated state
  expect(find.text('Test Data'), findsOneWidget);
  expect(find.text('Loading'), findsNothing);
});
```

## Error State Testing

```dart
testWidgets('widget displays error state correctly', (tester) async {
  final bloc = MyBloc();
  
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider(
        create: (_) => bloc,
        child: MyWidget(),
      ),
    ),
  );
  
  // Emit error state
  bloc.add(ErrorEvent(message: 'Error message'));
  await tester.pumpAndSettle();
  
  // Assert: Error displayed
  expect(find.text('Error message'), findsOneWidget);
  expect(find.byIcon(Icons.error), findsOneWidget);
});
```

## Reference

- `test/widget/pages/auth/login_page_test.dart` - Widget test example
- `test/helpers/widget_test_helpers.dart` - Test helpers

/// SPOTS ActionHistoryEntry Model Unit Tests
/// Date: December 23, 2025
/// Purpose: Test ActionHistoryEntry model functionality for Phase 9 Section 2
///
/// Test Coverage:
/// - JSON Serialization: Round-trip serialization/deserialization
/// - copyWith: Field updates and immutability
/// - Intent/Result Handling: Different action types and results
/// - Edge Cases: Missing fields, invalid data, null handling
///
/// Dependencies:
/// - ActionHistoryEntry: Action history data model
/// - ActionIntent/ActionResult: Action models
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai/action_history_entry.dart';
import 'package:avrai/core/ai/action_models.dart';

void main() {
  group('ActionHistoryEntry', () {
    late CreateSpotIntent testIntent;
    late ActionResult testResult;
    late DateTime testTimestamp;

    setUp(() {
      testTimestamp = DateTime(2025, 12, 23, 10, 0, 0);
      testIntent = const CreateSpotIntent(
        name: 'Test Spot',
        description: 'Test description',
        latitude: 40.7128,
        longitude: -74.0060,
        category: 'Test',
        userId: 'user123',
        confidence: 0.9,
      );
      testResult = ActionResult.success(
        intent: testIntent,
        message: 'Spot created successfully',
        data: {'spotId': 'spot123'},
      );
    });

    group('JSON Serialization', () {
      test('should serialize and deserialize correctly (round-trip)', () {
        final entry = ActionHistoryEntry(
          id: 'entry1',
          intent: testIntent,
          result: testResult,
          timestamp: testTimestamp,
          canUndo: true,
          isUndone: false,
          userId: 'user123',
        );

        final json = entry.toJson();
        final restored = ActionHistoryEntry.fromJson(json);

        expect(restored.id, equals(entry.id));
        expect(restored.intent.type, equals(entry.intent.type));
        expect(restored.intent, isA<CreateSpotIntent>());
        expect((restored.intent as CreateSpotIntent).name, equals('Test Spot'));
        expect(restored.result.success, equals(entry.result.success));
        expect(restored.timestamp, equals(entry.timestamp));
        expect(restored.canUndo, equals(entry.canUndo));
        expect(restored.isUndone, equals(entry.isUndone));
        expect(restored.userId, equals(entry.userId));
      });

      test('should serialize and deserialize CreateListIntent correctly', () {
        const listIntent = CreateListIntent(
          title: 'Test List',
          description: 'Test list description',
          userId: 'user123',
          confidence: 0.8,
        );
        final listResult = ActionResult.success(intent: listIntent);

        final entry = ActionHistoryEntry(
          id: 'entry2',
          intent: listIntent,
          result: listResult,
          timestamp: testTimestamp,
          canUndo: true,
          userId: 'user123',
        );

        final json = entry.toJson();
        final restored = ActionHistoryEntry.fromJson(json);

        expect(restored.intent, isA<CreateListIntent>());
        expect(
            (restored.intent as CreateListIntent).title, equals('Test List'));
      });

      test('should serialize and deserialize AddSpotToListIntent correctly',
          () {
        const addIntent = AddSpotToListIntent(
          spotId: 'spot1',
          listId: 'list1',
          userId: 'user123',
          confidence: 0.7,
        );
        final addResult = ActionResult.success(intent: addIntent);

        final entry = ActionHistoryEntry(
          id: 'entry3',
          intent: addIntent,
          result: addResult,
          timestamp: testTimestamp,
          canUndo: true,
          userId: 'user123',
        );

        final json = entry.toJson();
        final restored = ActionHistoryEntry.fromJson(json);

        expect(restored.intent, isA<AddSpotToListIntent>());
        expect(
            (restored.intent as AddSpotToListIntent).spotId, equals('spot1'));
        expect(
            (restored.intent as AddSpotToListIntent).listId, equals('list1'));
      });

      test('should serialize and deserialize failure results correctly', () {
        final failureResult = ActionResult.failure(
          error: 'Test error',
        );

        final entry = ActionHistoryEntry(
          id: 'entry4',
          intent: testIntent,
          result: failureResult,
          timestamp: testTimestamp,
          canUndo: false,
          userId: 'user123',
        );

        final json = entry.toJson();
        final restored = ActionHistoryEntry.fromJson(json);

        expect(restored.result.success, isFalse);
        expect(restored.result.errorMessage, equals('Test error'));
      });

      test('should serialize and deserialize CreateEventIntent correctly', () {
        // Test business logic: CreateEventIntent serialization (new action type)
        final eventIntent = CreateEventIntent(
          userId: 'user123',
          templateId: 'coffee_tasting_tour',
          title: 'Coffee Tour',
          description: 'A fun coffee tour',
          startTime: DateTime(2025, 12, 25, 10, 0),
          maxAttendees: 20,
          price: 25.0,
          category: 'Coffee',
          confidence: 0.8,
        );
        final eventResult = ActionResult.success(intent: eventIntent);

        final entry = ActionHistoryEntry(
          id: 'entry5',
          intent: eventIntent,
          result: eventResult,
          timestamp: testTimestamp,
          canUndo: true,
          userId: 'user123',
        );

        final json = entry.toJson();
        final restored = ActionHistoryEntry.fromJson(json);

        expect(restored.intent, isA<CreateEventIntent>());
        final restoredIntent = restored.intent as CreateEventIntent;
        expect(restoredIntent.userId, equals('user123'));
        expect(restoredIntent.templateId, equals('coffee_tasting_tour'));
        expect(restoredIntent.title, equals('Coffee Tour'));
        expect(restoredIntent.description, equals('A fun coffee tour'));
        expect(restoredIntent.startTime, equals(DateTime(2025, 12, 25, 10, 0)));
        expect(restoredIntent.maxAttendees, equals(20));
        expect(restoredIntent.price, equals(25.0));
        expect(restoredIntent.category, equals('Coffee'));
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final original = ActionHistoryEntry(
          id: 'entry1',
          intent: testIntent,
          result: testResult,
          timestamp: testTimestamp,
          canUndo: true,
          isUndone: false,
          userId: 'user123',
        );

        final updated = original.copyWith(
          isUndone: true,
          canUndo: false,
        );

        expect(updated.id, equals(original.id));
        expect(updated.intent, equals(original.intent));
        expect(updated.result, equals(original.result));
        expect(updated.timestamp, equals(original.timestamp));
        expect(updated.isUndone, isTrue);
        expect(updated.canUndo, isFalse);
        expect(updated.userId, equals(original.userId));
      });

      test('should preserve original values when fields not specified', () {
        final original = ActionHistoryEntry(
          id: 'entry1',
          intent: testIntent,
          result: testResult,
          timestamp: testTimestamp,
          canUndo: true,
          isUndone: false,
          userId: 'user123',
        );

        final copy = original.copyWith();

        expect(copy.id, equals(original.id));
        expect(copy.intent, equals(original.intent));
        expect(copy.result, equals(original.result));
        expect(copy.timestamp, equals(original.timestamp));
        expect(copy.canUndo, equals(original.canUndo));
        expect(copy.isUndone, equals(original.isUndone));
        expect(copy.userId, equals(original.userId));
      });
    });

    group('Edge Cases', () {
      test('should handle isUndone default value correctly', () {
        final entry = ActionHistoryEntry(
          id: 'entry1',
          intent: testIntent,
          result: testResult,
          timestamp: testTimestamp,
          canUndo: true,
          userId: 'user123',
          // isUndone not specified, should default to false
        );

        expect(entry.isUndone, isFalse);
      });

      test('should handle JSON with missing isUndone field', () {
        final json = {
          'id': 'entry1',
          'intentType': 'create_spot',
          'intent': {
            'type': 'create_spot',
            'name': 'Test Spot',
            'description': 'Test',
            'latitude': 40.7128,
            'longitude': -74.0060,
            'category': 'Test',
            'userId': 'user123',
            'confidence': 0.9,
            'metadata': {},
          },
          'result': {
            'success': true,
            'successMessage': 'Success',
            'data': {},
          },
          'timestamp': testTimestamp.toIso8601String(),
          'canUndo': true,
          'userId': 'user123',
          // isUndone missing
        };

        final entry = ActionHistoryEntry.fromJson(json);
        expect(entry.isUndone, isFalse); // Should default to false
      });
    });
  });
}

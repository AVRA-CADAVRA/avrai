import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/ai/action_parser.dart';
import 'package:spots/core/ai/action_executor.dart';
import 'package:spots/core/ai/action_models.dart';
import 'package:geolocator/geolocator.dart';
import '../../helpers/test_helpers.dart';

/// Integration tests for Phase 5: Action Execution System
/// Tests the complete flow from parsing to execution
void main() {
  group('Action Execution Flow Integration', () {
    late ActionParser parser;
    late ActionExecutor executor;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      parser = ActionParser();
      // Note: In real integration test, executor would use real repositories
      // For now, we test the flow with mocked dependencies
      executor = ActionExecutor();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Create List Flow', () {
      test('should parse and validate create list intent', () async {
        final intent = await parser.parseAction(
          'Create a coffee shop list',
          userId: 'user123',
        );

        expect(intent, isNotNull);
        expect(intent, isA<CreateListIntent>());
        
        final canExecute = await parser.canExecute(intent!);
        expect(canExecute, isTrue);
      });

      test('should handle create list with quoted name', () async {
        final intent = await parser.parseAction(
          'Create a list called "My Favorite Places"',
          userId: 'user123',
        );

        expect(intent, isNotNull);
        final listIntent = intent as CreateListIntent;
        expect(listIntent.title, equals('My Favorite Places'));
      });
    });

    group('Create Spot Flow', () {
      test('should parse create spot intent with location', () async {
        final location = Position(
          latitude: 40.7128,
          longitude: -74.0060,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );

        final intent = await parser.parseAction(
          'Create a spot called "Central Park"',
          userId: 'user123',
          currentLocation: location,
        );

        expect(intent, isNotNull);
        expect(intent, isA<CreateSpotIntent>());
        
        final spotIntent = intent as CreateSpotIntent;
        expect(spotIntent.latitude, equals(40.7128));
        expect(spotIntent.longitude, equals(-74.0060));
      });
    });

    group('Add Spot to List Flow', () {
      test('should parse add spot to list intent', () async {
        final intent = await parser.parseAction(
          'Add Central Park to my coffee shop list',
          userId: 'user123',
        );

        expect(intent, isNotNull);
        expect(intent, isA<AddSpotToListIntent>());
        
        final addIntent = intent as AddSpotToListIntent;
        expect(addIntent.metadata['spotName'], isNotNull);
        expect(addIntent.metadata['listName'], isNotNull);
      });
    });

    group('Error Handling', () {
      test('should handle invalid commands gracefully', () async {
        final intent = await parser.parseAction(
          'What is the weather?',
          userId: 'user123',
        );

        expect(intent, isNull);
      });

      test('should reject intents with missing required fields', () async {
        final intent = CreateSpotIntent(
          name: '',
          description: 'Test',
          latitude: 40.7128,
          longitude: -74.0060,
          category: 'restaurant',
          userId: 'user123',
          confidence: 0.8,
        );

        final canExecute = await parser.canExecute(intent);
        expect(canExecute, isFalse);
      });
    });
  });
}


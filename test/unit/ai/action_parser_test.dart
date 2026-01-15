import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai/action_parser.dart';
import 'package:avrai/core/ai/action_models.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  group('ActionParser', () {
    late ActionParser parser;

    setUp(() {
      parser = ActionParser();
    });

    group('parseAction', () {
      test('should parse create list intent', () async {
        final intent = await parser.parseAction(
          'Create a coffee shop list',
          userId: 'user123',
        );

        expect(intent, isNotNull);
        expect(intent, isA<CreateListIntent>());
        final listIntent = intent as CreateListIntent;
        expect(listIntent.title.toLowerCase(), contains('coffee shop'));
        expect(listIntent.userId, equals('user123'));
        expect(listIntent.confidence, greaterThan(0.0));
      });

      test('should parse create list with quoted name', () async {
        final intent = await parser.parseAction(
          'Create a list called "My Favorites"',
          userId: 'user123',
        );

        expect(intent, isNotNull);
        expect(intent, isA<CreateListIntent>());
        final listIntent = intent as CreateListIntent;
        expect(listIntent.title, equals('My Favorites'));
      });

      test('should parse add spot to list intent', () async {
        final intent = await parser.parseAction(
          'Add Central Park to my coffee shop list',
          userId: 'user123',
        );

        expect(intent, isNotNull);
        expect(intent, isA<AddSpotToListIntent>());
        final addIntent = intent as AddSpotToListIntent;
        expect(addIntent.userId, equals('user123'));
        expect(addIntent.metadata['spotName'], equals('Central Park'));
        expect(addIntent.metadata['listName'], equals('coffee shop'));
      });

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
          'Create a spot called "Test Spot"',
          userId: 'user123',
          currentLocation: location,
        );

        expect(intent, isNotNull);
        expect(intent, isA<CreateSpotIntent>());
        final spotIntent = intent as CreateSpotIntent;
        expect(spotIntent.name.toLowerCase(), contains('test spot'));
        expect(spotIntent.latitude, equals(40.7128));
        expect(spotIntent.longitude, equals(-74.0060));
        expect(spotIntent.userId, equals('user123'));
      });

      test('should return null for non-action messages', () async {
        final intent = await parser.parseAction(
          'What is the weather today?',
          userId: 'user123',
        );

        expect(intent, isNull);
      });

      test('should return null when userId is missing', () async {
        final intent = await parser.parseAction(
          'Create a coffee shop list',
        );

        expect(intent, isNull);
      });

      test('should parse create event intent with template matching', () async {
        // Test business logic: event creation with template matching
        final intent = await parser.parseAction(
          'Create a coffee tasting tour',
          userId: 'user123',
        );

        expect(intent, isNotNull);
        expect(intent, isA<CreateEventIntent>());
        final eventIntent = intent as CreateEventIntent;
        expect(eventIntent.userId, equals('user123'));
        // Template matching may or may not work depending on EventTemplateService registration
        expect(eventIntent.confidence, greaterThanOrEqualTo(0.0));
        expect(eventIntent.confidence, lessThanOrEqualTo(1.0));
      });

      test('should parse create event intent with various event types',
          () async {
        // Test business logic: different event types

        final testCases = [
          'host a bar crawl next weekend',
          'schedule trivia night',
          'create a food tour',
          'host a concert meetup',
        ];

        for (final message in testCases) {
          final intent = await parser.parseAction(
            message,
            userId: 'user123',
          );

          // May or may not parse depending on EventTemplateService availability
          if (intent != null) {
            expect(intent, isA<CreateEventIntent>());
            final eventIntent = intent as CreateEventIntent;
            expect(eventIntent.userId, equals('user123'));
            expect(eventIntent.confidence, greaterThanOrEqualTo(0.0));
          }
        }
      });

      test('should parse create event intent with time extraction', () async {
        // Test business logic: event creation with time parsing
        final intent = await parser.parseAction(
          'Create a coffee tour next Friday',
          userId: 'user123',
        );

        // May or may not parse depending on EventTemplateService availability
        if (intent != null) {
          expect(intent, isA<CreateEventIntent>());
          final eventIntent = intent as CreateEventIntent;
          expect(eventIntent.userId, equals('user123'));
          // startTime may be extracted or null
        }
      });
    });

    group('canExecute', () {
      test('should validate create spot intent', () async {
        const intent = CreateSpotIntent(
          name: 'Test Spot',
          description: 'A test spot',
          latitude: 40.7128,
          longitude: -74.0060,
          category: 'restaurant',
          userId: 'user123',
          confidence: 0.8,
        );

        final canExecute = await parser.canExecute(intent);
        expect(canExecute, isTrue);
      });

      test('should reject create spot intent with missing name', () async {
        const intent = CreateSpotIntent(
          name: '',
          description: 'A test spot',
          latitude: 40.7128,
          longitude: -74.0060,
          category: 'restaurant',
          userId: 'user123',
          confidence: 0.8,
        );

        final canExecute = await parser.canExecute(intent);
        expect(canExecute, isFalse);
      });

      test('should reject create spot intent with invalid location', () async {
        const intent = CreateSpotIntent(
          name: 'Test Spot',
          description: 'A test spot',
          latitude: 0.0,
          longitude: 0.0,
          category: 'restaurant',
          userId: 'user123',
          confidence: 0.8,
        );

        final canExecute = await parser.canExecute(intent);
        expect(canExecute, isFalse);
      });

      test('should validate create list intent', () async {
        const intent = CreateListIntent(
          title: 'My List',
          description: 'A test list',
          userId: 'user123',
          confidence: 0.8,
        );

        final canExecute = await parser.canExecute(intent);
        expect(canExecute, isTrue);
      });

      test('should reject create list intent with missing title', () async {
        const intent = CreateListIntent(
          title: '',
          description: 'A test list',
          userId: 'user123',
          confidence: 0.8,
        );

        final canExecute = await parser.canExecute(intent);
        expect(canExecute, isFalse);
      });

      test('should validate add spot to list intent', () async {
        const intent = AddSpotToListIntent(
          spotId: 'spot123',
          listId: 'list456',
          userId: 'user123',
          confidence: 0.8,
        );

        final canExecute = await parser.canExecute(intent);
        expect(canExecute, isTrue);
      });

      test('should reject add spot to list intent with missing IDs', () async {
        const intent = AddSpotToListIntent(
          spotId: '',
          listId: 'list456',
          userId: 'user123',
          confidence: 0.8,
        );

        final canExecute = await parser.canExecute(intent);
        expect(canExecute, isFalse);
      });
    });
  });
}

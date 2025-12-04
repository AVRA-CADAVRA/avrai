import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/event_template.dart';
import 'package:spots/core/models/expertise_event.dart';

/// SPOTS EventTemplate Model Unit Tests
/// Date: December 1, 2025
/// Purpose: Test EventTemplate model functionality
/// 
/// Test Coverage:
/// - Model Creation: Constructor and properties
/// - Price Display: Free vs paid templates
/// - Time Calculations: Estimated end time
/// - Description Generation: Placeholder replacement
/// - JSON Serialization: toJson/fromJson
/// - Equality: Equatable implementation
/// 
/// Dependencies:
/// - ExpertiseEventType: Event type enum

void main() {
  group('EventTemplate', () {
    late EventTemplate template;
    late DateTime testStartTime;

    setUp(() {
      testStartTime = DateTime(2025, 12, 1, 14, 0); // Dec 1, 2025, 2:00 PM
      
      template = EventTemplate(
        id: 'coffee_tasting_tour',
        name: 'Coffee Tasting Tour',
        category: 'Coffee',
        eventType: ExpertiseEventType.tour,
        descriptionTemplate: 'Join {hostName} for a coffee tour at {location}!',
        defaultDuration: const Duration(hours: 2),
        defaultMaxAttendees: 15,
        suggestedPrice: 25.0,
        suggestedSpotTypes: ['coffee_shop', 'roastery'],
        recommendedSpotCount: 3,
        icon: '☕',
        tags: ['beginner-friendly', 'indoor'],
        metadata: {'vibeTracking': ['energy_preference']},
      );
    });

    group('Constructor and Properties', () {
      test('should create template with all required fields', () {
        expect(template.id, 'coffee_tasting_tour');
        expect(template.name, 'Coffee Tasting Tour');
        expect(template.category, 'Coffee');
        expect(template.eventType, ExpertiseEventType.tour);
        expect(template.descriptionTemplate, contains('{hostName}'));
        expect(template.defaultDuration, const Duration(hours: 2));
        expect(template.defaultMaxAttendees, 15);
        expect(template.suggestedPrice, 25.0);
        expect(template.recommendedSpotCount, 3);
        expect(template.icon, '☕');
      });

      test('should create template with default values', () {
        final minimalTemplate = EventTemplate(
          id: 'test_template',
          name: 'Test Template',
          category: 'Test',
          eventType: ExpertiseEventType.meetup,
          descriptionTemplate: 'Test description',
          defaultDuration: const Duration(hours: 1),
        );

        expect(minimalTemplate.defaultMaxAttendees, 20);
        expect(minimalTemplate.suggestedPrice, isNull);
        expect(minimalTemplate.suggestedSpotTypes, isEmpty);
        expect(minimalTemplate.recommendedSpotCount, 3);
        expect(minimalTemplate.icon, '📍');
        expect(minimalTemplate.tags, isEmpty);
        expect(minimalTemplate.metadata, isEmpty);
      });
    });

    group('Price Display', () {
      test('should identify free templates', () {
        // Create a template with null price directly (copyWith doesn't handle null explicitly)
        final freeTemplate = EventTemplate(
          id: 'free_template',
          name: 'Free Template',
          category: 'Test',
          eventType: template.eventType,
          descriptionTemplate: 'Test description',
          defaultDuration: template.defaultDuration,
          suggestedPrice: null, // Explicitly null
        );
        expect(freeTemplate.isFree, true);
        expect(freeTemplate.getPriceDisplay(), 'Free');
      });

      test('should identify paid templates', () {
        expect(template.isFree, false);
        expect(template.getPriceDisplay(), '\$25');
      });

      test('should handle zero price as free', () {
        final zeroPriceTemplate = template.copyWith(suggestedPrice: 0.0);
        expect(zeroPriceTemplate.isFree, true);
        expect(zeroPriceTemplate.getPriceDisplay(), 'Free');
      });

      test('should format price correctly', () {
        final expensiveTemplate = template.copyWith(suggestedPrice: 99.99);
        expect(expensiveTemplate.getPriceDisplay(), '\$100');
      });
    });

    group('Time Calculations', () {
      test('should calculate estimated end time correctly', () {
        final endTime = template.getEstimatedEndTime(testStartTime);
        expect(endTime, testStartTime.add(const Duration(hours: 2)));
      });

      test('should handle different durations', () {
        final longTemplate = template.copyWith(
          defaultDuration: const Duration(hours: 4),
        );
        final endTime = longTemplate.getEstimatedEndTime(testStartTime);
        expect(endTime, testStartTime.add(const Duration(hours: 4)));
      });
    });

    group('Description Generation', () {
      test('should generate title with host name', () {
        final title = template.generateTitle('John Doe');
        expect(title, 'Coffee Tasting Tour');
      });

      test('should generate description with placeholders', () {
        // Create a template with all placeholders
        final templateWithAllPlaceholders = template.copyWith(
          descriptionTemplate: 'Join {hostName} for a coffee tour at {location} with {spotCount} spots!',
        );
        final description = templateWithAllPlaceholders.generateDescription(
          hostName: 'John Doe',
          location: 'Downtown',
          spotCount: 5,
        );

        expect(description, contains('John Doe'));
        expect(description, contains('Downtown'));
        expect(description, contains('5'));
      });

      test('should handle missing optional placeholders', () {
        final description = template.generateDescription(
          hostName: 'John Doe',
        );

        expect(description, contains('John Doe'));
        expect(description, isNotEmpty);
      });

      test('should replace all placeholders', () {
        final templateWithAllPlaceholders = template.copyWith(
          descriptionTemplate: 'Join {hostName} at {location} for {spotCount} spots!',
        );

        final description = templateWithAllPlaceholders.generateDescription(
          hostName: 'Alice',
          location: 'Park',
          spotCount: 3,
        );

        expect(description, 'Join Alice at Park for 3 spots!');
        expect(description, isNot(contains('{')));
        expect(description, isNot(contains('}')));
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        final json = template.toJson();

        expect(json['id'], 'coffee_tasting_tour');
        expect(json['name'], 'Coffee Tasting Tour');
        expect(json['category'], 'Coffee');
        expect(json['eventType'], 'tour');
        expect(json['defaultDuration'], 120); // 2 hours in minutes
        expect(json['defaultMaxAttendees'], 15);
        expect(json['suggestedPrice'], 25.0);
        expect(json['recommendedSpotCount'], 3);
        expect(json['icon'], '☕');
        expect(json['tags'], ['beginner-friendly', 'indoor']);
      });

      test('should deserialize from JSON correctly', () {
        final json = template.toJson();
        final deserialized = EventTemplate.fromJson(json);

        expect(deserialized.id, template.id);
        expect(deserialized.name, template.name);
        expect(deserialized.category, template.category);
        expect(deserialized.eventType, template.eventType);
        expect(deserialized.defaultDuration, template.defaultDuration);
        expect(deserialized.defaultMaxAttendees, template.defaultMaxAttendees);
        expect(deserialized.suggestedPrice, template.suggestedPrice);
        expect(deserialized.recommendedSpotCount, template.recommendedSpotCount);
      });

      test('should handle null price in JSON', () {
        // Create a template with null price directly (copyWith doesn't handle null explicitly)
        final freeTemplate = EventTemplate(
          id: 'free_template',
          name: 'Free Template',
          category: 'Test',
          eventType: template.eventType,
          descriptionTemplate: 'Test description',
          defaultDuration: template.defaultDuration,
          suggestedPrice: null, // Explicitly null
        );
        final json = freeTemplate.toJson();
        final deserialized = EventTemplate.fromJson(json);

        expect(deserialized.suggestedPrice, isNull);
        expect(deserialized.isFree, true);
      });
    });

    group('Equality', () {
      test('should be equal when all properties match', () {
        final template2 = template.copyWith();
        expect(template, equals(template2));
      });

      test('should not be equal when properties differ', () {
        final template2 = template.copyWith(name: 'Different Name');
        expect(template, isNot(equals(template2)));
      });

      test('should handle equality with different metadata', () {
        final template2 = template.copyWith(
          metadata: {'different': 'metadata'},
        );
        expect(template, isNot(equals(template2)));
      });
    });

    group('Copy With', () {
      test('should create copy with updated fields', () {
        final updated = template.copyWith(
          name: 'Updated Name',
          suggestedPrice: 30.0,
        );

        expect(updated.name, 'Updated Name');
        expect(updated.suggestedPrice, 30.0);
        expect(updated.id, template.id); // Unchanged
        expect(updated.category, template.category); // Unchanged
      });

      test('should preserve all fields when copying', () {
        final copied = template.copyWith();
        expect(copied, equals(template));
      });
    });
  });
}


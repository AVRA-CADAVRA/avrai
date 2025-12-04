import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/event_template_service.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/spot.dart';
import '../../fixtures/model_factories.dart';

/// SPOTS EventTemplateService Unit Tests
/// Date: December 1, 2025
/// Purpose: Test EventTemplateService functionality
/// 
/// Test Coverage:
/// - Template Retrieval: Get all templates, by category, by type
/// - Template Filtering: Business templates, expert templates
/// - Template Search: Keyword search functionality
/// - Event Creation: Create events from templates
/// - Category Management: Get template categories
/// 
/// Dependencies:
/// - EventTemplate: Template model
/// - ExpertiseEvent: Event model
/// - UnifiedUser: User model

void main() {
  group('EventTemplateService', () {
    late EventTemplateService service;
    late UnifiedUser host;
    late List<Spot> testSpots;

    setUp(() {
      service = EventTemplateService();
      host = ModelFactories.createTestUser(
        id: 'host-1',
        displayName: 'Test Host',
      );
      testSpots = [
        ModelFactories.createTestSpot(name: 'Coffee Shop 1'),
        ModelFactories.createTestSpot(name: 'Coffee Shop 2'),
      ];
    });

    group('Template Retrieval', () {
      test('should return all templates', () {
        final templates = service.getAllTemplates();
        expect(templates, isNotEmpty);
        expect(templates.length, greaterThan(10)); // Should have default templates
      });

      test('should get template by ID', () {
        final template = service.getTemplate('coffee_tasting_tour');
        expect(template, isNotNull);
        expect(template?.id, 'coffee_tasting_tour');
        expect(template?.name, 'Coffee Tasting Tour');
      });

      test('should return null for non-existent template', () {
        final template = service.getTemplate('non_existent_template');
        expect(template, isNull);
      });

      test('should get templates by category', () {
        final coffeeTemplates = service.getTemplatesByCategory('Coffee');
        expect(coffeeTemplates, isNotEmpty);
        expect(coffeeTemplates.every((t) => t.category.toLowerCase() == 'coffee'), true);
      });

      test('should get templates by category case-insensitively', () {
        final coffeeTemplates1 = service.getTemplatesByCategory('Coffee');
        final coffeeTemplates2 = service.getTemplatesByCategory('coffee');
        expect(coffeeTemplates1.length, coffeeTemplates2.length);
      });

      test('should get templates by event type', () {
        final tourTemplates = service.getTemplatesByType(ExpertiseEventType.tour);
        expect(tourTemplates, isNotEmpty);
        expect(tourTemplates.every((t) => t.eventType == ExpertiseEventType.tour), true);
      });
    });

    group('Template Filtering', () {
      test('should get business templates', () {
        final businessTemplates = service.getBusinessTemplates();
        expect(businessTemplates, isNotEmpty);
        expect(
          businessTemplates.every((t) => t.metadata['businessOnly'] == true),
          true,
        );
      });

      test('should get expert templates (non-business)', () {
        final expertTemplates = service.getExpertTemplates();
        expect(expertTemplates, isNotEmpty);
        expect(
          expertTemplates.every((t) => t.metadata['businessOnly'] != true),
          true,
        );
      });
    });

    group('Template Search', () {
      test('should search templates by name', () {
        final results = service.searchTemplates('coffee');
        expect(results, isNotEmpty);
        expect(
          results.any((t) => t.name.toLowerCase().contains('coffee')),
          true,
        );
      });

      test('should search templates by category', () {
        final results = service.searchTemplates('food');
        expect(results, isNotEmpty);
        expect(
          results.any((t) => t.category.toLowerCase().contains('food')),
          true,
        );
      });

      test('should search templates by tags', () {
        final results = service.searchTemplates('beginner');
        expect(results, isNotEmpty);
        expect(
          results.any((t) => t.tags.any((tag) => tag.toLowerCase().contains('beginner'))),
          true,
        );
      });

      test('should return empty list for no matches', () {
        final results = service.searchTemplates('nonexistentquery12345');
        expect(results, isEmpty);
      });

      test('should be case-insensitive', () {
        final results1 = service.searchTemplates('COFFEE');
        final results2 = service.searchTemplates('coffee');
        expect(results1.length, results2.length);
      });
    });

    group('Event Creation', () {
      test('should create event from template with default values', () {
        final template = service.getTemplate('coffee_tasting_tour')!;
        final startTime = DateTime.now().add(const Duration(days: 7));

        final event = service.createEventFromTemplate(
          template: template,
          host: host,
          startTime: startTime,
        );

        expect(event, isA<ExpertiseEvent>());
        expect(event.title, contains(host.displayName));
        expect(event.category, template.category);
        expect(event.eventType, template.eventType);
        expect(event.host.id, host.id);
        expect(event.startTime, startTime);
        expect(event.endTime, template.getEstimatedEndTime(startTime));
        expect(event.maxAttendees, template.defaultMaxAttendees);
        expect(event.price, template.suggestedPrice);
        expect(event.isPaid, template.suggestedPrice != null && template.suggestedPrice! > 0);
      });

      test('should create event with custom title', () {
        final template = service.getTemplate('coffee_tasting_tour')!;
        final startTime = DateTime.now().add(const Duration(days: 7));
        const customTitle = 'My Custom Coffee Tour';

        final event = service.createEventFromTemplate(
          template: template,
          host: host,
          startTime: startTime,
          customTitle: customTitle,
        );

        expect(event.title, customTitle);
      });

      test('should create event with custom description', () {
        final template = service.getTemplate('coffee_tasting_tour')!;
        final startTime = DateTime.now().add(const Duration(days: 7));
        const customDescription = 'A custom event description';

        final event = service.createEventFromTemplate(
          template: template,
          host: host,
          startTime: startTime,
          customDescription: customDescription,
        );

        expect(event.description, customDescription);
      });

      test('should create event with selected spots', () {
        final template = service.getTemplate('coffee_tasting_tour')!;
        final startTime = DateTime.now().add(const Duration(days: 7));

        final event = service.createEventFromTemplate(
          template: template,
          host: host,
          startTime: startTime,
          selectedSpots: testSpots,
        );

        expect(event.spots.length, testSpots.length);
        expect(event.spots.first.name, testSpots.first.name);
      });

      test('should create event with custom max attendees', () {
        final template = service.getTemplate('coffee_tasting_tour')!;
        final startTime = DateTime.now().add(const Duration(days: 7));
        const customMaxAttendees = 30;

        final event = service.createEventFromTemplate(
          template: template,
          host: host,
          startTime: startTime,
          customMaxAttendees: customMaxAttendees,
        );

        expect(event.maxAttendees, customMaxAttendees);
      });

      test('should create event with custom price', () {
        final template = service.getTemplate('coffee_tasting_tour')!;
        final startTime = DateTime.now().add(const Duration(days: 7));
        const customPrice = 50.0;

        final event = service.createEventFromTemplate(
          template: template,
          host: host,
          startTime: startTime,
          customPrice: customPrice,
        );

        expect(event.price, customPrice);
        expect(event.isPaid, true);
      });

      test('should create free event from paid template', () {
        final template = service.getTemplate('coffee_tasting_tour')!;
        final startTime = DateTime.now().add(const Duration(days: 7));
        const customPrice = 0.0;

        final event = service.createEventFromTemplate(
          template: template,
          host: host,
          startTime: startTime,
          customPrice: customPrice,
        );

        expect(event.price, customPrice);
        expect(event.isPaid, false);
      });
    });

    group('Category Management', () {
      test('should return all categories', () {
        final categories = service.getCategories();
        expect(categories, isNotEmpty);
        expect(categories.length, greaterThan(5));
      });

      test('should return categories with correct structure', () {
        final categories = service.getCategories();
        for (final category in categories) {
          expect(category.id, isNotEmpty);
          expect(category.name, isNotEmpty);
          expect(category.icon, isNotEmpty);
        }
      });
    });

    group('Default Templates', () {
      test('should have coffee tasting tour template', () {
        final template = service.getTemplate('coffee_tasting_tour');
        expect(template, isNotNull);
        expect(template?.category, 'Coffee');
        expect(template?.eventType, ExpertiseEventType.tour);
      });

      test('should have bookstore walk template', () {
        final template = service.getTemplate('bookstore_walk');
        expect(template, isNotNull);
        expect(template?.category, 'Books');
        expect(template?.isFree, true);
      });

      test('should have business templates', () {
        final businessTemplates = service.getBusinessTemplates();
        expect(businessTemplates.length, greaterThan(0));
        
        final grandOpening = service.getTemplate('grand_opening');
        expect(grandOpening, isNotNull);
        expect(grandOpening?.metadata['businessOnly'], true);
      });
    });
  });
}


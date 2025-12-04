import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spots/core/services/event_template_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/models/event_template.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/spot.dart';
import '../fixtures/model_factories.dart';
import '../helpers/test_helpers.dart';

// Mock dependencies
class MockExpertiseEventService extends Mock implements ExpertiseEventService {}

/// SPOTS Event Template Integration Tests
/// Date: December 1, 2025
/// Purpose: Test EventTemplateService integration with event creation
/// 
/// Test Coverage:
/// - Template selection and event creation
/// - Template service + EventService integration
/// - Template-based event hosting flow
/// - Business vs expert template filtering
/// - Template search and filtering
/// 
/// Dependencies:
/// - EventTemplateService: Template management
/// - ExpertiseEventService: Event creation

void main() {
  group('Event Template Integration Tests', () {
    late EventTemplateService templateService;
    late MockExpertiseEventService mockEventService;
    late UnifiedUser testHost;
    late List<Spot> testSpots;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      
      templateService = EventTemplateService();
      mockEventService = MockExpertiseEventService();
      
      testHost = ModelFactories.createTestUser(
        id: 'host-123',
        displayName: 'Test Host',
      );
      
      testSpots = ModelFactories.createTestSpots(3);
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
      reset(mockEventService);
    });

    group('Template Selection and Event Creation', () {
      test('should create event from template with all fields pre-filled', () {
        // Arrange
        final templates = templateService.getAllTemplates();
        expect(templates, isNotEmpty);
        
        final template = templates.first;
        final startTime = DateTime.now().add(const Duration(days: 1));
        
        // Act
        final event = templateService.createEventFromTemplate(
          template: template,
          host: testHost,
          startTime: startTime,
          selectedSpots: testSpots,
        );
        
        // Assert
        expect(event, isNotNull);
        expect(event.host.id, testHost.id);
        expect(event.startTime, startTime);
        expect(event.endTime, template.getEstimatedEndTime(startTime));
        expect(event.category, template.category);
        expect(event.eventType, template.eventType);
      });

      test('should use template defaults when custom values not provided', () {
        // Arrange
        final template = templateService.getAllTemplates().first;
        final startTime = DateTime.now().add(const Duration(days: 1));
        
        // Act
        final event = templateService.createEventFromTemplate(
          template: template,
          host: testHost,
          startTime: startTime,
        );
        
        // Assert
        expect(event.maxAttendees, template.defaultMaxAttendees);
        expect(event.price, template.suggestedPrice);
        expect(event.description, contains(testHost.displayName));
      });

      test('should allow custom overrides for template values', () {
        // Arrange
        final template = templateService.getAllTemplates().first;
        final startTime = DateTime.now().add(const Duration(days: 1));
        const customTitle = 'Custom Event Title';
        const customMaxAttendees = 50;
        const customPrice = 30.0;
        
        // Act
        final event = templateService.createEventFromTemplate(
          template: template,
          host: testHost,
          startTime: startTime,
          customTitle: customTitle,
          customMaxAttendees: customMaxAttendees,
          customPrice: customPrice,
        );
        
        // Assert
        expect(event.title, customTitle);
        expect(event.maxAttendees, customMaxAttendees);
        expect(event.price, customPrice);
      });
    });

    group('Template Filtering Integration', () {
      test('should filter templates by category', () {
        // Arrange
        final allTemplates = templateService.getAllTemplates();
        expect(allTemplates, isNotEmpty);
        
        // Act
        final coffeeTemplates = templateService.getTemplatesByCategory('Coffee');
        
        // Assert
        expect(coffeeTemplates, isNotEmpty);
        for (final template in coffeeTemplates) {
          expect(template.category.toLowerCase(), contains('coffee'));
        }
      });

      test('should filter templates by event type', () {
        // Act
        final tourTemplates = templateService.getTemplatesByType(ExpertiseEventType.tour);
        
        // Assert
        for (final template in tourTemplates) {
          expect(template.eventType, ExpertiseEventType.tour);
        }
      });

      test('should separate business and expert templates', () {
        // Arrange
        final allTemplates = templateService.getAllTemplates();
        
        // Act
        final businessTemplates = templateService.getBusinessTemplates();
        final expertTemplates = templateService.getExpertTemplates();
        
        // Assert
        expect(businessTemplates.length + expertTemplates.length, 
               greaterThanOrEqualTo(allTemplates.length));
        
        // Verify no overlap
        final businessIds = businessTemplates.map((t) => t.id).toSet();
        final expertIds = expertTemplates.map((t) => t.id).toSet();
        expect(businessIds.intersection(expertIds), isEmpty);
      });
    });

    group('Template Search Integration', () {
      test('should search templates by name', () {
        // Arrange
        final allTemplates = templateService.getAllTemplates();
        if (allTemplates.isEmpty) return;
        
        final searchTerm = allTemplates.first.name.split(' ').first;
        
        // Act
        final results = templateService.searchTemplates(searchTerm);
        
        // Assert
        expect(results, isNotEmpty);
        for (final template in results) {
          expect(
            template.name.toLowerCase().contains(searchTerm.toLowerCase()) ||
            template.category.toLowerCase().contains(searchTerm.toLowerCase()) ||
            template.tags.any((tag) => tag.toLowerCase().contains(searchTerm.toLowerCase())),
            isTrue,
          );
        }
      });

      test('should search templates by category', () {
        // Arrange
        final allTemplates = templateService.getAllTemplates();
        if (allTemplates.isEmpty) return;
        
        final searchTerm = allTemplates.first.category;
        
        // Act
        final results = templateService.searchTemplates(searchTerm);
        
        // Assert
        expect(results, isNotEmpty);
      });

      test('should return empty list for non-matching search', () {
        // Act
        final results = templateService.searchTemplates('nonexistentxyz123');
        
        // Assert
        expect(results, isEmpty);
      });
    });

    group('Template Categories Integration', () {
      test('should retrieve all template categories', () {
        // Act
        final categories = templateService.getCategories();
        
        // Assert
        expect(categories, isA<List<TemplateCategory>>());
      });
    });
  });
}


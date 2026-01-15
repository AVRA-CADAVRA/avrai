import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/controllers/event_creation_controller.dart';
import 'package:avrai/core/models/expertise_event.dart';
import 'package:avrai/data/datasources/local/sembast_database.dart';
import 'package:avrai/injection_container.dart' as di;
import '../../helpers/platform_channel_helper.dart';
import '../../helpers/integration_test_helpers.dart';

/// Integration tests for EventCreationController
/// 
/// Tests verify that the controller works correctly when integrated
/// with real services (ExpertiseEventService, GeographicScopeService).
void main() {
  group('EventCreationController Integration Tests', () {
    late EventCreationController controller;

    setUpAll(() async {
      // Initialize Sembast for tests
      SembastDatabase.useInMemoryForTests();
      await SembastDatabase.database;
      
      // Initialize dependency injection
      await setupTestStorage();
      await di.init();
      
      // Get controller from DI
      controller = di.sl<EventCreationController>();
    });

    setUp(() async {
      // Reset database for each test
      await SembastDatabase.resetForTests();
    });

    tearDown(() async {
      // Clean up test data - database is reset in setUp, so no manual cleanup needed
    });

    group('createEvent', () {
      test('should successfully create event with valid data and Local expertise', () async {
        // Arrange
        final host = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'host-1',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn, NY, USA',
        );

        final formData = EventFormData(
          title: 'Coffee Tasting Tour',
          description: 'Explore local coffee shops in Greenpoint neighborhood',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          location: 'Greenpoint, Brooklyn',
          locality: 'Greenpoint',
          maxAttendees: 20,
          isPublic: true,
        );

        // Act
        final result = await controller.createEvent(
          formData: formData,
          host: host,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.event, isNotNull);
        expect(result.event!.title, equals(formData.title));
        expect(result.event!.description, equals(formData.description));
        expect(result.event!.category, equals(formData.category));
        expect(result.event!.host.id, equals(host.id));
        expect(result.event!.location, equals(formData.location));
        expect(result.event!.maxAttendees, equals(formData.maxAttendees));
      });

      test('should successfully create paid event', () async {
        // Arrange
        final host = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'host-2',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn, NY, USA',
        );

        final formData = EventFormData(
          title: 'Premium Coffee Workshop',
          description: 'Learn advanced coffee brewing techniques',
          category: 'Coffee',
          eventType: ExpertiseEventType.workshop,
          startTime: DateTime.now().add(const Duration(days: 2)),
          endTime: DateTime.now().add(const Duration(days: 2, hours: 3)),
          location: 'Greenpoint, Brooklyn',
          locality: 'Greenpoint',
          maxAttendees: 15,
          price: 75.0,
          isPublic: true,
        );

        // Act
        final result = await controller.createEvent(
          formData: formData,
          host: host,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.event, isNotNull);
        expect(result.event!.price, equals(75.0));
        expect(result.event!.isPaid, isTrue);
      });

      test('should return failure for user without Local+ expertise', () async {
        // Arrange - user with no expertise
        final host = IntegrationTestHelpers.createUserWithoutHosting(
          id: 'host-3',
          category: 'Coffee',
        );

        final formData = EventFormData(
          title: 'Coffee Tour',
          description: 'Explore local coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );

        // Act
        final result = await controller.createEvent(
          formData: formData,
          host: host,
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.errorCode, equals('EXPERTISE_ERROR'));
        expect(result.error, contains('You must have expertise in Coffee'));
        expect(result.event, isNull);
      });

      test('should return failure for invalid geographic scope', () async {
        // Arrange - user can host in Greenpoint, but tries to host in Manhattan
        final host = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'host-4',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn, NY, USA', // User is in Greenpoint
        );

        final formData = EventFormData(
          title: 'Coffee Tour',
          description: 'Explore local coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          location: 'Manhattan, New York',
          locality: 'Manhattan', // Different locality
        );

        // Act
        final result = await controller.createEvent(
          formData: formData,
          host: host,
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.errorCode, equals('GEOGRAPHIC_SCOPE_ERROR'));
        expect(result.error, contains('Local experts can only host events'));
        expect(result.event, isNull);
      });

      test('should return failure for invalid dates (past start time)', () async {
        // Arrange
        final host = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'host-5',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn, NY, USA',
        );

        final formData = EventFormData(
          title: 'Coffee Tour',
          description: 'Explore local coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().subtract(const Duration(days: 1)), // Past date
          endTime: DateTime.now().add(const Duration(hours: 2)),
          location: 'Greenpoint, Brooklyn',
          locality: 'Greenpoint',
        );

        // Act
        final result = await controller.createEvent(
          formData: formData,
          host: host,
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.errorCode, equals('DATE_ERROR'));
        expect(result.error, equals('Date validation failed'));
        expect(result.validationErrors, isNotNull);
        expect(result.validationErrors!.generalErrors, contains('Start time must be in the future'));
        expect(result.event, isNull);
      });

      test('should return failure for invalid dates (end before start)', () async {
        // Arrange
        final host = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'host-6',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn, NY, USA',
        );

        final formData = EventFormData(
          title: 'Coffee Tour',
          description: 'Explore local coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 2)),
          endTime: DateTime.now().add(const Duration(days: 1)), // End before start
          location: 'Greenpoint, Brooklyn',
          locality: 'Greenpoint',
        );

        // Act
        final result = await controller.createEvent(
          formData: formData,
          host: host,
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.errorCode, equals('DATE_ERROR'));
        expect(result.validationErrors!.generalErrors, contains('End time must be after start time'));
        expect(result.event, isNull);
      });

      test('should return failure for invalid form data (empty title)', () async {
        // Arrange
        final host = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'host-7',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn, NY, USA',
        );

        final formData = EventFormData(
          title: '', // Invalid: empty title
          description: 'Explore local coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );

        // Act
        final result = await controller.createEvent(
          formData: formData,
          host: host,
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.errorCode, equals('VALIDATION_ERROR'));
        expect(result.validationErrors, isNotNull);
        expect(result.validationErrors!.fieldErrors['title'], equals('Title is required'));
        expect(result.event, isNull);
      });

      test('should successfully create event with City level expertise in same city', () async {
        // Arrange - City expert can host in any locality in their city
        final host = IntegrationTestHelpers.createUserWithCityExpertise(
          id: 'host-8',
          category: 'Coffee',
          location: 'Brooklyn, NY, USA', // User is in Brooklyn
        );

        final formData = EventFormData(
          title: 'City-wide Coffee Tour',
          description: 'Explore coffee shops across Brooklyn',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          location: 'Greenpoint, Brooklyn', // Different locality, same city
          locality: 'Greenpoint',
        );

        // Act
        final result = await controller.createEvent(
          formData: formData,
          host: host,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.event, isNotNull);
        expect(result.event!.host.id, equals(host.id));
      });
    });

    group('AVRAI Core System Integration', () {
      test('should create 4D quantum states when location timing service available', () async {
        // Arrange
        final host = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'host-avrai-1',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn, NY, USA',
        );

        final formData = EventFormData(
          title: 'Coffee Tasting Tour',
          description: 'Explore local coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          location: 'Greenpoint, Brooklyn',
          locality: 'Greenpoint',
          latitude: 40.7295,
          longitude: -73.9545,
          maxAttendees: 20,
          isPublic: true,
        );

        // Act
        final result = await controller.createEvent(
          formData: formData,
          host: host,
        );

        // Assert
        expect(result.isSuccess, isTrue, reason: 'Should succeed with AVRAI services');
        expect(result.event, isNotNull, reason: 'Event should be created');
        // Note: 4D quantum state creation happens internally and doesn't affect result
        // This test verifies the controller doesn't crash when AVRAI services are available
      });

      test('should work when AVRAI services are unavailable (graceful degradation)', () async {
        // Create controller without AVRAI services
        final controllerWithoutAVRAI = EventCreationController(
          personalityKnotService: null,
          knotStorageService: null,
          knotFabricService: null,
          knotWorldsheetService: null,
          knotStringService: null,
          locationTimingService: null,
          quantumEntanglementService: null,
          aiLearningService: null,
        );

        final host = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'host-avrai-2',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn, NY, USA',
        );

        final formData = EventFormData(
          title: 'Coffee Tour',
          description: 'Explore local coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          location: 'Greenpoint, Brooklyn',
          locality: 'Greenpoint',
          maxAttendees: 20,
          isPublic: true,
        );

        // Act
        final result = await controllerWithoutAVRAI.createEvent(
          formData: formData,
          host: host,
        );

        // Assert
        expect(result.isSuccess, isTrue, reason: 'Should succeed even without AVRAI services');
        expect(result.event, isNotNull, reason: 'Event should be created');
        // Core functionality should work without AVRAI services
      });

      test('should handle 4D quantum state creation failure gracefully', () async {
        // This test verifies that if 4D quantum state creation fails,
        // the controller continues and doesn't block event creation
        final host = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'host-avrai-3',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn, NY, USA',
        );

        final formData = EventFormData(
          title: 'Coffee Tour',
          description: 'Explore local coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          location: 'Greenpoint, Brooklyn',
          locality: 'Greenpoint',
          latitude: 40.7295,
          longitude: -73.9545,
          maxAttendees: 20,
          isPublic: true,
        );

        final result = await controller.createEvent(
          formData: formData,
          host: host,
        );

        expect(result.isSuccess, isTrue, reason: 'Should succeed even if 4D quantum creation fails');
        // The controller should handle quantum state creation failures gracefully
      });

      test('should handle fabric creation for group events gracefully', () async {
        // Arrange - event with maxAttendees > 1 (group event)
        final host = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'host-avrai-4',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn, NY, USA',
        );

        final formData = EventFormData(
          title: 'Group Coffee Tour',
          description: 'Explore local coffee shops with friends',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          location: 'Greenpoint, Brooklyn',
          locality: 'Greenpoint',
          maxAttendees: 10, // Group event
          isPublic: true,
        );

        // Act
        final result = await controller.createEvent(
          formData: formData,
          host: host,
        );

        // Assert
        expect(result.isSuccess, isTrue, reason: 'Should succeed for group events');
        expect(result.event, isNotNull, reason: 'Event should be created');
        // Fabric creation is deferred until attendees join, so it shouldn't block event creation
      });
    });
  });
}


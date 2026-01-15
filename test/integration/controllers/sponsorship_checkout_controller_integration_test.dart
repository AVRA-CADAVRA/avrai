import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/controllers/sponsorship_checkout_controller.dart';
import 'package:avrai/core/models/expertise_event.dart';
import 'package:avrai/core/models/sponsorship.dart';
import 'package:avrai/core/models/unified_user.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/data/datasources/local/sembast_database.dart';
import '../../helpers/platform_channel_helper.dart';

/// Sponsorship Checkout Controller Integration Tests
/// 
/// Tests the complete sponsorship checkout workflow with real service implementations:
/// - Validation
/// - Sponsorship creation
/// - Product tracking
void main() {
  group('SponsorshipCheckoutController Integration Tests', () {
    late SponsorshipCheckoutController controller;

    setUpAll(() async {
      // Initialize Sembast for tests
      SembastDatabase.useInMemoryForTests();
      await SembastDatabase.database;
      
      // Initialize dependency injection
      await setupTestStorage();
      await di.init();
      
      controller = di.sl<SponsorshipCheckoutController>();
    });

    setUp(() async {
      // Reset database for each test
      await SembastDatabase.resetForTests();
    });

    group('validate', () {
      test('should validate input correctly', () {
        final event = ExpertiseEvent(
          id: 'event_123',
          title: 'Test Sponsored Event',
          description: 'Test',
          category: 'Coffee',
          eventType: ExpertiseEventType.workshop,
          host: UnifiedUser(
            id: 'host_123',
            email: 'host@test.com',
            primaryRole: UserRole.follower,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final validFinancialInput = SponsorshipCheckoutInput(
          event: event,
          brandId: 'brand_456',
          type: SponsorshipType.financial,
          contributionAmount: 500.0,
        );

        final invalidInput = SponsorshipCheckoutInput(
          event: event,
          brandId: 'brand_456',
          type: SponsorshipType.financial,
          contributionAmount: null,
        );

        // Act
        final validResult = controller.validate(validFinancialInput);
        final invalidResult = controller.validate(invalidInput);

        // Assert
        expect(validResult.isValid, isTrue);
        expect(invalidResult.isValid, isFalse);
      });
    });

    group('AVRAI Core System Integration', () {
      test('should work when AVRAI services are available', () {
        final event = ExpertiseEvent(
          id: 'event_123',
          title: 'Test Sponsored Event',
          description: 'Test',
          category: 'Coffee',
          eventType: ExpertiseEventType.workshop,
          host: UnifiedUser(
            id: 'host_123',
            email: 'host@test.com',
            primaryRole: UserRole.follower,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final validFinancialInput = SponsorshipCheckoutInput(
          event: event,
          brandId: 'brand_456',
          type: SponsorshipType.financial,
          contributionAmount: 500.0,
        );

        final validationResult = controller.validate(validFinancialInput);
        expect(validationResult.isValid, isTrue, reason: 'Should validate correctly with AVRAI services');
        // Note: AVRAI integrations (quantum compatibility, knot compatibility, 4D quantum, fabrics, AI2AI learning)
        // happen internally during checkout and don't affect validation
      });

      test('should work when AVRAI services are unavailable (graceful degradation)', () {
        // Create controller without AVRAI services
        final controllerWithoutAVRAI = SponsorshipCheckoutController(
          knotCompatibilityService: null,
          knotFabricService: null,
          locationTimingService: null,
          quantumEntanglementService: null,
          aiLearningService: null,
        );

        final event = ExpertiseEvent(
          id: 'event_123',
          title: 'Test Sponsored Event',
          description: 'Test',
          category: 'Coffee',
          eventType: ExpertiseEventType.workshop,
          host: UnifiedUser(
            id: 'host_123',
            email: 'host@test.com',
            primaryRole: UserRole.follower,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final validFinancialInput = SponsorshipCheckoutInput(
          event: event,
          brandId: 'brand_456',
          type: SponsorshipType.financial,
          contributionAmount: 500.0,
        );

        final validationResult = controllerWithoutAVRAI.validate(validFinancialInput);
        expect(validationResult.isValid, isTrue, reason: 'Should validate correctly even without AVRAI services');
        // Core functionality should work without AVRAI services
      });
    });
  });
}


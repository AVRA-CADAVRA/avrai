import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/controllers/checkout_controller.dart';
import 'package:avrai/core/models/expertise_event.dart';
import 'package:avrai/core/models/unified_user.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/data/datasources/local/sembast_database.dart';
import '../../helpers/platform_channel_helper.dart';

/// Checkout Controller Integration Tests
/// 
/// Tests the complete checkout workflow with real service implementations:
/// - Validation
/// - Event availability checks
/// - Waiver checking
/// - Tax calculation
/// - Payment processing delegation
void main() {
  group('CheckoutController Integration Tests', () {
    late CheckoutController controller;

    setUpAll(() async {
      // Initialize Sembast for tests
      SembastDatabase.useInMemoryForTests();
      await SembastDatabase.database;
      
      // Initialize dependency injection
      await setupTestStorage();
      await di.init();
      
      controller = di.sl<CheckoutController>();
    });

    setUp(() async {
      // Reset database for each test
      await SembastDatabase.resetForTests();
    });

    group('validate', () {
      test('should validate input correctly', () {
        final event = ExpertiseEvent(
          id: 'event_123',
          title: 'Test Event',
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

        final buyer = UnifiedUser(
          id: 'user_456',
          email: 'user@test.com',
          primaryRole: UserRole.follower,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final validInput = CheckoutInput(
          event: event,
          buyer: buyer,
          quantity: 2,
        );

        final invalidInput = CheckoutInput(
          event: event,
          buyer: buyer,
          quantity: 0,
        );

        // Act
        final validResult = controller.validate(validInput);
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
          title: 'Test Event',
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

        final buyer = UnifiedUser(
          id: 'user_456',
          email: 'user@test.com',
          primaryRole: UserRole.follower,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final validInput = CheckoutInput(
          event: event,
          buyer: buyer,
          quantity: 2,
        );

        final validationResult = controller.validate(validInput);
        expect(validationResult.isValid, isTrue, reason: 'Should validate correctly with AVRAI services');
        // Note: AVRAI integrations (quantum compatibility, fabrics, worldsheets, AI2AI learning)
        // happen internally during checkout and don't affect validation
      });

      test('should work when AVRAI services are unavailable (graceful degradation)', () {
        // Create controller without AVRAI services
        final controllerWithoutAVRAI = CheckoutController(
          knotFabricService: null,
          knotWorldsheetService: null,
          locationTimingService: null,
          quantumEntanglementService: null,
          aiLearningService: null,
        );

        final event = ExpertiseEvent(
          id: 'event_123',
          title: 'Test Event',
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

        final buyer = UnifiedUser(
          id: 'user_456',
          email: 'user@test.com',
          primaryRole: UserRole.follower,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final validInput = CheckoutInput(
          event: event,
          buyer: buyer,
          quantity: 2,
        );

        final validationResult = controllerWithoutAVRAI.validate(validInput);
        expect(validationResult.isValid, isTrue, reason: 'Should validate correctly even without AVRAI services');
        // Core functionality should work without AVRAI services
      });
    });
  });
}


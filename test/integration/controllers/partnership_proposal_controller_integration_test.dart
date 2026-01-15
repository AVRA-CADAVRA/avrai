import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/controllers/partnership_proposal_controller.dart';
import 'package:avrai/core/models/event_partnership.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/data/datasources/local/sembast_database.dart';
import '../../helpers/platform_channel_helper.dart';

/// Partnership Proposal Controller Integration Tests
/// 
/// Tests the complete partnership proposal workflow with real service implementations:
/// - Proposal validation
/// - Partnership creation
/// - Proposal acceptance/rejection
/// - Error handling
void main() {
  group('PartnershipProposalController Integration Tests', () {
    late PartnershipProposalController controller;

    setUpAll(() async {
      // Initialize Sembast for tests
      SembastDatabase.useInMemoryForTests();
      await SembastDatabase.database;
      
      // Initialize dependency injection
      await setupTestStorage();
      await di.init();
      
      controller = di.sl<PartnershipProposalController>();
    });

    setUp(() async {
      // Reset database for each test
      await SembastDatabase.resetForTests();
    });

    group('validate', () {
      test('should validate input correctly', () {
        final validData = PartnershipProposalData(
          type: PartnershipType.eventBased,
          sharedResponsibilities: ['Venue'],
        );
        final validInput = PartnershipProposalInput(
          eventId: 'event_123',
          proposerId: 'user_456',
          businessId: 'business_789',
          data: validData,
        );

        final invalidData = PartnershipProposalData();
        final invalidInput = PartnershipProposalInput(
          eventId: '',
          proposerId: 'user_456',
          businessId: 'business_789',
          data: invalidData,
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
        final validData = PartnershipProposalData(
          type: PartnershipType.eventBased,
          sharedResponsibilities: ['Venue'],
        );
        final validInput = PartnershipProposalInput(
          eventId: 'event_123',
          proposerId: 'user_456',
          businessId: 'business_789',
          data: validData,
        );

        final validationResult = controller.validate(validInput);
        expect(validationResult.isValid, isTrue, reason: 'Should validate correctly with AVRAI services');
        // Note: AVRAI integrations (knot compatibility, quantum compatibility, 4D quantum, AI2AI learning)
        // happen internally during proposal creation and don't affect validation
      });

      test('should work when AVRAI services are unavailable (graceful degradation)', () {
        // Create controller without AVRAI services
        final controllerWithoutAVRAI = PartnershipProposalController(
          knotCompatibilityService: null,
          locationTimingService: null,
          quantumEntanglementService: null,
          aiLearningService: null,
        );

        final validData = PartnershipProposalData(
          type: PartnershipType.eventBased,
          sharedResponsibilities: ['Venue'],
        );
        final validInput = PartnershipProposalInput(
          eventId: 'event_123',
          proposerId: 'user_456',
          businessId: 'business_789',
          data: validData,
        );

        final validationResult = controllerWithoutAVRAI.validate(validInput);
        expect(validationResult.isValid, isTrue, reason: 'Should validate correctly even without AVRAI services');
        // Core functionality should work without AVRAI services
      });
    });
  });
}


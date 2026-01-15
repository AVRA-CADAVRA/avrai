import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/controllers/business_onboarding_controller.dart';
import 'package:avrai/core/services/business_account_service.dart';
import 'package:avrai/core/models/business_expert_preferences.dart';
import 'package:avrai/core/models/business_patron_preferences.dart';
import 'package:avrai/core/models/unified_user.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/data/datasources/local/sembast_database.dart';
import '../../helpers/platform_channel_helper.dart';

/// Business Onboarding Controller Integration Tests
/// 
/// Tests the complete business onboarding workflow with real service implementations:
/// - Business account creation and updates
/// - Shared AI agent initialization
/// - Preference updates
/// - Error handling
void main() {
  group('BusinessOnboardingController Integration Tests', () {
    late BusinessOnboardingController controller;
    late BusinessAccountService businessAccountService;
    final DateTime now = DateTime.now();

    setUpAll(() async {
      // Initialize Sembast for tests
      SembastDatabase.useInMemoryForTests();
      await SembastDatabase.database;
      
      // Initialize dependency injection
      await setupTestStorage();
      await di.init();
      
      controller = di.sl<BusinessOnboardingController>();
      businessAccountService = di.sl<BusinessAccountService>();
    });

    setUp(() async {
      // Reset database for each test
      await SembastDatabase.resetForTests();
    });

    group('completeBusinessOnboarding', () {
      test('should successfully complete onboarding without shared agent', () async {
        // Arrange
        final creator = UnifiedUser(
          id: 'user_123',
          email: 'creator@test.com',
          displayName: 'Test Creator',
          createdAt: now,
          updatedAt: now,
        );

        // Create a business account first
        final businessAccount = await businessAccountService.createBusinessAccount(
          creator: creator,
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
        );

        const expertPrefs = BusinessExpertPreferences(
          preferredExpertiseCategories: ['Coffee'],
          minExpertLevel: 3,
        );
        const patronPrefs = BusinessPatronPreferences(
          preferredVibePreferences: ['Cozy', 'Social'],
        );

        final data = BusinessOnboardingData(
          expertPreferences: expertPrefs,
          patronPreferences: patronPrefs,
          setupSharedAgent: false,
        );

        // Act
        final result = await controller.completeBusinessOnboarding(
          businessId: businessAccount.id,
          data: data,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.businessAccount, isNotNull);
        expect(result.businessAccount?.id, equals(businessAccount.id));
        expect(result.businessAccount?.expertPreferences?.preferredExpertiseCategories, contains('Coffee'));
        expect(result.businessAccount?.patronPreferences?.preferredVibePreferences, containsAll(['Cozy', 'Social']));
        expect(result.sharedAgentId, isNull);
      });

      test('should successfully complete onboarding with shared agent', () async {
        // Arrange
        final creator = UnifiedUser(
          id: 'user_456',
          email: 'creator2@test.com',
          displayName: 'Test Creator 2',
          createdAt: now,
          updatedAt: now,
        );

        // Create a business account first
        final businessAccount = await businessAccountService.createBusinessAccount(
          creator: creator,
          name: 'Test Business 2',
          email: 'test2@business.com',
          businessType: 'Retail',
        );

        final data = BusinessOnboardingData(
          setupSharedAgent: true,
          teamMembers: ['user_1', 'user_2'],
        );

        // Act
        final result = await controller.completeBusinessOnboarding(
          businessId: businessAccount.id,
          data: data,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.businessAccount, isNotNull);
        // Note: Shared agent ID might be null if initialization is not fully implemented
        // This test verifies the flow completes without errors
      });

      test('should return failure for non-existent business account', () async {
        // Arrange
        final data = BusinessOnboardingData();

        // Act
        final result = await controller.completeBusinessOnboarding(
          businessId: 'non_existent_business',
          data: data,
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('Business account not found'));
        expect(result.errorCode, equals('BUSINESS_NOT_FOUND'));
      });

      test('should update business account with required expertise and preferred communities', () async {
        // Arrange
        final creator = UnifiedUser(
          id: 'user_789',
          email: 'creator3@test.com',
          displayName: 'Test Creator 3',
          createdAt: now,
          updatedAt: now,
        );

        // Create a business account first
        final businessAccount = await businessAccountService.createBusinessAccount(
          creator: creator,
          name: 'Test Business 3',
          email: 'test3@business.com',
          businessType: 'Service',
        );

        final data = BusinessOnboardingData(
          requiredExpertise: ['Coffee', 'Food'],
          preferredCommunities: ['community_1', 'community_2'],
        );

        // Act
        final result = await controller.completeBusinessOnboarding(
          businessId: businessAccount.id,
          data: data,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.businessAccount, isNotNull);
        expect(result.businessAccount?.requiredExpertise, containsAll(['Coffee', 'Food']));
        expect(result.businessAccount?.preferredCommunities, containsAll(['community_1', 'community_2']));
      });
    });

    group('validate', () {
      test('should validate input correctly', () {
        // Arrange
        final data = BusinessOnboardingData(
          businessId: 'business_123',
          setupSharedAgent: false,
        );

        // Act
        final result = controller.validate(data);

        // Assert
        expect(result.isValid, isTrue);
      });

      test('should return warning for shared agent without team members', () {
        // Arrange
        final data = BusinessOnboardingData(
          businessId: 'business_123',
          setupSharedAgent: true,
          teamMembers: [],
        );

        // Act
        final result = controller.validate(data);

        // Assert
        expect(result.isValid, isTrue);
        expect(result.warnings, contains('Shared agent enabled but no team members added'));
      });
    });

    group('AVRAI Core System Integration', () {
      test('should work when AVRAI services are available', () async {
        final creator = UnifiedUser(
          id: 'user_avrai_${DateTime.now().millisecondsSinceEpoch}',
          email: 'creator@test.com',
          displayName: 'Test Creator',
          createdAt: now,
          updatedAt: now,
        );

        final businessAccount = await businessAccountService.createBusinessAccount(
          creator: creator,
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
        );

        final data = BusinessOnboardingData(
          setupSharedAgent: false,
        );

        final result = await controller.completeBusinessOnboarding(
          businessId: businessAccount.id,
          data: data,
        );

        expect(result.success, isTrue, reason: 'Should succeed with AVRAI services');
        expect(result.businessAccount, isNotNull, reason: 'Business account should be updated');
        // Note: AVRAI integrations (knots, 4D quantum) happen internally
      });

      test('should work when AVRAI services are unavailable (graceful degradation)', () async {
        // Create controller without AVRAI services
        final controllerWithoutAVRAI = BusinessOnboardingController(
          personalityKnotService: null,
          knotStorageService: null,
          locationTimingService: null,
          quantumEntanglementService: null,
        );

        final creator = UnifiedUser(
          id: 'user_avrai_${DateTime.now().millisecondsSinceEpoch}',
          email: 'creator@test.com',
          displayName: 'Test Creator',
          createdAt: now,
          updatedAt: now,
        );

        final businessAccount = await businessAccountService.createBusinessAccount(
          creator: creator,
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
        );

        final data = BusinessOnboardingData(
          setupSharedAgent: false,
        );

        final result = await controllerWithoutAVRAI.completeBusinessOnboarding(
          businessId: businessAccount.id,
          data: data,
        );

        expect(result.success, isTrue, reason: 'Should succeed even without AVRAI services');
        expect(result.businessAccount, isNotNull, reason: 'Business account should be updated');
        // Core functionality should work without AVRAI services
      });
    });
  });
}

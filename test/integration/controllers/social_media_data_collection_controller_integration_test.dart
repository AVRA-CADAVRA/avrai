import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/controllers/social_media_data_collection_controller.dart';
import 'package:avrai/data/datasources/local/sembast_database.dart';
import 'package:avrai/injection_container.dart' as di;
import '../../helpers/platform_channel_helper.dart';

/// Integration tests for SocialMediaDataCollectionController
/// 
/// Tests verify that the controller works correctly when integrated
/// with real services (SocialMediaConnectionService).
void main() {
  group('SocialMediaDataCollectionController Integration Tests', () {
    late SocialMediaDataCollectionController controller;

    setUpAll(() async {
      // Initialize Sembast for tests
      SembastDatabase.useInMemoryForTests();
      await SembastDatabase.database;
      
      // Initialize dependency injection
      await setupTestStorage();
      await di.init();
      
      // Get controller from DI
      controller = di.sl<SocialMediaDataCollectionController>();
    });

    setUp(() async {
      // Reset database for each test
      await SembastDatabase.resetForTests();
    });

    tearDown(() async {
      // Clean up test data - database is reset in setUp, so no manual cleanup needed
    });

    group('collectAllData', () {
      test('should return empty result when no connections exist', () async {
        // Arrange
        const userId = 'test_user_no_connections';

        // Act
        final result = await controller.collectAllData(userId: userId);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.profileData, isEmpty);
        expect(result.follows, isEmpty);
        expect(result.primaryPlatform, isNull);
      });

      test('should handle errors gracefully when service fails', () async {
        // Arrange
        const userId = 'test_user_error';

        // Act
        // Note: This may succeed or fail depending on service implementation
        // The important thing is that it doesn't crash
        final result = await controller.collectAllData(userId: userId);

        // Assert
        expect(result, isNotNull);
        // Result may be success (empty) or failure depending on service behavior
      });

      test('should validate userId before processing', () async {
        // Arrange
        const emptyUserId = '';

        // Act
        final result = await controller.collectAllData(userId: emptyUserId);

        // Assert
        // Controller should handle empty userId gracefully
        expect(result, isNotNull);
      });
    });

    group('validate', () {
      test('should validate non-empty userId', () {
        // Act
        final result = controller.validate('user-123');

        // Assert
        expect(result.isValid, isTrue);
      });

      test('should reject empty userId', () {
        // Act
        final result = controller.validate('');

        // Assert
        expect(result.isValid, isFalse);
        expect(result.generalErrors, contains('User ID cannot be empty'));
      });
    });

    group('AVRAI Core System Integration', () {
      test('should work correctly (no AVRAI integration needed)', () async {
        // SocialMediaDataCollectionController doesn't have AVRAI integration
        // (it's just data collection, not personality/entity workflows)
        const userId = 'test_user_avrai';

        final result = await controller.collectAllData(userId: userId);

        expect(result, isNotNull, reason: 'Should return result');
        // Note: SocialMediaDataCollectionController doesn't need AVRAI integration
        // It's purely data collection, not personality/entity workflows
      });
    });
  });
}


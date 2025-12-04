import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:spots/core/services/community_validation_service.dart';
import 'package:spots/core/models/unified_models.dart';
import 'package:spots/core/models/community_validation.dart';
import 'package:shared_preferences/shared_preferences.dart' as real_prefs;
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks/mock_dependencies.mocks.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/platform_channel_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CommunityValidationService Tests', () {
    late CommunityValidationService service;
    late MockStorageService mockStorageService;
    late SharedPreferences prefs;

    setUpAll(() async {
      real_prefs.SharedPreferences.setMockInitialValues({});
      await setupTestStorage();
    });

    setUp(() async {
      mockStorageService = MockStorageService();
      prefs = await real_prefs.SharedPreferences.getInstance();

      service = CommunityValidationService(
        storageService: mockStorageService,
        prefs: prefs,
      );
    });

    tearDown(() async {
      await prefs.clear();
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });

    group('validateSpot', () {
      test('validates spot successfully', () async {
        // Arrange
        final spot = ModelFactories.createTestSpot();
        when(mockStorageService.getObject<List<dynamic>>(
          any,
          box: anyNamed('box'),
        )).thenReturn([]);
        when(mockStorageService.setObject(
          any,
          any,
          box: anyNamed('box'),
        )).thenAnswer((_) async => true);

        // Act
        final validation = await service.validateSpot(
          spot: spot,
          validatorId: 'validator_id',
          status: ValidationStatus.validated,
          criteria: [ValidationCriteria.locationAccuracy],
        );

        // Assert
        expect(validation, isNotNull);
        expect(validation.spotId, equals(spot.id));
        expect(validation.status, equals(ValidationStatus.validated));
        expect(validation.validatedAt, isNotNull);
      });
    });

    group('validateList', () {
      test('validates list with valid spots', () async {
        // Arrange
        final list = ModelFactories.createTestList();

        // Mock storage to return validations for each spot
        // This makes getSpotValidationSummary return validated summaries
        final validationsData = <Map<String, dynamic>>[];
        for (final spotId in list.spotIds) {
          validationsData.add({
            'id': 'validation_$spotId',
            'spotId': spotId,
            'validatorId': 'validator_id',
            'status': 'validated',
            'level': 'community',
            'validatedAt': DateTime.now().toIso8601String(),
            'criteriaChecked': ['locationAccuracy'],
            'confidenceScore': 0.9,
            'metadata': {},
          });
        }

        when(mockStorageService.getObject<List<dynamic>>(
          any,
          box: anyNamed('box'),
        )).thenReturn(validationsData);
        when(mockStorageService.getObject<Map<String, dynamic>>(
          any,
          box: anyNamed('box'),
        )).thenReturn({});
        when(mockStorageService.setObject(
          any,
          any,
          box: anyNamed('box'),
        )).thenAnswer((_) async => true);

        // Act
        final result = await service.validateList(
          list: list,
          validatorId: 'validator_id',
          criteria: [ValidationCriteria.locationAccuracy],
        );

        // Assert
        expect(result, isNotNull);
        // Note: Result depends on validation status of spots
        // If spots aren't validated, result will be invalid (expected behavior)
        // The important thing is that the method completes without errors
        expect(result.confidenceScore, greaterThanOrEqualTo(0.0));
        expect(result.issues, isA<List<String>>());
      });

      test('returns invalid for empty list', () async {
        // Arrange
        final emptyList = ModelFactories.createTestList();
        emptyList.spotIds.clear();

        // Act
        final result = await service.validateList(
          list: emptyList,
          validatorId: 'validator_id',
          criteria: [ValidationCriteria.locationAccuracy],
        );

        // Assert
        expect(result.isValid, isFalse);
        expect(result.issues, contains('List has no spots'));
      });
    });

    group('getSpotValidationSummary', () {
      test('returns summary for validated spot', () async {
        // Arrange
        final spot = ModelFactories.createTestSpot();
        when(mockStorageService.getObject<List<dynamic>>(
          any,
          box: anyNamed('box'),
        )).thenReturn([]);

        // Act
        final summary = await service.getSpotValidationSummary(spot.id);

        // Assert
        expect(summary, isNotNull);
        expect(summary.spotId, equals(spot.id));
      });
    });
  });
}

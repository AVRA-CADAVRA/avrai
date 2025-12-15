import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/geographic_scope_service.dart';
import 'package:spots/core/services/large_city_detection_service.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/platform_channel_helper.dart';

/// Geographic Scope Service Tests
/// Tests geographic hierarchy validation for event hosting
void main() {
  group('GeographicScopeService Tests', () {
    late GeographicScopeService service;
    late LargeCityDetectionService largeCityService;

    setUp(() {
      largeCityService = LargeCityDetectionService();
      service = GeographicScopeService(largeCityService: largeCityService);
    });

    // Removed: Property assignment tests
    // Geographic scope tests focus on business logic (expertise level validation, location matching), not property assignment

    group('canHostInLocality', () {
      test(
          'should correctly determine hosting eligibility based on expertise level and location, or return false for no expertise or no location',
          () {
        // Test business logic: expertise-based hosting eligibility
        // Local expert - own locality only
        final localUser = ModelFactories.createTestUser(id: 'user-123')
            .copyWith(
                location: 'Greenpoint, Brooklyn',
                expertiseMap: {'food': 'local'});
        expect(
            service.canHostInLocality(
                userId: localUser.id,
                user: localUser,
                category: 'food',
                locality: 'Greenpoint'),
            isTrue);
        expect(
            service.canHostInLocality(
                userId: localUser.id,
                user: localUser,
                category: 'food',
                locality: 'Williamsburg'),
            isFalse);

        // City expert - any locality in city
        final cityUser = ModelFactories.createTestUser(id: 'user-123').copyWith(
            location: 'Greenpoint, Brooklyn', expertiseMap: {'food': 'city'});
        expect(
            service.canHostInLocality(
                userId: cityUser.id,
                user: cityUser,
                category: 'food',
                locality: 'Greenpoint'),
            isTrue);
        expect(
            service.canHostInLocality(
                userId: cityUser.id,
                user: cityUser,
                category: 'food',
                locality: 'Williamsburg'),
            isTrue);
        expect(
            service.canHostInLocality(
                userId: cityUser.id,
                user: cityUser,
                category: 'food',
                locality: 'DUMBO'),
            isTrue);
        expect(
            service.canHostInLocality(
                userId: cityUser.id,
                user: cityUser,
                category: 'food',
                locality: 'Manhattan'),
            isFalse);

        // Regional expert - any locality in state
        final regionalUser = ModelFactories.createTestUser(id: 'user-123')
            .copyWith(
                location: 'Greenpoint, Brooklyn, NY, USA',
                expertiseMap: {'food': 'regional'});
        expect(
            service.canHostInLocality(
                userId: regionalUser.id,
                user: regionalUser,
                category: 'food',
                locality: 'Greenpoint'),
            isTrue);
        expect(
            service.canHostInLocality(
                userId: regionalUser.id,
                user: regionalUser,
                category: 'food',
                locality: 'Manhattan'),
            isTrue);

        // National expert - any locality in nation
        final nationalUser = ModelFactories.createTestUser(id: 'user-123')
            .copyWith(
                location: 'Greenpoint, Brooklyn, NY, USA',
                expertiseMap: {'food': 'national'});
        expect(
            service.canHostInLocality(
                userId: nationalUser.id,
                user: nationalUser,
                category: 'food',
                locality: 'Greenpoint'),
            isTrue);
        expect(
            service.canHostInLocality(
                userId: nationalUser.id,
                user: nationalUser,
                category: 'food',
                locality: 'Los Angeles'),
            isTrue);

        // Global/Universal expert - anywhere
        final globalUser = ModelFactories.createTestUser(id: 'user-123')
            .copyWith(expertiseMap: {'food': 'global'});
        expect(
            service.canHostInLocality(
                userId: globalUser.id,
                user: globalUser,
                category: 'food',
                locality: 'Tokyo'),
            isTrue);
        expect(
            service.canHostInLocality(
                userId: globalUser.id,
                user: globalUser,
                category: 'food',
                locality: 'Paris'),
            isTrue);

        final universalUser = ModelFactories.createTestUser(id: 'user-123')
            .copyWith(expertiseMap: {'food': 'universal'});
        expect(
            service.canHostInLocality(
                userId: universalUser.id,
                user: universalUser,
                category: 'food',
                locality: 'Anywhere'),
            isTrue);

        // Edge cases
        final noExpertiseUser = ModelFactories.createTestUser(id: 'user-123')
            .copyWith(location: 'Greenpoint, Brooklyn', expertiseMap: {});
        expect(
            service.canHostInLocality(
                userId: noExpertiseUser.id,
                user: noExpertiseUser,
                category: 'food',
                locality: 'Greenpoint'),
            isFalse);

        final noLocationUser = ModelFactories.createTestUser(id: 'user-123')
            .copyWith(expertiseMap: {'food': 'local'});
        expect(
            service.canHostInLocality(
                userId: noLocationUser.id,
                user: noLocationUser,
                category: 'food',
                locality: 'Greenpoint'),
            isFalse);
      });
    });

    group('canHostInCity', () {
      test(
          'should correctly determine city hosting eligibility based on expertise level',
          () {
        // Test business logic: city-level hosting eligibility
        final cityUser = ModelFactories.createTestUser(id: 'user-123').copyWith(
            location: 'Greenpoint, Brooklyn', expertiseMap: {'food': 'city'});
        expect(
            service.canHostInCity(
                userId: cityUser.id,
                user: cityUser,
                category: 'food',
                city: 'Brooklyn'),
            isTrue);

        final localUser = ModelFactories.createTestUser(id: 'user-123')
            .copyWith(
                location: 'Greenpoint, Brooklyn',
                expertiseMap: {'food': 'local'});
        expect(
            service.canHostInCity(
                userId: localUser.id,
                user: localUser,
                category: 'food',
                city: 'Manhattan'),
            isFalse);

        final regionalUser = ModelFactories.createTestUser(id: 'user-123')
            .copyWith(
                location: 'Greenpoint, Brooklyn, NY, USA',
                expertiseMap: {'food': 'regional'});
        expect(
            service.canHostInCity(
                userId: regionalUser.id,
                user: regionalUser,
                category: 'food',
                city: 'Brooklyn'),
            isTrue);
        expect(
            service.canHostInCity(
                userId: regionalUser.id,
                user: regionalUser,
                category: 'food',
                city: 'Manhattan'),
            isTrue);
      });
    });

    group('getHostingScope', () {
      test(
          'should return correct hosting scope based on expertise level (local, city, global)',
          () {
        // Test business logic: hosting scope calculation
        final localUser = ModelFactories.createTestUser(id: 'user-123')
            .copyWith(
                location: 'Greenpoint, Brooklyn',
                expertiseMap: {'food': 'local'});
        final localScope =
            service.getHostingScope(user: localUser, category: 'food');
        expect(localScope['localities'], isA<List<String>>());
        expect(localScope['cities'], isEmpty);

        final cityUser = ModelFactories.createTestUser(id: 'user-123').copyWith(
            location: 'Greenpoint, Brooklyn', expertiseMap: {'food': 'city'});
        final cityScope =
            service.getHostingScope(user: cityUser, category: 'food');
        expect(cityScope['localities'], isA<List<String>>());
        expect(cityScope['cities'], isA<List<String>>());

        final globalUser = ModelFactories.createTestUser(id: 'user-123')
            .copyWith(expertiseMap: {'food': 'global'});
        final globalScope =
            service.getHostingScope(user: globalUser, category: 'food');
        expect(globalScope['localities'], contains('*'));
        expect(globalScope['cities'], contains('*'));
      });
    });

    group('validateEventLocation', () {
      test(
          'should validate event location based on expertise level, or throw exception for invalid locations',
          () {
        // Test business logic: location validation with error handling
        final localUser = ModelFactories.createTestUser(id: 'user-123')
            .copyWith(
                location: 'Greenpoint, Brooklyn',
                expertiseMap: {'food': 'local'});
        expect(
          () => service.validateEventLocation(
              userId: localUser.id,
              user: localUser,
              category: 'food',
              eventLocality: 'Greenpoint'),
          returnsNormally,
        );
        expect(
          () => service.validateEventLocation(
              userId: localUser.id,
              user: localUser,
              category: 'food',
              eventLocality: 'Williamsburg'),
          throwsException,
        );

        final cityUser = ModelFactories.createTestUser(id: 'user-123').copyWith(
            location: 'Greenpoint, Brooklyn', expertiseMap: {'food': 'city'});
        expect(
          () => service.validateEventLocation(
              userId: cityUser.id,
              user: cityUser,
              category: 'food',
              eventLocality: 'Williamsburg'),
          returnsNormally,
        );
        expect(
          () => service.validateEventLocation(
              userId: cityUser.id,
              user: cityUser,
              category: 'food',
              eventLocality: 'Manhattan'),
          throwsException,
        );

        final globalUser = ModelFactories.createTestUser(id: 'user-123')
            .copyWith(expertiseMap: {'food': 'global'});
        expect(
          () => service.validateEventLocation(
              userId: globalUser.id,
              user: globalUser,
              category: 'food',
              eventLocality: 'Tokyo'),
          returnsNormally,
        );
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}

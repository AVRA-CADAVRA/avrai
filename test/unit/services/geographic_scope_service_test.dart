import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/geographic_scope_service.dart';
import 'package:spots/core/services/large_city_detection_service.dart';
import '../../fixtures/model_factories.dart';

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

    group('canHostInLocality', () {
      test('should allow local expert to host in their own locality', () {
        final user = ModelFactories.createTestUser(
          id: 'user-123',
        ).copyWith(
          location: 'Greenpoint, Brooklyn, NY, USA',
          expertiseMap: {'food': 'local'},
        );

        final canHost = service.canHostInLocality(
          userId: user.id,
          user: user,
          category: 'food',
          locality: 'Greenpoint',
        );

        expect(canHost, isTrue);
      });

      test('should prevent local expert from hosting in different locality', () {
        final user = ModelFactories.createTestUser(
          id: 'user-123',
        ).copyWith(
          location: 'Greenpoint, Brooklyn, NY, USA',
          expertiseMap: {'food': 'local'},
        );

        final canHost = service.canHostInLocality(
          userId: user.id,
          user: user,
          category: 'food',
          locality: 'Williamsburg',
        );

        expect(canHost, isFalse);
      });

      test('should allow city expert to host in any locality in their city', () {
        final user = ModelFactories.createTestUser(
          id: 'user-123',
        ).copyWith(
          location: 'Greenpoint, Brooklyn, NY, USA',
          expertiseMap: {'food': 'city'},
        );

        // City expert can host in any locality in Brooklyn
        expect(
          service.canHostInLocality(
            userId: user.id,
            user: user,
            category: 'food',
            locality: 'Greenpoint',
          ),
          isTrue,
        );
        expect(
          service.canHostInLocality(
            userId: user.id,
            user: user,
            category: 'food',
            locality: 'Williamsburg',
          ),
          isTrue,
        );
        expect(
          service.canHostInLocality(
            userId: user.id,
            user: user,
            category: 'food',
            locality: 'DUMBO',
          ),
          isTrue,
        );
      });

      test('should prevent city expert from hosting in different city', () {
        final user = ModelFactories.createTestUser(
          id: 'user-123',
        ).copyWith(
          location: 'Greenpoint, Brooklyn, NY, USA',
          expertiseMap: {'food': 'city'},
        );

        final canHost = service.canHostInLocality(
          userId: user.id,
          user: user,
          category: 'food',
          locality: 'Manhattan',
        );

        expect(canHost, isFalse);
      });

      test('should allow state expert to host in any locality in their state', () {
        final user = ModelFactories.createTestUser(
          id: 'user-123',
        ).copyWith(
          location: 'Greenpoint, Brooklyn, NY, USA',
          expertiseMap: {'food': 'regional'},
        );

        // State expert can host in any locality in NY
        expect(
          service.canHostInLocality(
            userId: user.id,
            user: user,
            category: 'food',
            locality: 'Greenpoint',
          ),
          isTrue,
        );
        expect(
          service.canHostInLocality(
            userId: user.id,
            user: user,
            category: 'food',
            locality: 'Manhattan',
          ),
          isTrue,
        );
      });

      test('should allow national expert to host in any locality in their nation', () {
        final user = ModelFactories.createTestUser(
          id: 'user-123',
        ).copyWith(
          location: 'Greenpoint, Brooklyn, NY, USA',
          expertiseMap: {'food': 'national'},
        );

        // National expert can host anywhere in USA
        expect(
          service.canHostInLocality(
            userId: user.id,
            user: user,
            category: 'food',
            locality: 'Greenpoint',
          ),
          isTrue,
        );
        expect(
          service.canHostInLocality(
            userId: user.id,
            user: user,
            category: 'food',
            locality: 'Los Angeles',
          ),
          isTrue,
        );
      });

      test('should allow global expert to host anywhere', () {
        final user = ModelFactories.createTestUser(
          id: 'user-123',
        ).copyWith(
          location: 'Greenpoint, Brooklyn, NY, USA',
          expertiseMap: {'food': 'global'},
        );

        expect(
          service.canHostInLocality(
            userId: user.id,
            user: user,
            category: 'food',
            locality: 'Tokyo',
          ),
          isTrue,
        );
        expect(
          service.canHostInLocality(
            userId: user.id,
            user: user,
            category: 'food',
            locality: 'Paris',
          ),
          isTrue,
        );
      });

      test('should allow universal expert to host anywhere', () {
        final user = ModelFactories.createTestUser(
          id: 'user-123',
        ).copyWith(
          location: 'Greenpoint, Brooklyn, NY, USA',
          expertiseMap: {'food': 'universal'},
        );

        expect(
          service.canHostInLocality(
            userId: user.id,
            user: user,
            category: 'food',
            locality: 'Anywhere',
          ),
          isTrue,
        );
      });

      test('should return false if user has no expertise in category', () {
        final user = ModelFactories.createTestUser(
          id: 'user-123',
        ).copyWith(
          location: 'Greenpoint, Brooklyn, NY, USA',
          expertiseMap: {}, // No expertise
        );

        final canHost = service.canHostInLocality(
          userId: user.id,
          user: user,
          category: 'food',
          locality: 'Greenpoint',
        );

        expect(canHost, isFalse);
      });

      test('should return false if user has no location', () {
        final user = ModelFactories.createTestUser(
          id: 'user-123',
          location: null,
        ).copyWith(
          expertiseMap: {'food': 'local'},
        );

        final canHost = service.canHostInLocality(
          userId: user.id,
          user: user,
          category: 'food',
          locality: 'Greenpoint',
        );

        expect(canHost, isFalse);
      });
    });

    group('canHostInCity', () {
      test('should allow city expert to host in their own city', () {
        final user = ModelFactories.createTestUser(
          id: 'user-123',
        ).copyWith(
          location: 'Greenpoint, Brooklyn, NY, USA',
          expertiseMap: {'food': 'city'},
        );

        final canHost = service.canHostInCity(
          userId: user.id,
          user: user,
          category: 'food',
          city: 'Brooklyn',
        );

        expect(canHost, isTrue);
      });

      test('should prevent local expert from hosting in different city', () {
        final user = ModelFactories.createTestUser(
          id: 'user-123',
        ).copyWith(
          location: 'Greenpoint, Brooklyn, NY, USA',
          expertiseMap: {'food': 'local'},
        );

        final canHost = service.canHostInCity(
          userId: user.id,
          user: user,
          category: 'food',
          city: 'Manhattan',
        );

        expect(canHost, isFalse);
      });

      test('should allow state expert to host in any city in their state', () {
        final user = ModelFactories.createTestUser(
          id: 'user-123',
        ).copyWith(
          location: 'Greenpoint, Brooklyn, NY, USA',
          expertiseMap: {'food': 'regional'},
        );

        expect(
          service.canHostInCity(
            userId: user.id,
            user: user,
            category: 'food',
            city: 'Brooklyn',
          ),
          isTrue,
        );
        expect(
          service.canHostInCity(
            userId: user.id,
            user: user,
            category: 'food',
            city: 'Manhattan',
          ),
          isTrue,
        );
      });
    });

    group('getHostingScope', () {
      test('should return only user locality for local expert', () {
        final user = ModelFactories.createTestUser(
          id: 'user-123',
        ).copyWith(
          location: 'Greenpoint, Brooklyn, NY, USA',
          expertiseMap: {'food': 'local'},
        );

        final scope = service.getHostingScope(
          user: user,
          category: 'food',
        );

        expect(scope['localities'], isA<List<String>>());
        expect(scope['cities'], isEmpty);
      });

      test('should return all localities in city for city expert', () {
        final user = ModelFactories.createTestUser(
          id: 'user-123',
        ).copyWith(
          location: 'Greenpoint, Brooklyn, NY, USA',
          expertiseMap: {'food': 'city'},
        );

        final scope = service.getHostingScope(
          user: user,
          category: 'food',
        );

        expect(scope['localities'], isA<List<String>>());
        expect(scope['cities'], isA<List<String>>());
      });

      test('should return all localities and cities for global expert', () {
        final user = ModelFactories.createTestUser(
          id: 'user-123',
        ).copyWith(
          location: 'Greenpoint, Brooklyn, NY, USA',
          expertiseMap: {'food': 'global'},
        );

        final scope = service.getHostingScope(
          user: user,
          category: 'food',
        );

        expect(scope['localities'], contains('*'));
        expect(scope['cities'], contains('*'));
      });
    });

    group('validateEventLocation', () {
      test('should validate local expert hosting in their locality', () {
        final user = ModelFactories.createTestUser(
          id: 'user-123',
        ).copyWith(
          location: 'Greenpoint, Brooklyn, NY, USA',
          expertiseMap: {'food': 'local'},
        );

        expect(
          () => service.validateEventLocation(
            userId: user.id,
            user: user,
            category: 'food',
            eventLocality: 'Greenpoint',
          ),
          returnsNormally,
        );
      });

      test('should throw exception when local expert hosts in different locality', () {
        final user = ModelFactories.createTestUser(
          id: 'user-123',
        ).copyWith(
          location: 'Greenpoint, Brooklyn, NY, USA',
          expertiseMap: {'food': 'local'},
        );

        expect(
          () => service.validateEventLocation(
            userId: user.id,
            user: user,
            category: 'food',
            eventLocality: 'Williamsburg',
          ),
          throwsException,
        );
      });

      test('should validate city expert hosting in any locality in their city', () {
        final user = ModelFactories.createTestUser(
          id: 'user-123',
        ).copyWith(
          location: 'Greenpoint, Brooklyn, NY, USA',
          expertiseMap: {'food': 'city'},
        );

        expect(
          () => service.validateEventLocation(
            userId: user.id,
            user: user,
            category: 'food',
            eventLocality: 'Williamsburg',
          ),
          returnsNormally,
        );
      });

      test('should throw exception when city expert hosts outside their city', () {
        final user = ModelFactories.createTestUser(
          id: 'user-123',
        ).copyWith(
          location: 'Greenpoint, Brooklyn, NY, USA',
          expertiseMap: {'food': 'city'},
        );

        expect(
          () => service.validateEventLocation(
            userId: user.id,
            user: user,
            category: 'food',
            eventLocality: 'Manhattan',
          ),
          throwsException,
        );
      });

      test('should validate global expert hosting anywhere', () {
        final user = ModelFactories.createTestUser(
          id: 'user-123',
        ).copyWith(
          location: 'Greenpoint, Brooklyn, NY, USA',
          expertiseMap: {'food': 'global'},
        );

        expect(
          () => service.validateEventLocation(
            userId: user.id,
            user: user,
            category: 'food',
            eventLocality: 'Tokyo',
          ),
          returnsNormally,
        );
      });
    });
  });
}


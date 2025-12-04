import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/large_city_detection_service.dart';

/// Large City Detection Service Tests
/// Tests large city detection and neighborhood handling
void main() {
  group('LargeCityDetectionService Tests', () {
    late LargeCityDetectionService service;

    setUp(() {
      service = LargeCityDetectionService();
    });

    group('isLargeCity', () {
      test('should detect Brooklyn as large city', () {
        expect(service.isLargeCity('Brooklyn'), isTrue);
        expect(service.isLargeCity('brooklyn'), isTrue); // Case insensitive
        expect(service.isLargeCity('BROOKLYN'), isTrue);
      });

      test('should detect Los Angeles as large city', () {
        expect(service.isLargeCity('Los Angeles'), isTrue);
        expect(service.isLargeCity('los angeles'), isTrue);
      });

      test('should detect Chicago as large city', () {
        expect(service.isLargeCity('Chicago'), isTrue);
      });

      test('should detect Tokyo as large city', () {
        expect(service.isLargeCity('Tokyo'), isTrue);
      });

      test('should detect Seoul as large city', () {
        expect(service.isLargeCity('Seoul'), isTrue);
      });

      test('should detect Paris as large city', () {
        expect(service.isLargeCity('Paris'), isTrue);
      });

      test('should detect Madrid as large city', () {
        expect(service.isLargeCity('Madrid'), isTrue);
      });

      test('should detect Lagos as large city', () {
        expect(service.isLargeCity('Lagos'), isTrue);
      });

      test('should not detect small city as large city', () {
        expect(service.isLargeCity('Smalltown'), isFalse);
        expect(service.isLargeCity(''), isFalse);
      });
    });

    group('getNeighborhoods', () {
      test('should return neighborhoods for Brooklyn', () {
        final neighborhoods = service.getNeighborhoods('Brooklyn');

        expect(neighborhoods, isNotEmpty);
        expect(neighborhoods, contains('Greenpoint'));
        expect(neighborhoods, contains('Williamsburg'));
        expect(neighborhoods, contains('DUMBO'));
        expect(neighborhoods, contains('Park Slope'));
      });

      test('should return neighborhoods for Los Angeles', () {
        final neighborhoods = service.getNeighborhoods('Los Angeles');

        expect(neighborhoods, isNotEmpty);
        expect(neighborhoods, contains('Hollywood'));
        expect(neighborhoods, contains('Santa Monica'));
        expect(neighborhoods, contains('Venice'));
      });

      test('should return neighborhoods for Tokyo', () {
        final neighborhoods = service.getNeighborhoods('Tokyo');

        expect(neighborhoods, isNotEmpty);
        expect(neighborhoods, contains('Shibuya'));
        expect(neighborhoods, contains('Shinjuku'));
        expect(neighborhoods, contains('Harajuku'));
      });

      test('should return empty list for non-large city', () {
        final neighborhoods = service.getNeighborhoods('Smalltown');

        expect(neighborhoods, isEmpty);
      });

      test('should return empty list for empty string', () {
        final neighborhoods = service.getNeighborhoods('');

        expect(neighborhoods, isEmpty);
      });
    });

    group('isNeighborhoodLocality', () {
      test('should detect Greenpoint as neighborhood', () {
        expect(service.isNeighborhoodLocality('Greenpoint'), isTrue);
        expect(service.isNeighborhoodLocality('greenpoint'), isTrue);
      });

      test('should detect Williamsburg as neighborhood', () {
        expect(service.isNeighborhoodLocality('Williamsburg'), isTrue);
      });

      test('should detect DUMBO as neighborhood', () {
        expect(service.isNeighborhoodLocality('DUMBO'), isTrue);
      });

      test('should detect Hollywood as neighborhood', () {
        expect(service.isNeighborhoodLocality('Hollywood'), isTrue);
      });

      test('should detect Shibuya as neighborhood', () {
        expect(service.isNeighborhoodLocality('Shibuya'), isTrue);
      });

      test('should not detect regular locality as neighborhood', () {
        expect(service.isNeighborhoodLocality('Smalltown'), isFalse);
        expect(service.isNeighborhoodLocality(''), isFalse);
      });
    });

    group('getParentCity', () {
      test('should return Brooklyn for Greenpoint', () {
        final parentCity = service.getParentCity('Greenpoint');

        expect(parentCity, equals('Brooklyn'));
      });

      test('should return Brooklyn for Williamsburg', () {
        final parentCity = service.getParentCity('Williamsburg');

        expect(parentCity, equals('Brooklyn'));
      });

      test('should return Brooklyn for DUMBO', () {
        final parentCity = service.getParentCity('DUMBO');

        expect(parentCity, equals('Brooklyn'));
      });

      test('should return Los Angeles for Hollywood', () {
        final parentCity = service.getParentCity('Hollywood');

        expect(parentCity, equals('Los Angeles'));
      });

      test('should return Tokyo for Shibuya', () {
        final parentCity = service.getParentCity('Shibuya');

        expect(parentCity, equals('Tokyo'));
      });

      test('should return null for non-neighborhood locality', () {
        final parentCity = service.getParentCity('Smalltown');

        expect(parentCity, isNull);
      });

      test('should return null for empty string', () {
        final parentCity = service.getParentCity('');

        expect(parentCity, isNull);
      });
    });

    group('getCityConfig', () {
      test('should return config for Brooklyn', () {
        final config = service.getCityConfig('Brooklyn');

        expect(config, isNotNull);
        expect(config?.cityName, equals('Brooklyn'));
        expect(config?.neighborhoods, isNotEmpty);
        expect(config?.population, greaterThan(0));
        expect(config?.geographicSize, greaterThan(0));
      });

      test('should return config for Los Angeles', () {
        final config = service.getCityConfig('Los Angeles');

        expect(config, isNotNull);
        expect(config?.cityName, equals('Los Angeles'));
      });

      test('should return null for non-large city', () {
        final config = service.getCityConfig('Smalltown');

        expect(config, isNull);
      });
    });

    group('getAllLargeCities', () {
      test('should return list of all large cities', () {
        final cities = service.getAllLargeCities();

        expect(cities, isNotEmpty);
        expect(cities, contains('Brooklyn'));
        expect(cities, contains('Los Angeles'));
        expect(cities, contains('Chicago'));
        expect(cities, contains('Tokyo'));
        expect(cities, contains('Seoul'));
        expect(cities, contains('Paris'));
        expect(cities, contains('Madrid'));
        expect(cities, contains('Lagos'));
      });
    });

    group('LargeCityConfig', () {
      test('should meet large city criteria for Brooklyn', () {
        final config = service.getCityConfig('Brooklyn');

        expect(config, isNotNull);
        expect(config?.meetsLargeCityCriteria, isTrue);
      });

      test('should meet large city criteria for Los Angeles', () {
        final config = service.getCityConfig('Los Angeles');

        expect(config, isNotNull);
        expect(config?.meetsLargeCityCriteria, isTrue);
      });

      test('should meet large city criteria for Tokyo', () {
        final config = service.getCityConfig('Tokyo');

        expect(config, isNotNull);
        expect(config?.meetsLargeCityCriteria, isTrue);
      });
    });
  });
}


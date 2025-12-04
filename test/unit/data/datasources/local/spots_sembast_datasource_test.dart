import 'package:flutter_test/flutter_test.dart';
import 'package:spots/data/datasources/local/spots_sembast_datasource.dart';
import 'package:spots/data/datasources/local/sembast_database.dart';
import 'package:spots/core/models/spot.dart';

/// Spots Sembast Data Source Tests
/// Tests local spots data storage using Sembast
void main() {
  group('SpotsSembastDataSource', () {
    late SpotsSembastDataSource dataSource;

    setUp(() {
      // Use in-memory database for tests
      SembastDatabase.useInMemoryForTests();
      dataSource = SpotsSembastDataSource();
    });

    tearDown(() async {
      // Clean up database after each test
      final db = await SembastDatabase.database;
      await db.close();
    });

    group('createSpot', () {
      test('should create spot in database', () async {
        final spot = Spot(
          id: 'spot-1',
          name: 'Test Spot',
          description: 'Test Description',
          latitude: 37.7749,
          longitude: -122.4194,
          category: 'restaurant',
          rating: 4.0,
          createdBy: 'test_user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final key = await dataSource.createSpot(spot);

        expect(key, isNotEmpty);
      });
    });

    group('getSpotById', () {
      test('should get spot by id', () async {
        final spot = Spot(
          id: 'spot-1',
          name: 'Test Spot',
          description: 'Test Description',
          latitude: 37.7749,
          longitude: -122.4194,
          category: 'restaurant',
          rating: 4.0,
          createdBy: 'test_user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await dataSource.createSpot(spot);
        final retrieved = await dataSource.getSpotById('spot-1');

        expect(retrieved, isNotNull);
        expect(retrieved?.name, equals('Test Spot'));
      });

      test('should return null for non-existent spot', () async {
        final spot = await dataSource.getSpotById('non-existent');

        expect(spot, isNull);
      });
    });

    group('updateSpot', () {
      test('should update existing spot', () async {
        final spot = Spot(
          id: 'spot-1',
          name: 'Original Name',
          description: 'Original Description',
          latitude: 37.7749,
          longitude: -122.4194,
          category: 'restaurant',
          rating: 4.0,
          createdBy: 'test_user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await dataSource.createSpot(spot);
        
        final updated = spot.copyWith(name: 'Updated Name');
        final result = await dataSource.updateSpot(updated);

        expect(result.name, equals('Updated Name'));
      });
    });

    group('deleteSpot', () {
      test('should delete spot from database', () async {
        final spot = Spot(
          id: 'spot-1',
          name: 'Test Spot',
          description: 'Test Description',
          latitude: 37.7749,
          longitude: -122.4194,
          category: 'restaurant',
          rating: 4.0,
          createdBy: 'test_user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await dataSource.createSpot(spot);
        await dataSource.deleteSpot('spot-1');

        final deleted = await dataSource.getSpotById('spot-1');
        expect(deleted, isNull);
      });
    });

    group('getAllSpots', () {
      test('should get all spots from database', () async {
        final spot1 = Spot(
          id: 'spot-1',
          name: 'Spot 1',
          description: 'Description 1',
          latitude: 37.7749,
          longitude: -122.4194,
          category: 'restaurant',
          rating: 4.0,
          createdBy: 'test_user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final spot2 = Spot(
          id: 'spot-2',
          name: 'Spot 2',
          description: 'Description 2',
          latitude: 37.7849,
          longitude: -122.4294,
          category: 'park',
          rating: 4.5,
          createdBy: 'test_user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await dataSource.createSpot(spot1);
        await dataSource.createSpot(spot2);

        final spots = await dataSource.getAllSpots();

        expect(spots.length, greaterThanOrEqualTo(2));
      });
    });

    group('getSpotsByCategory', () {
      test('should filter spots by category', () async {
        final restaurant = Spot(
          id: 'spot-1',
          name: 'Restaurant',
          description: 'Food place',
          latitude: 37.7749,
          longitude: -122.4194,
          category: 'restaurant',
          rating: 4.0,
          createdBy: 'test_user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final park = Spot(
          id: 'spot-2',
          name: 'Park',
          description: 'Green space',
          latitude: 37.7849,
          longitude: -122.4294,
          category: 'park',
          rating: 4.5,
          createdBy: 'test_user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await dataSource.createSpot(restaurant);
        await dataSource.createSpot(park);

        final restaurants = await dataSource.getSpotsByCategory('restaurant');

        expect(restaurants.length, greaterThanOrEqualTo(1));
        expect(restaurants.first.category, equals('restaurant'));
      });
    });

    group('searchSpots', () {
      test('should search spots by query', () async {
        final spot = Spot(
          id: 'spot-1',
          name: 'Coffee Shop',
          description: 'Great coffee place',
          latitude: 37.7749,
          longitude: -122.4194,
          category: 'cafe',
          rating: 4.5,
          createdBy: 'test_user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await dataSource.createSpot(spot);

        final results = await dataSource.searchSpots('coffee');

        expect(results.length, greaterThanOrEqualTo(1));
        expect(results.first.name.toLowerCase(), contains('coffee'));
      });

      test('should search by description', () async {
        final spot = Spot(
          id: 'spot-1',
          name: 'Restaurant',
          description: 'Italian cuisine',
          latitude: 37.7749,
          longitude: -122.4194,
          category: 'restaurant',
          rating: 4.0,
          createdBy: 'test_user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await dataSource.createSpot(spot);

        final results = await dataSource.searchSpots('italian');

        expect(results.length, greaterThanOrEqualTo(1));
      });
    });

    group('getSpotsFromRespectedLists', () {
      test('should return spots from respected lists', () async {
        final spots = await dataSource.getSpotsFromRespectedLists();

        expect(spots, isA<List<Spot>>());
      });
    });
  });
}


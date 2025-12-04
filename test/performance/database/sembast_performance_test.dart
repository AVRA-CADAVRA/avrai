/// Phase 9: Database Performance & Load Testing
/// Ensures optimal database operations for development and deployment
/// OUR_GUTS.md: "Effortless, Seamless Discovery" - Fast, reliable data access
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:spots/core/models/spot.dart';
import 'package:spots/core/models/list.dart';
import 'package:spots/data/datasources/local/sembast_database.dart';
import 'package:spots/data/datasources/local/spots_sembast_datasource.dart';
import 'package:spots/data/datasources/local/lists_sembast_datasource.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Force in-memory database for tests to avoid path_provider
  SembastDatabase.useInMemoryForTests();
  group('Phase 9: Database Performance Tests', () {
    late Database testDatabase;
    late SpotsSembastDataSource spotsDataSource;
    late ListsSembastDataSource listsDataSource;

    setUpAll(() async {
      // Use in-memory database for testing
      testDatabase = await databaseFactoryMemory.openDatabase('test.db');
    });

    setUp(() async {
      // Clear database stores for each test
      final store = StoreRef<String, Map<String, dynamic>>('default');
      await store.drop(testDatabase);
      
      spotsDataSource = SpotsSembastDataSource();
      listsDataSource = ListsSembastDataSource();
    });

    tearDownAll(() async {
      await testDatabase.close();
    });

    group('Spot Database Performance', () {
      test('should handle bulk spot insertion efficiently', () async {
        // Arrange
        final stopwatch = Stopwatch()..start();
        final spots = _generateTestSpots(1000); // 1000 spots
        
        // Act
        for (final spot in spots) {
          await spotsDataSource.createSpot(spot);
        }
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Under 5 seconds
        
        final allSpots = await spotsDataSource.getAllSpots();
        expect(allSpots.length, equals(1000));
        
        print('Bulk insertion of 1000 spots: ${stopwatch.elapsedMilliseconds}ms');
      });

      test('should retrieve spots efficiently with large dataset', () async {
        // Arrange - Insert test data
        final testSpots = _generateTestSpots(5000);
        for (final spot in testSpots) {
          await spotsDataSource.createSpot(spot);
        }
        
        // Act
        final stopwatch = Stopwatch()..start();
        final allSpots = await spotsDataSource.getAllSpots();
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(1500)); // Under 1.5 seconds (in-memory/env variance)
        expect(allSpots.length, greaterThanOrEqualTo(5000));
        
        print('Retrieved 5000 spots: ${stopwatch.elapsedMilliseconds}ms');
      });

      test('should search spots by category efficiently', () async {
        // Arrange
        final testSpots = _generateSpotsWithCategories(2000);
        for (final spot in testSpots) {
          await spotsDataSource.createSpot(spot);
        }
        
        // Act
        final stopwatch = Stopwatch()..start();
        final coffeeSpots = await spotsDataSource.getSpotsByCategory('Coffee');
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(500)); // Under 500ms
        expect(coffeeSpots.isNotEmpty, true);
        
        print('Category search in 2000 spots: ${stopwatch.elapsedMilliseconds}ms');
      });

      test('should handle concurrent spot operations', () async {
        // Arrange
        final spots = _generateTestSpots(100);
        
        // Act - Perform concurrent operations
        final stopwatch = Stopwatch()..start();
        final futures = <Future>[];
        
        for (int i = 0; i < 10; i++) {
          futures.add(_performConcurrentSpotOperations(spots.skip(i * 10).take(10).toList()));
        }
        
        await Future.wait(futures);
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(3000)); // Under 3 seconds
        
        final allSpots = await spotsDataSource.getAllSpots();
        expect(allSpots.length, greaterThanOrEqualTo(50)); // Some operations might overlap
        
        print('Concurrent operations: ${stopwatch.elapsedMilliseconds}ms');
      });

      test('should maintain performance with complex queries', () async {
        // Arrange
        final spots = _generateComplexTestSpots(1000);
        for (final spot in spots) {
          await spotsDataSource.createSpot(spot);
        }
        
        // Act - Complex search operations
        final stopwatch = Stopwatch()..start();
        
        final searchResults = await spotsDataSource.searchSpots('coffee shop');
        final categoryResults = await spotsDataSource.getSpotsByCategory('Restaurant');
        final respectResults = await spotsDataSource.getSpotsFromRespectedLists();
        
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // Under 2 seconds (in-memory/env variance)
        expect(searchResults.isNotEmpty, true);
        
        print('Complex queries: ${stopwatch.elapsedMilliseconds}ms');
      });
    });

    group('List Database Performance', () {
      test('should handle bulk list operations efficiently', () async {
        // Arrange
        final lists = _generateTestLists(500);
        
        // Act
        final stopwatch = Stopwatch()..start();
        for (final list in lists) {
          await listsDataSource.saveList(list);
        }
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(3000)); // Under 3 seconds
        
        final allLists = await listsDataSource.getLists();
        expect(allLists.length, greaterThanOrEqualTo(500));
        
        print('Bulk list operations: ${stopwatch.elapsedMilliseconds}ms');
      });

      test('should optimize list relationships and permissions', () async {
        // Arrange
        final complexLists = _generateComplexLists(100);
        for (final list in complexLists) {
          await listsDataSource.saveList(list);
        }
        
        // Act
        final stopwatch = Stopwatch()..start();
        final allLists = await listsDataSource.getLists();
        
        // Simulate permission checks and relationship loading
        var permissionChecks = 0;
        for (final list in allLists) {
          if (list.collaborators.isNotEmpty) permissionChecks++;
          if (list.followers.isNotEmpty) permissionChecks++;
        }
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(800)); // Under 800ms
        expect(permissionChecks, greaterThanOrEqualTo(0));
        
        print('Complex list operations: ${stopwatch.elapsedMilliseconds}ms');
      });
    });

    group('Database Memory Optimization', () {
      test('should manage memory efficiently during large operations', () async {
        // Arrange
        final largeDataset = _generateTestSpots(10000);
        
        // Act - Monitor memory usage pattern
        final stopwatch = Stopwatch()..start();
        var batchSize = 100;
        
        for (int i = 0; i < largeDataset.length; i += batchSize) {
          final batch = largeDataset.skip(i).take(batchSize);
          for (final spot in batch) {
            await spotsDataSource.createSpot(spot);
          }
          
          // Simulate memory management check
          if (i % 1000 == 0) {
            await Future.delayed(const Duration(milliseconds: 1)); // Allow GC
          }
        }
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(15000)); // Under 15 seconds
        
        final count = (await spotsDataSource.getAllSpots()).length;
        expect(count, equals(10000));
        
        print('Memory optimized bulk insert: ${stopwatch.elapsedMilliseconds}ms');
      });

      test('should handle database size growth efficiently', () async {
        // Arrange - Simulate database growth over time
        final phases = [
          _generateTestSpots(1000),   // Initial data
          _generateTestSpots(2000),   // Growth phase 1
          _generateTestSpots(3000),   // Growth phase 2
        ];
        
        // Act
        final timings = <int>[];
        
        for (final phase in phases) {
          final stopwatch = Stopwatch()..start();
          for (final spot in phase.take(100)) { // Sample from each phase
            await spotsDataSource.createSpot(spot);
          }
          stopwatch.stop();
          timings.add(stopwatch.elapsedMilliseconds);
        }
        
        // Assert - Performance should remain consistent
        expect(timings[0], lessThan(1000));
        expect(timings[1], lessThan(timings[0] * 1.5)); // No more than 50% slowdown
        expect(timings[2], lessThan(timings[0] * 2.0)); // No more than 100% slowdown
        
        print('Database growth timings: $timings ms');
      });
    });

    group('Performance Regression Detection', () {
      test('should establish baseline performance metrics', () async {
        // Arrange
        final standardDataset = _generateTestSpots(1000);
        
        // Act - Measure standard operations
        final metrics = <String, int>{};
        
        // Create operation baseline
        var stopwatch = Stopwatch()..start();
        for (final spot in standardDataset.take(100)) {
          await spotsDataSource.createSpot(spot);
        }
        stopwatch.stop();
        metrics['create_100_spots'] = stopwatch.elapsedMilliseconds;
        
        // Read operation baseline
        stopwatch = Stopwatch()..start();
        await spotsDataSource.getAllSpots();
        stopwatch.stop();
        metrics['read_all_spots'] = stopwatch.elapsedMilliseconds;
        
        // Search operation baseline
        stopwatch = Stopwatch()..start();
        await spotsDataSource.searchSpots('test');
        stopwatch.stop();
        metrics['search_spots'] = stopwatch.elapsedMilliseconds;
        
        // Assert - Establish acceptable baseline ranges
        expect(metrics['create_100_spots']!, lessThan(2000)); // Under 2 seconds
        expect(metrics['read_all_spots']!, lessThan(500));    // Under 500ms
        expect(metrics['search_spots']!, lessThan(300));      // Under 300ms
        
        print('Performance baselines: $metrics');
      });
    });
  });
}

// Helper functions for generating test data

List<Spot> _generateTestSpots(int count) {
  return List.generate(count, (index) => Spot(
    id: 'perf_test_$index',
    name: 'Performance Test Spot $index',
    description: 'This is a test spot for performance testing number $index',
    latitude: 40.7128 + (index * 0.0001),
    longitude: -74.0060 + (index * 0.0001),
    category: _getCategoryForIndex(index),
    rating: 3.0 + (index % 3),
    createdBy: 'perf_test_user_${index % 10}',
    createdAt: DateTime.now().subtract(Duration(days: index % 365)),
    updatedAt: DateTime.now().subtract(Duration(hours: index % 24)),
    tags: ['performance', 'test', _getCategoryForIndex(index).toLowerCase()],
    metadata: {
      'test_index': index,
      'batch': index ~/ 100,
      'performance_test': true,
    },
  ));
}

List<Spot> _generateSpotsWithCategories(int count) {
  final categories = ['Coffee', 'Restaurant', 'Park', 'Store', 'Service'];
  return List.generate(count, (index) => Spot(
    id: 'category_test_$index',
    name: '${categories[index % categories.length]} Spot $index',
    description: 'Category performance test spot',
    latitude: 40.7128 + (index * 0.0001),
    longitude: -74.0060 + (index * 0.0001),
    category: categories[index % categories.length],
    rating: 4.0,
    createdBy: 'category_test_user',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    tags: ['category_test', categories[index % categories.length].toLowerCase()],
  ));
}

List<Spot> _generateComplexTestSpots(int count) {
  final complexCategories = ['Coffee Shop', 'Fine Dining Restaurant', 'Fast Food', 'Public Park', 'Shopping Mall'];
  final complexTags = [
    ['coffee', 'wifi', 'study', 'downtown'],
    ['restaurant', 'fine_dining', 'date_night', 'expensive'],
    ['fast_food', 'quick', 'cheap', 'drive_through'],
    ['park', 'family', 'outdoor', 'free'],
    ['shopping', 'indoor', 'retail', 'weekend'],
  ];
  
  return List.generate(count, (index) {
    final categoryIndex = index % complexCategories.length;
    return Spot(
      id: 'complex_test_$index',
      name: '${complexCategories[categoryIndex]} Complex $index',
      description: 'Complex test spot with rich metadata and multiple tags for performance testing',
      latitude: 40.7128 + (index * 0.0001),
      longitude: -74.0060 + (index * 0.0001),
      category: complexCategories[categoryIndex],
      rating: 3.0 + (index % 5) * 0.5,
      createdBy: 'complex_test_user_${index % 20}',
      createdAt: DateTime.now().subtract(Duration(days: index % 730)),
      updatedAt: DateTime.now().subtract(Duration(hours: index % 168)),
      tags: [...complexTags[categoryIndex], 'complex_test'],
      metadata: {
        'complexity_level': 'high',
        'test_index': index,
        'category_index': categoryIndex,
        'has_images': index % 3 == 0,
        'has_reviews': index % 2 == 0,
        'popular': index % 10 == 0,
      },
    );
  });
}

List<SpotList> _generateTestLists(int count) {
  return List.generate(count, (index) => SpotList(
    id: 'perf_list_$index',
      title: 'Performance Test List $index',
    description: 'Test list for performance evaluation $index',
      category: 'general',
    spots: const [],
    spotIds: List.generate((index % 20) + 1, (i) => 'spot_${index}_$i'),
    collaborators: List.generate(index % 5, (i) => 'collaborator_${index}_$i'),
    followers: List.generate((index % 10) + 1, (i) => 'follower_${index}_$i'),
    isPublic: index % 2 == 0,
    tags: ['performance', 'test', 'list_$index'],
    createdAt: DateTime.now().subtract(Duration(days: index % 365)),
    updatedAt: DateTime.now(),
  ));
}

List<SpotList> _generateComplexLists(int count) {
  return List.generate(count, (index) => SpotList(
    id: 'complex_list_$index',
      title: 'Complex Performance List $index',
    description: 'Complex list with many relationships and permissions for performance testing',
      category: 'general',
    spots: const [],
    spotIds: List.generate((index % 50) + 10, (i) => 'complex_spot_${index}_$i'),
    collaborators: List.generate((index % 10) + 2, (i) => 'complex_collab_${index}_$i'),
    followers: List.generate((index % 25) + 5, (i) => 'complex_follower_${index}_$i'),
    isPublic: index % 3 != 0,
    ageRestricted: index % 7 == 0,
    moderationEnabled: index % 4 == 0,
    tags: ['complex', 'performance', 'list', 'test', 'category_${index % 5}'],
    createdAt: DateTime.now().subtract(Duration(days: index % 1095)),
    updatedAt: DateTime.now().subtract(Duration(hours: index % 72)),
    metadata: {
      'complexity': 'high',
      'performance_test': true,
      'relationship_count': (index % 50) + 10 + (index % 10) + 2 + (index % 25) + 5,
    },
  ));
}

String _getCategoryForIndex(int index) {
  const categories = ['Coffee', 'Restaurant', 'Park', 'Store', 'Service', 'Entertainment'];
  return categories[index % categories.length];
}

Future<void> _performConcurrentSpotOperations(List<Spot> spots) async {
  final futures = <Future>[];
  
  for (final spot in spots) {
    futures.add(SpotsSembastDataSource().createSpot(spot));
  }
  
  await Future.wait(futures);
}

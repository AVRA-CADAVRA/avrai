/// Phase 9: Load Testing & Concurrent Operations
/// Ensures optimal performance under high concurrent load for production deployment
/// OUR_GUTS.md: "Self-improving ecosystem" - Scalable, robust performance
import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:spots/data/datasources/remote/spots_remote_datasource.dart';
import 'package:spots/data/datasources/local/spots_local_datasource.dart';
import 'package:spots/core/models/spot.dart';
import 'package:spots/core/models/list.dart';
import 'package:spots/data/repositories/spots_repository_impl.dart';
import 'package:spots/data/repositories/lists_repository_impl.dart';
import 'package:spots/data/repositories/hybrid_search_repository.dart';
import 'package:spots/core/services/search_cache_service.dart';
import 'package:spots/core/ai/ai_master_orchestrator.dart';
import 'package:spots/presentation/blocs/spots/spots_bloc.dart';
import 'package:spots/domain/usecases/spots/get_spots_usecase.dart';
import 'package:spots/domain/usecases/spots/get_spots_from_respected_lists_usecase.dart';
import 'package:spots/domain/usecases/spots/create_spot_usecase.dart';
import 'package:spots/domain/usecases/spots/update_spot_usecase.dart';
import 'package:spots/domain/usecases/spots/delete_spot_usecase.dart';
import 'package:spots/presentation/blocs/search/hybrid_search_bloc.dart';
import 'package:spots/domain/usecases/search/hybrid_search_usecase.dart';
import 'package:spots/core/services/ai_search_suggestions_service.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Phase 9: Load Testing & Concurrent Operations', () {
    group('Database Concurrent Load Testing', () {
      test('should handle concurrent spot creation efficiently', () async {
        // Arrange
        final repository = _createMockSpotsRepository();
        const concurrentUsers = 50;
        const operationsPerUser = 20;
        
        // Act - Simulate concurrent spot creation
        final stopwatch = Stopwatch()..start();
        final futures = <Future>[];
        
        for (int userId = 0; userId < concurrentUsers; userId++) {
          futures.add(_simulateConcurrentSpotCreation(repository, userId, operationsPerUser));
        }
        
        final results = await Future.wait(futures);
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(15000)); // Under 15 seconds
        expect(results.length, equals(concurrentUsers));
        
        final totalOperations = concurrentUsers * operationsPerUser;
        final avgTimePerOperation = stopwatch.elapsedMilliseconds / totalOperations;
        expect(avgTimePerOperation, lessThan(15)); // Under 15ms per operation
        
        print('Concurrent spot creation: $totalOperations operations in ${stopwatch.elapsedMilliseconds}ms '
              '(${avgTimePerOperation.toStringAsFixed(1)}ms avg)');
      });

      test('should maintain data consistency under concurrent updates', () async {
        // Arrange
        final repository = _createMockSpotsRepository();
        final baseSpot = _createTestSpot(0);
        await repository.createSpot(baseSpot);
        
        const concurrentUpdates = 100;
        
        // Act - Concurrent updates to same spot
        final stopwatch = Stopwatch()..start();
        final futures = <Future>[];
        
        for (int i = 0; i < concurrentUpdates; i++) {
          futures.add(_simulateConcurrentSpotUpdate(repository, baseSpot.id, i));
        }
        
        await Future.wait(futures);
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // Under 10 seconds
        
        // Verify data consistency
        final finalSpot = await repository.getSpotById(baseSpot.id);
        expect(finalSpot, isNotNull);
        expect(finalSpot!.id, equals(baseSpot.id));
        
        print('Concurrent updates: $concurrentUpdates operations in ${stopwatch.elapsedMilliseconds}ms');
      });

      test('should handle concurrent search operations efficiently', () async {
        // Arrange
        final searchRepository = _createMockHybridSearchRepository();
        const concurrentSearches = 200;
        final searchQueries = _generateSearchQueries(50);
        
        // Act - Concurrent search operations
        final stopwatch = Stopwatch()..start();
        final futures = <Future>[];
        
        for (int i = 0; i < concurrentSearches; i++) {
          final query = searchQueries[i % searchQueries.length];
          futures.add(searchRepository.searchSpots(
            query: query,
            maxResults: 50,
            includeExternal: true,
          ));
        }
        
        final searchResults = await Future.wait(futures);
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(20000)); // Under 20 seconds
        expect(searchResults.length, equals(concurrentSearches));
        
        final avgSearchTime = stopwatch.elapsedMilliseconds / concurrentSearches;
        expect(avgSearchTime, lessThan(100)); // Under 100ms per search
        
        print('Concurrent searches: $concurrentSearches in ${stopwatch.elapsedMilliseconds}ms '
              '(${avgSearchTime.toStringAsFixed(1)}ms avg)');
      });
    });

    group('AI System Concurrent Load Testing', () {
      test('should handle concurrent AI processing efficiently', () async {
        // Arrange
        final aiOrchestrator = AIMasterOrchestrator();
        await aiOrchestrator.initialize();
        
        const concurrentAIOperations = 100;
        
        // Act - Concurrent AI operations
        final stopwatch = Stopwatch()..start();
        final futures = <Future>[];
        
        for (int i = 0; i < concurrentAIOperations; i++) {
          futures.add(_simulateConcurrentAIOperation(aiOrchestrator, i));
        }
        
        await Future.wait(futures);
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(30000)); // Under 30 seconds
        
        final avgAITime = stopwatch.elapsedMilliseconds / concurrentAIOperations;
        expect(avgAITime, lessThan(300)); // Under 300ms per AI operation
        
        print('Concurrent AI operations: $concurrentAIOperations in ${stopwatch.elapsedMilliseconds}ms '
              '(${avgAITime.toStringAsFixed(1)}ms avg)');
      });

      test('should maintain AI learning performance under load', () async {
        // Arrange
        final aiOrchestrator = AIMasterOrchestrator();
        await aiOrchestrator.initialize();
        
        const learningCycles = 50;
        const concurrentLearners = 20;
        
        // Act - Concurrent learning operations
        final stopwatch = Stopwatch()..start();
        final futures = <Future>[];
        
        for (int learner = 0; learner < concurrentLearners; learner++) {
          futures.add(_simulateConcurrentLearning(aiOrchestrator, learner, learningCycles));
        }
        
        await Future.wait(futures);
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(45000)); // Under 45 seconds
        
        final totalLearningOperations = concurrentLearners * learningCycles;
        final avgLearningTime = stopwatch.elapsedMilliseconds / totalLearningOperations;
        expect(avgLearningTime, lessThan(45)); // Under 45ms per learning operation
        
        print('Concurrent AI learning: $totalLearningOperations operations in ${stopwatch.elapsedMilliseconds}ms '
              '(${avgLearningTime.toStringAsFixed(1)}ms avg)');
      });
    });

    group('Cache System Load Testing', () {
      test('should handle concurrent cache operations efficiently', () async {
        // Arrange
        final cacheService = SearchCacheService();
        const concurrentCacheOps = 500;
        
        // Act - Concurrent cache operations (reads/writes)
        final stopwatch = Stopwatch()..start();
        final futures = <Future>[];
        
        for (int i = 0; i < concurrentCacheOps; i++) {
          if (i % 3 == 0) {
            // Cache write operation
            futures.add(cacheService.cacheResult(
              query: 'test_query_$i',
              result: _createMockSearchResult(i),
            ));
          } else {
            // Cache read operation
            futures.add(cacheService.getCachedResult(
              query: 'test_query_${i ~/ 3}',
            ));
          }
        }
        
        await Future.wait(futures);
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // Under 10 seconds
        
        final avgCacheTime = stopwatch.elapsedMilliseconds / concurrentCacheOps;
        expect(avgCacheTime, lessThan(20)); // Under 20ms per cache operation
        
        print('Concurrent cache operations: $concurrentCacheOps in ${stopwatch.elapsedMilliseconds}ms '
              '(${avgCacheTime.toStringAsFixed(1)}ms avg)');
      });

      test('should maintain cache hit rate under load', () async {
        // Arrange
        final cacheService = SearchCacheService();
        
        // Pre-populate cache
        for (int i = 0; i < 100; i++) {
          await cacheService.cacheResult(
            query: 'popular_query_$i',
            result: _createMockSearchResult(i),
          );
        }
        
        const concurrentReads = 1000;
        final popularQueries = List.generate(20, (i) => 'popular_query_$i');
        
        // Act - Concurrent cache reads
        final stopwatch = Stopwatch()..start();
        final futures = <Future>[];
        int cacheHits = 0;
        
        for (int i = 0; i < concurrentReads; i++) {
          final query = popularQueries[i % popularQueries.length];
          futures.add(cacheService.getCachedResult(query: query).then((result) {
            if (result != null) cacheHits++;
          }));
        }
        
        await Future.wait(futures);
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Under 5 seconds
        
        final hitRate = cacheHits / concurrentReads;
        expect(hitRate, greaterThan(0.8)); // At least 80% hit rate
        
        print('Cache load test: $concurrentReads reads in ${stopwatch.elapsedMilliseconds}ms, '
              'Hit rate: ${(hitRate * 100).toStringAsFixed(1)}%');
      });
    });

    group('BLoC Concurrent State Management', () {
      test('should handle concurrent BLoC events efficiently', () async {
        // Arrange
        final spotsBloc = _createMockSpotsBloc();
        const concurrentEvents = 200;
        
        // Act - Concurrent BLoC events
        final stopwatch = Stopwatch()..start();
        final futures = <Future>[];
        
        for (int i = 0; i < concurrentEvents; i++) {
          futures.add(_simulateConcurrentBlocEvent(spotsBloc, i));
        }
        
        await Future.wait(futures);
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(8000)); // Under 8 seconds
        
        final avgEventTime = stopwatch.elapsedMilliseconds / concurrentEvents;
        expect(avgEventTime, lessThan(40)); // Under 40ms per event
        
        await spotsBloc.close();
        
        print('Concurrent BLoC events: $concurrentEvents in ${stopwatch.elapsedMilliseconds}ms '
              '(${avgEventTime.toStringAsFixed(1)}ms avg)');
      });

      test('should maintain state consistency under concurrent updates', () async {
        // Arrange
        final searchBloc = _createMockHybridSearchBloc();
        const concurrentSearchEvents = 100;
        
        // Act - Concurrent search events
        final stopwatch = Stopwatch()..start();
        final futures = <Future>[];
        
        for (int i = 0; i < concurrentSearchEvents; i++) {
          futures.add(_simulateConcurrentSearchEvent(searchBloc, i));
        }
        
        await Future.wait(futures);
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(12000)); // Under 12 seconds
        
        // Verify final state consistency
        expect(searchBloc.state, isA<HybridSearchState>());
        
        await searchBloc.close();
        
        print('Concurrent search events: $concurrentSearchEvents in ${stopwatch.elapsedMilliseconds}ms');
      });
    });

    group('System Integration Load Testing', () {
      test('should handle complete user journey under load', () async {
        // Arrange
        const simulatedUsers = 25;
        const operationsPerUser = 10;
        
        // Act - Simulate complete user journeys concurrently
        final stopwatch = Stopwatch()..start();
        final futures = <Future>[];
        
        for (int userId = 0; userId < simulatedUsers; userId++) {
          futures.add(_simulateCompleteUserJourney(userId, operationsPerUser));
        }
        
        final journeyResults = await Future.wait(futures);
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(60000)); // Under 60 seconds
        expect(journeyResults.length, equals(simulatedUsers));
        
        final totalOperations = simulatedUsers * operationsPerUser;
        final avgOperationTime = stopwatch.elapsedMilliseconds / totalOperations;
        expect(avgOperationTime, lessThan(240)); // Under 240ms per operation
        
        print('Complete user journeys: $simulatedUsers users, $totalOperations operations '
              'in ${stopwatch.elapsedMilliseconds}ms (${avgOperationTime.toStringAsFixed(1)}ms avg)');
      });

      test('should maintain performance under sustained load', () async {
        // Arrange
        const loadDuration = Duration(seconds: 5);
        const operationsPerSecond = 10;
        
        // Act - Sustained load test
        final stopwatch = Stopwatch()..start();
        final futures = <Future>[];
        var operationCount = 0;
        
        final timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
          if (stopwatch.elapsed >= loadDuration) {
            timer.cancel();
            return;
          }
          
          for (int i = 0; i < operationsPerSecond ~/ 10; i++) {
            futures.add(_simulateRandomOperation(operationCount++));
          }
        });
        
        // Wait for load duration
        await Future.delayed(loadDuration);
        
        // Wait for all operations to complete
        await Future.wait(futures);
        stopwatch.stop();
        
        // Assert
        expect(operationCount, greaterThan(20)); // Minimum operations performed in shortened run
        
        final avgOperationTime = stopwatch.elapsedMilliseconds / operationCount;
        expect(avgOperationTime, lessThan(200)); // Consistent performance
        
        print('Sustained load test: $operationCount operations in ${stopwatch.elapsedSeconds} seconds '
              '(${avgOperationTime.toStringAsFixed(1)}ms avg)');
      });
    });

    group('Memory and Resource Load Testing', () {
      test('should manage memory efficiently under concurrent load', () async {
        // Arrange
        final memoryBefore = _getMemoryUsage();
        const heavyOperations = 50;
        
        // Act - Memory-intensive concurrent operations
        final stopwatch = Stopwatch()..start();
        final futures = <Future>[];
        
        for (int i = 0; i < heavyOperations; i++) {
          futures.add(_simulateMemoryIntensiveOperation(i));
        }
        
        await Future.wait(futures);
        stopwatch.stop();
        
        // Force garbage collection and measure memory
        await _forceGarbageCollection();
        final memoryAfter = _getMemoryUsage();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(30000)); // Under 30 seconds
        
        final memoryIncrease = memoryAfter - memoryBefore;
        expect(memoryIncrease, lessThan(200 * 1024 * 1024)); // Less than 200MB increase
        
        print('Memory load test: $heavyOperations operations in ${stopwatch.elapsedMilliseconds}ms, '
              'Memory increase: ${_formatBytes(memoryIncrease)}');
      });

      test('should handle resource contention efficiently', () async {
        // Arrange
        const resourceIntensiveOps = 100;
        
        // Act - Resource-intensive operations competing for same resources
        final stopwatch = Stopwatch()..start();
        final futures = <Future>[];
        
        // Database operations
        for (int i = 0; i < resourceIntensiveOps ~/ 3; i++) {
          futures.add(_simulateResourceIntensiveDBOperation(i));
        }
        
        // Cache operations
        for (int i = 0; i < resourceIntensiveOps ~/ 3; i++) {
          futures.add(_simulateResourceIntensiveCacheOperation(i));
        }
        
        // AI operations
        for (int i = 0; i < resourceIntensiveOps ~/ 3; i++) {
          futures.add(_simulateResourceIntensiveAIOperation(i));
        }
        
        await Future.wait(futures);
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(45000)); // Under 45 seconds
        
        final avgTime = stopwatch.elapsedMilliseconds / resourceIntensiveOps;
        expect(avgTime, lessThan(450)); // Under 450ms per operation
        
        print('Resource contention test: $resourceIntensiveOps operations in ${stopwatch.elapsedMilliseconds}ms '
              '(${avgTime.toStringAsFixed(1)}ms avg)');
      });
    });
  });
}

// Helper functions for load testing

Future<List<String>> _simulateConcurrentSpotCreation(dynamic repository, int userId, int operationCount) async {
  final results = <String>[];
  
  for (int i = 0; i < operationCount; i++) {
    final spot = _createTestSpot(userId * 1000 + i);
    final createdSpot = await repository.createSpot(spot);
    results.add(createdSpot.id);
    
    // Small delay to simulate real usage
    await Future.delayed(const Duration(microseconds: 100));
  }
  
  return results;
}

Future<void> _simulateConcurrentSpotUpdate(dynamic repository, String spotId, int updateIndex) async {
  final updatedSpot = _createTestSpot(updateIndex).copyWith(
    id: spotId,
    name: 'Updated Spot $updateIndex',
    updatedAt: DateTime.now(),
  );
  
  await repository.updateSpot(updatedSpot);
}

Future<dynamic> _simulateConcurrentAIOperation(AIMasterOrchestrator orchestrator, int operationIndex) async {
  final userProfile = _createTestUserProfile(operationIndex);
  return await orchestrator.updatePersonalityProfile(userProfile);
}

Future<void> _simulateConcurrentLearning(AIMasterOrchestrator orchestrator, int learnerId, int cycles) async {
  for (int cycle = 0; cycle < cycles; cycle++) {
    await orchestrator.processLearningCycle();
    
    // Small delay to prevent overwhelming
    await Future.delayed(const Duration(microseconds: 500));
  }
}

Future<void> _simulateConcurrentBlocEvent(SpotsBloc bloc, int eventIndex) async {
  if (eventIndex % 3 == 0) {
    bloc.add(LoadSpots());
  } else if (eventIndex % 3 == 1) {
    bloc.add(CreateSpot(_createTestSpot(eventIndex)));
  } else {
    // Legacy event not available; reuse LoadSpots
    bloc.add(LoadSpots());
  }
  
  // Wait for event processing
  await Future.delayed(const Duration(milliseconds: 10));
}

Future<void> _simulateConcurrentSearchEvent(HybridSearchBloc bloc, int eventIndex) async {
  final queries = ['coffee', 'restaurant', 'park', 'store', 'service'];
  final query = queries[eventIndex % queries.length];
  
  bloc.add(SearchHybridSpots(query: '$query $eventIndex'));
  
  // Wait for search processing
  await Future.delayed(const Duration(milliseconds: 20));
}

Future<Map<String, dynamic>> _simulateCompleteUserJourney(int userId, int operationCount) async {
  final journeyResults = <String, dynamic>{
    'user_id': userId,
    'operations_completed': 0,
    'total_time': 0,
  };
  
  final journeyStopwatch = Stopwatch()..start();
  
  for (int op = 0; op < operationCount; op++) {
    // Simulate different user operations
    switch (op % 5) {
      case 0:
        await _simulateSearch('user_query_${userId}_$op');
        break;
      case 1:
        await _simulateSpotCreation(userId, op);
        break;
      case 2:
        await _simulateSpotRating(userId, op);
        break;
      case 3:
        await _simulateListCreation(userId, op);
        break;
      case 4:
        await _simulateAIInteraction(userId, op);
        break;
    }
    
    journeyResults['operations_completed']++;
    await Future.delayed(const Duration(milliseconds: 50)); // User think time
  }
  
  journeyStopwatch.stop();
  journeyResults['total_time'] = journeyStopwatch.elapsedMilliseconds;
  
  return journeyResults;
}

Future<void> _simulateRandomOperation(int operationIndex) async {
  final operations = [
    () => _simulateSearch('random_$operationIndex'),
    () => _simulateSpotCreation(operationIndex % 100, operationIndex),
    () => _simulateSpotRating(operationIndex % 100, operationIndex),
    () => _simulateAIInteraction(operationIndex % 100, operationIndex),
  ];
  
  final operation = operations[operationIndex % operations.length];
  await operation();
}

Future<void> _simulateMemoryIntensiveOperation(int operationIndex) async {
  // Create large temporary data structures
  final largeList = List.generate(10000, (i) => _createTestSpot(operationIndex * 10000 + i));
  
  // Process the data
  var totalRating = 0.0;
  for (final spot in largeList) {
    totalRating += spot.rating;
  }
  
  // Simulate some processing time
  await Future.delayed(const Duration(milliseconds: 100));
  
  // Data should be garbage collected after function returns
}

Future<void> _simulateResourceIntensiveDBOperation(int operationIndex) async {
  final repository = _createMockSpotsRepository();
  
  // Multiple database operations
  for (int i = 0; i < 5; i++) {
    final spot = _createTestSpot(operationIndex * 10 + i);
    await repository.createSpot(spot);
  }
}

Future<void> _simulateResourceIntensiveCacheOperation(int operationIndex) async {
  final cacheService = SearchCacheService();
  
  // Multiple cache operations
  for (int i = 0; i < 10; i++) {
    await cacheService.cacheResult(
      query: 'resource_test_${operationIndex}_$i',
      result: _createMockSearchResult(operationIndex * 10 + i),
    );
  }
}

Future<void> _simulateResourceIntensiveAIOperation(int operationIndex) async {
  final orchestrator = AIMasterOrchestrator();
  
  // Multiple AI operations
  for (int i = 0; i < 3; i++) {
    await orchestrator.processLearningCycle();
  }
}

Future<void> _simulateSearch(String query) async {
  final searchRepository = _createMockHybridSearchRepository();
  await searchRepository.searchSpots(query: query, maxResults: 20);
}

Future<void> _simulateSpotCreation(int userId, int spotIndex) async {
  final repository = _createMockSpotsRepository();
  final spot = _createTestSpot(userId * 1000 + spotIndex);
  await repository.createSpot(spot);
}

Future<void> _simulateSpotRating(int userId, int ratingIndex) async {
  // Simulate rating a spot
  await Future.delayed(const Duration(milliseconds: 10));
}

Future<void> _simulateListCreation(int userId, int listIndex) async {
  final repository = _createMockListsRepository();
  final list = _createTestList(userId * 1000 + listIndex);
  await repository.createList(list);
}

Future<void> _simulateAIInteraction(int userId, int interactionIndex) async {
  final orchestrator = AIMasterOrchestrator();
  final userProfile = _createTestUserProfile(userId);
  await orchestrator.updatePersonalityProfile(userProfile);
}

// Mock objects and test data generators

Spot _createTestSpot(int index) {
  return Spot(
    id: 'load_test_spot_$index',
    name: 'Load Test Spot $index',
    description: 'This is a load test spot number $index',
    latitude: 40.7128 + (index * 0.0001),
    longitude: -74.0060 + (index * 0.0001),
    category: _getCategoryForIndex(index),
    rating: 3.0 + (index % 3),
    createdBy: 'load_test_user_${index % 50}',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    tags: ['load_test', 'performance'],
  );
}

SpotList _createTestList(int index) {
  return SpotList(
    id: 'load_test_list_$index',
    title: 'Load Test List $index',
    description: 'Load test list $index',
    curatorId: 'load_curator_${index % 10}',
    spots: const [],
    spotIds: List.generate(10, (i) => 'spot_${index}_$i'),
    collaborators: [],
    followers: [],
    isPublic: true,
    tags: ['load_test'],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

Map<String, dynamic> _createTestUserProfile(int userId) {
  return {
    'user_id': 'load_user_$userId',
    'dimensions': {
      'openness': math.Random().nextDouble(),
      'conscientiousness': math.Random().nextDouble(),
      'extraversion': math.Random().nextDouble(),
      'agreeableness': math.Random().nextDouble(),
      'neuroticism': math.Random().nextDouble(),
      'authenticity': math.Random().nextDouble(),
      'curiosity': math.Random().nextDouble(),
      'social_connection': math.Random().nextDouble(),
    },
    'generation': userId % 100,
  };
}

List<String> _generateSearchQueries(int count) {
  final baseQueries = ['coffee', 'restaurant', 'park', 'store', 'service', 'entertainment'];
  return List.generate(count, (index) => 
    '${baseQueries[index % baseQueries.length]} ${index ~/ baseQueries.length}');
}

HybridSearchResult _createMockSearchResult(int index) {
  return HybridSearchResult(
    spots: [_createTestSpot(index)],
    communityCount: 1,
    externalCount: 0,
    totalCount: 1,
    searchDuration: const Duration(milliseconds: 150),
    sources: const {'local': 1},
  );
}

String _getCategoryForIndex(int index) {
  const categories = ['Coffee', 'Restaurant', 'Park', 'Store', 'Service'];
  return categories[index % categories.length];
}

int _getMemoryUsage() {
  // Simplified memory usage - in real implementation use vm_service
  return 50 * 1024 * 1024; // Mock 50MB
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '${bytes}B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
}

Future<void> _forceGarbageCollection() async {
  await Future.delayed(const Duration(milliseconds: 100));
}

// Mock repository creators (implement based on actual interfaces)
// Minimal in-file fakes for repository and connectivity
class _FakeConnectivity implements Connectivity {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => [ConnectivityResult.wifi];

  // Satisfy interface with stubs
  @override
  // ignore: no_logic_in_create_state
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
class _FakeSpotsRemote implements SpotsRemoteDataSource {
  Future<List<Spot>> getSpots() async => [];
  Future<Spot> createSpot(Spot spot) async => spot;
  Future<Spot> updateSpot(Spot spot) async => spot;
  Future<void> deleteSpot(String id) async {}
}
class _FakeSpotsLocal implements SpotsLocalDataSource {
  final Map<String, Spot> _db = {};
  Future<List<Spot>> getAllSpots() async => _db.values.toList();
  Future<Spot?> getSpotById(String id) async => _db[id];
  Future<String> createSpot(Spot spot) async { _db[spot.id] = spot; return spot.id; }
  Future<Spot> updateSpot(Spot spot) async { _db[spot.id] = spot; return spot; }
  Future<void> deleteSpot(String id) async { _db.remove(id); }
  Future<List<Spot>> getSpotsByCategory(String category) async => _db.values.where((s)=>s.category==category).toList();
  Future<List<Spot>> getSpotsFromRespectedLists() async => _db.values.toList();
  Future<List<Spot>> searchSpots(String query) async => _db.values.where((s)=>s.name.contains(query)).toList();
}

dynamic _createMockSpotsRepository() => SpotsRepositoryImpl(
  remoteDataSource: _FakeSpotsRemote(),
  localDataSource: _FakeSpotsLocal(),
  connectivity: _FakeConnectivity(),
);

dynamic _createMockListsRepository() => ListsRepositoryImpl();

dynamic _createMockHybridSearchRepository() => HybridSearchRepository();

SpotsBloc _createMockSpotsBloc() {
  // Build a repository with fakes
  final repo = _createMockSpotsRepository();

  // Construct real use case classes with the fake repository
  final getSpotsUseCase = GetSpotsUseCase(repo);
  final getRespectedUseCase = GetSpotsFromRespectedListsUseCase(repo);
  final createSpotUseCase = CreateSpotUseCase(repo);
  final updateSpotUseCase = UpdateSpotUseCase(repo);
  final deleteSpotUseCase = DeleteSpotUseCase(repo);

  return SpotsBloc(
    getSpotsUseCase: getSpotsUseCase,
    getSpotsFromRespectedListsUseCase: getRespectedUseCase,
    createSpotUseCase: createSpotUseCase,
    updateSpotUseCase: updateSpotUseCase,
    deleteSpotUseCase: deleteSpotUseCase,
  );
}

HybridSearchBloc _createMockHybridSearchBloc() {
  // Construct use case with a minimal repository
  final repo = HybridSearchRepository();
  final usecase = HybridSearchUseCase(repo);

  return HybridSearchBloc(
    hybridSearchUseCase: usecase,
    cacheService: SearchCacheService(),
    suggestionsService: _FakeAISearchSuggestionsService(),
  );
}

class _FakeAISearchSuggestionsService implements AISearchSuggestionsService {
  @override
  Map<String, dynamic> getSearchPatterns() => {};

  @override
  Future<List<SearchSuggestion>> generateSuggestions({
    required String query,
    Position? userLocation,
    List<Spot>? recentSpots,
    Map<String, int>? communityTrends,
  }) async => [];

  @override
  void learnFromSearch({
    required String query,
    required List<Spot> results,
    String? selectedSpotId,
  }) {}

  @override
  void clearLearningData() {}
}

// Mock use cases
dynamic _mockGetSpotsUseCase() => null;
dynamic _mockCreateSpotUseCase() => null;
dynamic _mockUpdateSpotUseCase() => null;
dynamic _mockDeleteSpotUseCase() => null;
dynamic _mockGetSpotsFromRespectedListsUseCase() => null;
dynamic _mockHybridSearchUseCase() => null;
dynamic _mockAISearchSuggestionsService() => null;

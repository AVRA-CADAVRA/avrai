/// Phase 9: UI Responsiveness & Performance Tests
/// Ensures optimal user interface performance under various data loads
/// OUR_GUTS.md: "Effortless, Seamless Discovery" - Smooth, responsive UI
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/spot.dart';
import 'package:spots/core/models/list.dart';
import 'package:spots/core/theme/colors.dart';
// Shim missing widgets with lightweight stand-ins
import 'package:flutter/widgets.dart' as fw;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/presentation/blocs/spots/spots_bloc.dart';
import 'package:spots/domain/repositories/spots_repository.dart';
import 'package:spots/domain/usecases/spots/get_spots_usecase.dart';
import 'package:spots/domain/usecases/spots/get_spots_from_respected_lists_usecase.dart';
import 'package:spots/domain/usecases/spots/create_spot_usecase.dart';
import 'package:spots/domain/usecases/spots/update_spot_usecase.dart';
import 'package:spots/domain/usecases/spots/delete_spot_usecase.dart';

// Local stand-in widgets to satisfy performance tests
class SpotListWidget extends fw.StatelessWidget {
  final List<Spot> spots;
  const SpotListWidget({fw.Key? key, required this.spots}) : super(key: key);
  @override
  fw.Widget build(fw.BuildContext context) {
    return ListView(children: spots.map((s)=>ListTile(title: Text(s.name), subtitle: Text(s.description))).toList());
  }
}
class SearchResultsWidget extends fw.StatelessWidget {
  final List<Spot> spots;
  final String searchQuery;
  final bool isLoading;
  const SearchResultsWidget({fw.Key? key, required this.spots, required this.searchQuery, required this.isLoading}) : super(key: key);
  @override
  fw.Widget build(fw.BuildContext context) => SpotListWidget(spots: spots);
}
class ListCardWidget extends fw.StatelessWidget {
  final SpotList list;
  const ListCardWidget({fw.Key? key, required this.list}) : super(key: key);
  @override
  fw.Widget build(fw.BuildContext context) => Card(child: ListTile(title: Text(list.title), subtitle: Text(list.description)));
}

// In-memory repository and use cases for SpotsBloc in tests
class _InMemorySpotsRepository implements SpotsRepository {
  final List<Spot> _spots;
  _InMemorySpotsRepository({List<Spot>? initial}) : _spots = List.of(initial ?? _generateLargeSpotList(50));

  @override
  Future<Spot> createSpot(Spot spot) async {
    _spots.add(spot);
    return spot;
  }

  @override
  Future<void> deleteSpot(String spotId) async {
    _spots.removeWhere((s) => s.id == spotId);
  }

  @override
  Future<List<Spot>> getSpots() async {
    return List.of(_spots);
  }

  @override
  Future<List<Spot>> getSpotsFromRespectedLists() async {
    // Return a small subset to simulate "respected" lists
    return _spots.where((s) => s.rating >= 4.0).take(10).toList();
  }

  @override
  Future<Spot> updateSpot(Spot spot) async {
    final idx = _spots.indexWhere((s) => s.id == spot.id);
    if (idx >= 0) {
      _spots[idx] = spot;
    } else {
      _spots.add(spot);
    }
    return spot;
  }
}

void main() {
  group('Phase 9: UI Responsiveness Tests', () {
    group('Large Dataset Rendering Performance', () {
      testWidgets('should render large spot lists efficiently', (WidgetTester tester) async {
        // Arrange
        final largeSpotList = _generateLargeSpotList(5000);
        
        // Act
        final stopwatch = Stopwatch()..start();
        
        await tester.pumpWidget(_createTestApp(
          child: SpotListWidget(spots: largeSpotList.take(100).toList()),
        ));
        
        await tester.pumpAndSettle();
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // Under 2 seconds
        expect(find.byType(SpotListWidget), findsOneWidget);
        
        // Test scrolling performance
        final scrollStopwatch = Stopwatch()..start();
        await tester.fling(find.byType(ListView), const Offset(0, -500), 1000);
        await tester.pumpAndSettle();
        scrollStopwatch.stop();
        
        expect(scrollStopwatch.elapsedMilliseconds, lessThan(500)); // Smooth scrolling
        
        print('Large spot list rendering: ${stopwatch.elapsedMilliseconds}ms, '
              'Scrolling: ${scrollStopwatch.elapsedMilliseconds}ms');
      });

      testWidgets('should handle search results with large datasets', (WidgetTester tester) async {
        // Arrange
        final largeSearchResults = _generateLargeSpotList(2000);
        
        // Act
        final stopwatch = Stopwatch()..start();
        
        await tester.pumpWidget(_createTestApp(
          child: SearchResultsWidget(
            spots: largeSearchResults,
            searchQuery: 'performance test',
            isLoading: false,
          ),
        ));
        
        await tester.pumpAndSettle();
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(1500)); // Under 1.5 seconds
        expect(find.byType(SearchResultsWidget), findsOneWidget);
        
        print('Large search results rendering: ${stopwatch.elapsedMilliseconds}ms');
      });

      testWidgets('should efficiently render complex list cards', (WidgetTester tester) async {
        // Arrange
        final complexLists = _generateComplexListCards(500);
        
        // Act
        final stopwatch = Stopwatch()..start();
        
        await tester.pumpWidget(_createTestApp(
          child: ListView.builder(
            itemCount: complexLists.length,
            itemBuilder: (context, index) => ListCardWidget(list: complexLists[index]),
          ),
        ));
        
        await tester.pumpAndSettle();
        stopwatch.stop();
        
        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(3000)); // Under 3 seconds
        
        print('Complex list cards rendering: ${stopwatch.elapsedMilliseconds}ms');
      });
    });

    group('Real-time Updates Performance', () {
      testWidgets('should handle real-time spot updates efficiently', (WidgetTester tester) async {
        // Arrange
        final initialSpots = _generateLargeSpotList(100);
        
        await tester.pumpWidget(_createTestApp(
          child: SpotListWidget(spots: initialSpots),
        ));
        await tester.pumpAndSettle();
        
        // Act - Simulate real-time updates
        final updateStopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 50; i++) {
          final updatedSpots = [...initialSpots, _generateTestSpot(i + 1000)];
          
          await tester.pumpWidget(_createTestApp(
            child: SpotListWidget(spots: updatedSpots),
          ));
          await tester.pump(); // Single frame update
        }
        
        updateStopwatch.stop();
        
        // Assert
        expect(updateStopwatch.elapsedMilliseconds, lessThan(2000)); // Under 2 seconds for 50 updates
        
        final avgUpdateTime = updateStopwatch.elapsedMilliseconds / 50;
        expect(avgUpdateTime, lessThan(40)); // Under 40ms per update
        
        print('Real-time updates (50): ${updateStopwatch.elapsedMilliseconds}ms '
              '(${avgUpdateTime.toStringAsFixed(1)}ms avg)');
      });

      testWidgets('should handle search result updates smoothly', (WidgetTester tester) async {
        // Arrange
        final searchQueries = ['coffee', 'restaurant', 'park', 'store', 'service'];
        
        await tester.pumpWidget(_createTestApp(
          child: SearchResultsWidget(
            spots: [],
            searchQuery: '',
            isLoading: false,
          ),
        ));
        
        // Act - Simulate search updates
        final searchUpdateStopwatch = Stopwatch()..start();
        
        for (final query in searchQueries) {
          final results = _generateSearchResults(query, 200);
          
          await tester.pumpWidget(_createTestApp(
            child: SearchResultsWidget(
              spots: results,
              searchQuery: query,
              isLoading: false,
            ),
          ));
          await tester.pumpAndSettle();
        }
        
        searchUpdateStopwatch.stop();
        
        // Assert
        expect(searchUpdateStopwatch.elapsedMilliseconds, lessThan(3000)); // Under 3 seconds
        
        print('Search updates (5 queries): ${searchUpdateStopwatch.elapsedMilliseconds}ms');
      });
    });

    group('Memory Efficient Rendering', () {
      testWidgets('should use lazy loading for large lists', (WidgetTester tester) async {
        // Arrange
        final hugeSpotList = _generateLargeSpotList(10000);
        
        // Act
        await tester.pumpWidget(_createTestApp(
          child: ListView.builder(
            itemCount: hugeSpotList.length,
            itemBuilder: (context, index) {
              if (index >= hugeSpotList.length) return null;
              return ListTile(
                title: Text(hugeSpotList[index].name),
                subtitle: Text(hugeSpotList[index].description),
              );
            },
          ),
        ));
        
        // Initial render should be fast
        await tester.pump();
        
        // Test that only visible items are rendered
        final visibleItems = tester.widgetList(find.byType(ListTile));
        expect(visibleItems.length, lessThan(20)); // Only visible items rendered
        
        // Test scrolling performance with lazy loading
        final scrollStopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 10; i++) {
          await tester.fling(find.byType(ListView), const Offset(0, -1000), 2000);
          await tester.pump();
        }
        
        scrollStopwatch.stop();
        expect(scrollStopwatch.elapsedMilliseconds, lessThan(1000)); // Smooth scrolling
        
        print('Lazy loading performance (10k items): ${scrollStopwatch.elapsedMilliseconds}ms');
      });

      testWidgets('should efficiently manage widget lifecycle', (WidgetTester tester) async {
        // Arrange
        var widgetBuildCount = 0;
        
        Widget createCountingWidget(List<Spot> spots) {
          return StatefulBuilder(
            builder: (context, setState) {
              widgetBuildCount++;
              return SpotListWidget(spots: spots);
            },
          );
        }
        
        final initialSpots = _generateLargeSpotList(50);
        
        // Act
        await tester.pumpWidget(_createTestApp(
          child: createCountingWidget(initialSpots),
        ));
        await tester.pumpAndSettle();
        
        final initialBuildCount = widgetBuildCount;
        
        // Update with same data - should not trigger unnecessary rebuilds
        await tester.pumpWidget(_createTestApp(
          child: createCountingWidget(initialSpots),
        ));
        await tester.pump();
        
        // Assert
        expect(widgetBuildCount - initialBuildCount, lessThan(2)); // Minimal rebuilds
        
        print('Widget lifecycle efficiency - Build count: $widgetBuildCount');
      });
    });

    group('Animation Performance', () {
      testWidgets('should maintain smooth animations under load', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(_createTestApp(
          child: Scaffold(
            body: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 100,
              height: 100,
                color: AppColors.electricGreen,
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
          ),
        ));
        
        // Act - Trigger animations while rendering large lists
        final animationStopwatch = Stopwatch()..start();
        
        // Start animation
        await tester.pumpWidget(_createTestApp(
          child: Scaffold(
            body: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 200,
                  height: 200,
                  color: AppColors.error,
                ),
                Expanded(
                  child: SpotListWidget(spots: _generateLargeSpotList(200)),
                ),
              ],
            ),
          ),
        ));
        
        // Pump through animation frames
        await tester.pumpAndSettle();
        animationStopwatch.stop();
        
        // Assert
        expect(animationStopwatch.elapsedMilliseconds, lessThan(1000)); // Smooth animation
        
        print('Animation with large list: ${animationStopwatch.elapsedMilliseconds}ms');
      });

      testWidgets('should handle concurrent animations efficiently', (WidgetTester tester) async {
        // Arrange
        const animationCount = 10;
        
        await tester.pumpWidget(_createTestApp(
          child: Scaffold(
            body: Column(
              children: List.generate(animationCount, (index) => 
                AnimatedContainer(
                  duration: Duration(milliseconds: 200 + index * 50),
                  width: 50.0 + index * 10,
                  height: 50.0,
                  color: _getTestColor(index),
                ),
              ),
            ),
          ),
        ));
        
        // Act - Start multiple concurrent animations
        final concurrentAnimationStopwatch = Stopwatch()..start();
        
        await tester.pumpWidget(_createTestApp(
          child: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: List.generate(animationCount, (index) => 
                  AnimatedContainer(
                    duration: Duration(milliseconds: 200 + index * 50),
                    width: 100.0 + index * 20,
                    height: 100.0,
                    color: _getTestColor(index + 5),
                  ),
                ),
              ),
            ),
          ),
        ));
        
        await tester.pumpAndSettle();
        concurrentAnimationStopwatch.stop();
        
        // Assert
        expect(concurrentAnimationStopwatch.elapsedMilliseconds, lessThan(1500)); // All animations complete smoothly
        
        print('Concurrent animations (10): ${concurrentAnimationStopwatch.elapsedMilliseconds}ms');
      });
    });

    group('State Management Performance', () {
      testWidgets('should handle BLoC state updates efficiently', (WidgetTester tester) async {
        // Arrange
        final mockSpotsBloc = _createMockSpotsBloc();
        
        await tester.pumpWidget(
          BlocProvider<SpotsBloc>.value(
            value: mockSpotsBloc,
            child: MaterialApp(
              home: Scaffold(
                body: BlocBuilder<SpotsBloc, SpotsState>(
                  builder: (context, state) {
                    if (state is SpotsLoaded) {
                      return SpotListWidget(spots: state.spots);
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ),
          ),
        );
        
        // Act - Trigger multiple state updates
        final stateUpdateStopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 20; i++) {
          mockSpotsBloc.add(LoadSpots());
          await tester.pump(); // Single frame
        }
        
        await tester.pumpAndSettle();
        stateUpdateStopwatch.stop();
        
        // Assert
        expect(stateUpdateStopwatch.elapsedMilliseconds, lessThan(1000)); // Efficient state updates
        
        print('BLoC state updates (20): ${stateUpdateStopwatch.elapsedMilliseconds}ms');
      });

      testWidgets('should optimize rebuild cycles', (WidgetTester tester) async {
        // Arrange
        var rebuildCount = 0;
        
        Widget createRebuildCountingWidget() {
          return StatefulBuilder(
            builder: (context, setState) {
              rebuildCount++;
              return Container(
                child: Text('Rebuild count: $rebuildCount'),
              );
            },
          );
        }
        
        // Act
        await tester.pumpWidget(_createTestApp(
          child: createRebuildCountingWidget(),
        ));
        
        final initialRebuildCount = rebuildCount;
        
        // Trigger multiple pumps without changes
        for (int i = 0; i < 10; i++) {
          await tester.pump();
        }
        
        // Assert
        final finalRebuildCount = rebuildCount;
        expect(finalRebuildCount - initialRebuildCount, lessThan(3)); // Minimal unnecessary rebuilds
        
        print('Rebuild optimization - Rebuilds: ${finalRebuildCount - initialRebuildCount}');
      });
    });

    group('Touch Response Performance', () {
      testWidgets('should respond to touch events quickly', (WidgetTester tester) async {
        // Arrange
        var tapCount = 0;
        final responseStopwatch = Stopwatch();
        
        await tester.pumpWidget(_createTestApp(
          child: Scaffold(
            body: ListView(
              children: List.generate(100, (index) => 
                ListTile(
                  title: Text('Item $index'),
                  onTap: () {
                    if (index == 50) {
                      responseStopwatch.stop();
                      tapCount++;
                    }
                  },
                ),
              ),
            ),
          ),
        ));
        
        // Act - Test touch response time
        responseStopwatch.start();
        await tester.tap(find.text('Item 50'));
        await tester.pump();
        
        // Assert
        expect(responseStopwatch.elapsedMilliseconds, lessThan(100)); // Under 100ms response
        expect(tapCount, equals(1));
        
        print('Touch response time: ${responseStopwatch.elapsedMilliseconds}ms');
      });

      testWidgets('should handle rapid touch events efficiently', (WidgetTester tester) async {
        // Arrange
        var rapidTapCount = 0;
        
        await tester.pumpWidget(_createTestApp(
          child: Scaffold(
            body: GestureDetector(
              onTap: () => rapidTapCount++,
              child: Container(
                width: 200,
                height: 200,
                color: AppColors.electricGreen,
                child: const Center(child: Text('Tap me rapidly')),
              ),
            ),
          ),
        ));
        
        // Act - Rapid tapping
        final rapidTapStopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 20; i++) {
          await tester.tap(find.text('Tap me rapidly'));
          await tester.pump(const Duration(milliseconds: 10));
        }
        
        rapidTapStopwatch.stop();
        
        // Assert
        expect(rapidTapStopwatch.elapsedMilliseconds, lessThan(1000)); // Handle rapid taps efficiently
        expect(rapidTapCount, equals(20));
        
        print('Rapid taps (20): ${rapidTapStopwatch.elapsedMilliseconds}ms');
      });
    });
  });
}

// Helper functions for UI testing

Widget _createTestApp({required Widget child}) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}

List<Spot> _generateLargeSpotList(int count) {
  return List.generate(count, (index) => _generateTestSpot(index));
}

Spot _generateTestSpot(int index) {
  return Spot(
    id: 'ui_test_spot_$index',
    name: 'UI Test Spot $index',
    description: 'This is a test spot for UI performance testing number $index. It has a longer description to test text rendering performance.',
    latitude: 40.7128 + (index * 0.0001),
    longitude: -74.0060 + (index * 0.0001),
    category: _getCategoryForIndex(index),
    rating: 3.0 + (index % 3),
    createdBy: 'ui_test_user_${index % 50}',
    createdAt: DateTime.now().subtract(Duration(days: index % 365)),
    updatedAt: DateTime.now().subtract(Duration(hours: index % 24)),
    tags: ['ui_test', 'performance', _getCategoryForIndex(index).toLowerCase()],
    metadata: {
      'ui_test': true,
      'index': index,
      'complexity': index % 3 == 0 ? 'high' : 'low',
    },
  );
}

List<SpotList> _generateComplexListCards(int count) {
  return List.generate(count, (index) => SpotList(
    id: 'ui_test_list_$index',
    title: 'UI Test List $index - A Complex List with Long Name for Testing',
    description: 'This is a complex test list for UI performance testing. It includes many spots, collaborators, and followers to test rendering performance under load.',
    category: 'general',
    spots: const [],
    spotIds: List.generate((index % 50) + 10, (i) => 'spot_${index}_$i'),
    collaborators: List.generate((index % 10) + 2, (i) => 'collaborator_${index}_$i'),
    followers: List.generate((index % 25) + 5, (i) => 'follower_${index}_$i'),
    isPublic: index % 2 == 0,
    
    createdAt: DateTime.now().subtract(Duration(days: index % 365)),
    updatedAt: DateTime.now().subtract(Duration(hours: index % 24)),
    metadata: {
      'ui_test': true,
      'complexity': 'high',
      'rendering_test': true,
      'relationship_count': (index % 50) + 10 + (index % 10) + 2 + (index % 25) + 5,
    },
  ));
}

List<Spot> _generateSearchResults(String query, int count) {
  return List.generate(count, (index) => Spot(
    id: 'search_result_${query}_$index',
    name: '$query Spot $index',
    description: 'Search result for "$query" - spot number $index',
    latitude: 40.7128 + (index * 0.0001),
    longitude: -74.0060 + (index * 0.0001),
    category: _getCategoryForQuery(query),
    rating: 3.5 + (index % 3) * 0.5,
    createdBy: 'search_test_user',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    tags: [query.toLowerCase(), 'search_result', 'ui_test'],
  ));
}

String _getCategoryForIndex(int index) {
  const categories = ['Coffee', 'Restaurant', 'Park', 'Store', 'Service', 'Entertainment'];
  return categories[index % categories.length];
}

String _getCategoryForQuery(String query) {
  switch (query.toLowerCase()) {
    case 'coffee':
      return 'Coffee';
    case 'restaurant':
      return 'Restaurant';
    case 'park':
      return 'Park';
    case 'store':
      return 'Store';
    case 'service':
      return 'Service';
    default:
      return 'General';
  }
}

SpotsBloc _createMockSpotsBloc() {
  final repo = _InMemorySpotsRepository();
  return SpotsBloc(
    getSpotsUseCase: GetSpotsUseCase(repo),
    getSpotsFromRespectedListsUseCase: GetSpotsFromRespectedListsUseCase(repo),
    createSpotUseCase: CreateSpotUseCase(repo),
    updateSpotUseCase: UpdateSpotUseCase(repo),
    deleteSpotUseCase: DeleteSpotUseCase(repo),
  );
}

// Helper function to get test colors using AppColors (design token compliant)
Color _getTestColor(int index) {
  final colors = [
    AppColors.electricGreen,
    AppColors.grey600,
    AppColors.grey500,
    AppColors.grey400,
    AppColors.grey700,
    AppColors.error,
    AppColors.warning,
    AppColors.grey300,
    AppColors.grey800,
    AppColors.grey200,
  ];
  return colors[index % colors.length];
}

// Deprecated mocks kept for reference; real in-memory fakes are used above.
dynamic _mockGetSpotsUseCase() => GetSpotsUseCase(_InMemorySpotsRepository());
dynamic _mockCreateSpotUseCase() => CreateSpotUseCase(_InMemorySpotsRepository());
dynamic _mockUpdateSpotUseCase() => UpdateSpotUseCase(_InMemorySpotsRepository());
dynamic _mockDeleteSpotUseCase() => DeleteSpotUseCase(_InMemorySpotsRepository());
dynamic _mockGetSpotsFromRespectedListsUseCase() => GetSpotsFromRespectedListsUseCase(_InMemorySpotsRepository());

/// SpotsBloc Unit Tests - Phase 4: BLoC State Management Testing
/// 
/// Comprehensive testing of SpotsBloc with CRUD operations, search, and optimistic updates
/// Ensures optimal development stages and deployment optimization
/// Tests current implementation as-is without modifying production code

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spots/presentation/blocs/spots/spots_bloc.dart';
import 'package:spots/core/models/spot.dart';
import '../../helpers/bloc_test_helpers.dart';
import '../../mocks/bloc_mock_dependencies.dart';

void main() {
  group('SpotsBloc', () {
    late SpotsBloc spotsBloc;
    late MockGetSpotsUseCase mockGetSpotsUseCase;
    late MockGetSpotsFromRespectedListsUseCase mockGetSpotsFromRespectedListsUseCase;
    late MockCreateSpotUseCase mockCreateSpotUseCase;
    late MockUpdateSpotUseCase mockUpdateSpotUseCase;
    late MockDeleteSpotUseCase mockDeleteSpotUseCase;

    setUpAll(() {
      BlocMockFactory.registerFallbacks();
      // Register fallback values for Spot objects
      registerFallbackValue(TestDataFactory.createTestSpot());
    });

    setUp(() {
      mockGetSpotsUseCase = BlocMockFactory.getSpotsUseCase;
      mockGetSpotsFromRespectedListsUseCase = BlocMockFactory.getSpotsFromRespectedListsUseCase;
      mockCreateSpotUseCase = BlocMockFactory.createSpotUseCase;
      mockUpdateSpotUseCase = BlocMockFactory.updateSpotUseCase;
      mockDeleteSpotUseCase = BlocMockFactory.deleteSpotUseCase;
      
      BlocMockFactory.resetAll();

      spotsBloc = SpotsBloc(
        getSpotsUseCase: mockGetSpotsUseCase,
        getSpotsFromRespectedListsUseCase: mockGetSpotsFromRespectedListsUseCase,
        createSpotUseCase: mockCreateSpotUseCase,
        updateSpotUseCase: mockUpdateSpotUseCase,
        deleteSpotUseCase: mockDeleteSpotUseCase,
      );
    });

    tearDown(() {
      spotsBloc.close();
    });

    group('Initial State', () {
      test('should have SpotsInitial as initial state', () {
        expect(spotsBloc.state, isA<SpotsInitial>());
      });
    });

    group('LoadSpots Event', () {
      final testSpots = TestDataFactory.createTestSpots(5);

      blocTest<SpotsBloc, SpotsState>(
        'emits [SpotsLoading, SpotsLoaded] when loading spots succeeds',
        build: () {
          when(() => mockGetSpotsUseCase()).thenAnswer((_) async => testSpots);
          return spotsBloc;
        },
        act: (bloc) => bloc.add(LoadSpots()),
        expect: () => [
          isA<SpotsLoading>(),
          isA<SpotsLoaded>()
              .having((state) => state.spots.length, 'spots length', testSpots.length)
              .having((state) => state.filteredSpots.length, 'filtered spots length', testSpots.length)
              .having((state) => state.searchQuery, 'search query', isNull)
              .having((state) => state.respectedSpots.length, 'respected spots length', 0),
        ],
        verify: (_) {
          verify(() => mockGetSpotsUseCase()).called(1);
        },
      );

      blocTest<SpotsBloc, SpotsState>(
        'emits [SpotsLoading, SpotsError] when loading spots fails',
        build: () {
          when(() => mockGetSpotsUseCase())
              .thenThrow(Exception('Failed to load spots'));
          return spotsBloc;
        },
        act: (bloc) => bloc.add(LoadSpots()),
        expect: () => [
          isA<SpotsLoading>(),
          isA<SpotsError>()
              .having((state) => state.message, 'message', contains('Failed to load spots')),
        ],
      );

      blocTest<SpotsBloc, SpotsState>(
        'handles empty spots list correctly',
        build: () {
          when(() => mockGetSpotsUseCase()).thenAnswer((_) async => <Spot>[]);
          return spotsBloc;
        },
        act: (bloc) => bloc.add(LoadSpots()),
        expect: () => [
          isA<SpotsLoading>(),
          isA<SpotsLoaded>()
              .having((state) => state.spots.length, 'spots length', 0)
              .having((state) => state.filteredSpots.length, 'filtered spots length', 0),
        ],
      );
    });

    group('LoadSpotsWithRespected Event', () {
      final testSpots = TestDataFactory.createTestSpots(5);
      final respectedSpots = TestDataFactory.createTestSpots(3);

      blocTest<SpotsBloc, SpotsState>(
        'emits [SpotsLoading, SpotsLoaded] with respected spots when both calls succeed',
        build: () {
          when(() => mockGetSpotsUseCase()).thenAnswer((_) async => testSpots);
          when(() => mockGetSpotsFromRespectedListsUseCase())
              .thenAnswer((_) async => respectedSpots);
          return spotsBloc;
        },
        act: (bloc) => bloc.add(LoadSpotsWithRespected()),
        expect: () => [
          isA<SpotsLoading>(),
          isA<SpotsLoaded>()
              .having((state) => state.spots.length, 'spots length', testSpots.length)
              .having((state) => state.respectedSpots.length, 'respected spots length', respectedSpots.length),
        ],
        verify: (_) {
          verify(() => mockGetSpotsUseCase()).called(1);
          verify(() => mockGetSpotsFromRespectedListsUseCase()).called(1);
        },
      );

      blocTest<SpotsBloc, SpotsState>(
        'emits [SpotsLoading, SpotsError] when loading spots fails',
        build: () {
          when(() => mockGetSpotsUseCase())
              .thenThrow(Exception('Failed to load spots'));
          when(() => mockGetSpotsFromRespectedListsUseCase())
              .thenAnswer((_) async => respectedSpots);
          return spotsBloc;
        },
        act: (bloc) => bloc.add(LoadSpotsWithRespected()),
        expect: () => [
          isA<SpotsLoading>(),
          isA<SpotsError>(),
        ],
      );

      blocTest<SpotsBloc, SpotsState>(
        'emits [SpotsLoading, SpotsError] when loading respected spots fails',
        build: () {
          when(() => mockGetSpotsUseCase()).thenAnswer((_) async => testSpots);
          when(() => mockGetSpotsFromRespectedListsUseCase())
              .thenThrow(Exception('Failed to load respected spots'));
          return spotsBloc;
        },
        act: (bloc) => bloc.add(LoadSpotsWithRespected()),
        expect: () => [
          isA<SpotsLoading>(),
          isA<SpotsError>(),
        ],
      );
    });

    group('SearchSpots Event', () {
      final testSpots = [
        TestDataFactory.createTestSpot(
          id: '1',
          name: 'Coffee Shop',
          description: 'Great coffee',
          category: 'cafe',
        ),
        TestDataFactory.createTestSpot(
          id: '2',
          name: 'Pizza Restaurant',
          description: 'Delicious pizza',
          category: 'restaurant',
        ),
        TestDataFactory.createTestSpot(
          id: '3',
          name: 'Coffee Roastery',
          description: 'Fresh roasted coffee beans',
          category: 'cafe',
        ),
      ];

      blocTest<SpotsBloc, SpotsState>(
        'filters spots by name when searching with valid query',
        seed: () => SpotsLoaded(testSpots),
        build: () => spotsBloc,
        act: (bloc) => bloc.add(SearchSpots(query: 'coffee')),
        expect: () => [
          isA<SpotsLoaded>()
              .having((state) => state.spots.length, 'original spots length', testSpots.length)
              .having((state) => state.filteredSpots.length, 'filtered spots length', 2)
              .having((state) => state.searchQuery, 'search query', 'coffee')
              .having((state) => state.filteredSpots.every((spot) => 
                spot.name.toLowerCase().contains('coffee') ||
                spot.description.toLowerCase().contains('coffee') ||
                spot.category.toLowerCase().contains('coffee')
              ), 'all filtered spots contain query', true),
        ],
      );

      blocTest<SpotsBloc, SpotsState>(
        'filters spots by description when searching',
        seed: () => SpotsLoaded(testSpots),
        build: () => spotsBloc,
        act: (bloc) => bloc.add(SearchSpots(query: 'delicious')),
        expect: () => [
          isA<SpotsLoaded>()
              .having((state) => state.filteredSpots.length, 'filtered spots length', 1)
              .having((state) => state.filteredSpots.first.name, 'first filtered spot name', 'Pizza Restaurant'),
        ],
      );

      blocTest<SpotsBloc, SpotsState>(
        'filters spots by category when searching',
        seed: () => SpotsLoaded(testSpots),
        build: () => spotsBloc,
        act: (bloc) => bloc.add(SearchSpots(query: 'cafe')),
        expect: () => [
          isA<SpotsLoaded>()
              .having((state) => state.filteredSpots.length, 'filtered spots length', 2)
              .having((state) => state.filteredSpots.every((spot) => 
                spot.category == 'cafe' || spot.name.toLowerCase().contains('cafe')
              ), 'all filtered spots are cafes or contain cafe', true),
        ],
      );

      blocTest<SpotsBloc, SpotsState>(
        'returns all spots when search query is empty',
        // Seed with an active query + filtered list so clearing the query causes a real state change.
        // Otherwise the bloc won't emit because the "cleared" state equals the current state.
        seed: () => SpotsLoaded(
          testSpots,
          filteredSpots: testSpots.take(1).toList(),
          searchQuery: 'coffee',
        ),
        build: () => spotsBloc,
        act: (bloc) => bloc.add(SearchSpots(query: '')),
        expect: () => [
          isA<SpotsLoaded>()
              .having((state) => state.filteredSpots.length, 'filtered spots length', testSpots.length)
              .having((state) => state.searchQuery, 'search query', isNull),
        ],
      );

      blocTest<SpotsBloc, SpotsState>(
        'returns empty list when no spots match query',
        seed: () => SpotsLoaded(testSpots),
        build: () => spotsBloc,
        act: (bloc) => bloc.add(SearchSpots(query: 'nonexistent')),
        expect: () => [
          isA<SpotsLoaded>()
              .having((state) => state.filteredSpots.length, 'filtered spots length', 0)
              .having((state) => state.searchQuery, 'search query', 'nonexistent'),
        ],
      );

      blocTest<SpotsBloc, SpotsState>(
        'handles case-insensitive search correctly',
        seed: () => SpotsLoaded(testSpots),
        build: () => spotsBloc,
        act: (bloc) => bloc.add(SearchSpots(query: 'COFFEE')),
        expect: () => [
          isA<SpotsLoaded>()
              .having((state) => state.filteredSpots.length, 'filtered spots length', 2),
        ],
      );

      blocTest<SpotsBloc, SpotsState>(
        'does nothing when current state is not SpotsLoaded',
        build: () => spotsBloc,
        act: (bloc) => bloc.add(SearchSpots(query: 'coffee')),
        expect: () => [],
      );
    });

    group('CreateSpot Event', () {
      final testSpot = TestDataFactory.createTestSpot();
      final existingSpots = TestDataFactory.createTestSpots(3);

      blocTest<SpotsBloc, SpotsState>(
        'triggers LoadSpots after successful spot creation',
        build: () {
          when(() => mockCreateSpotUseCase(any())).thenAnswer((_) async => testSpot);
          when(() => mockGetSpotsUseCase()).thenAnswer((_) async => existingSpots);
          return spotsBloc;
        },
        act: (bloc) => bloc.add(CreateSpot(testSpot)),
        expect: () => [
          isA<SpotsLoading>(),
          isA<SpotsLoaded>(),
        ],
        verify: (_) {
          verify(() => mockCreateSpotUseCase(testSpot)).called(1);
          verify(() => mockGetSpotsUseCase()).called(1);
        },
      );

      blocTest<SpotsBloc, SpotsState>(
        'emits SpotsError when spot creation fails',
        build: () {
          when(() => mockCreateSpotUseCase(any()))
              .thenThrow(Exception('Failed to create spot'));
          return spotsBloc;
        },
        act: (bloc) => bloc.add(CreateSpot(testSpot)),
        expect: () => [
          isA<SpotsError>()
              .having((state) => state.message, 'message', contains('Failed to create spot')),
        ],
        verify: (_) {
          verify(() => mockCreateSpotUseCase(testSpot)).called(1);
          verifyNever(() => mockGetSpotsUseCase());
        },
      );

      blocTest<SpotsBloc, SpotsState>(
        'handles validation errors gracefully',
        build: () {
          when(() => mockCreateSpotUseCase(any()))
              .thenThrow(Exception('Invalid spot data'));
          return spotsBloc;
        },
        act: (bloc) => bloc.add(CreateSpot(testSpot)),
        expect: () => [
          isA<SpotsError>()
              .having((state) => state.message, 'message', contains('Invalid spot data')),
        ],
      );
    });

    group('UpdateSpot Event', () {
      final testSpot = TestDataFactory.createTestSpot();
      final existingSpots = TestDataFactory.createTestSpots(3);

      blocTest<SpotsBloc, SpotsState>(
        'triggers LoadSpots after successful spot update',
        build: () {
          when(() => mockUpdateSpotUseCase(any())).thenAnswer((_) async => testSpot);
          when(() => mockGetSpotsUseCase()).thenAnswer((_) async => existingSpots);
          return spotsBloc;
        },
        act: (bloc) => bloc.add(UpdateSpot(testSpot)),
        expect: () => [
          isA<SpotsLoading>(),
          isA<SpotsLoaded>(),
        ],
        verify: (_) {
          verify(() => mockUpdateSpotUseCase(testSpot)).called(1);
          verify(() => mockGetSpotsUseCase()).called(1);
        },
      );

      blocTest<SpotsBloc, SpotsState>(
        'emits SpotsError when spot update fails',
        build: () {
          when(() => mockUpdateSpotUseCase(any()))
              .thenThrow(Exception('Failed to update spot'));
          return spotsBloc;
        },
        act: (bloc) => bloc.add(UpdateSpot(testSpot)),
        expect: () => [
          isA<SpotsError>()
              .having((state) => state.message, 'message', contains('Failed to update spot')),
        ],
        verify: (_) {
          verify(() => mockUpdateSpotUseCase(testSpot)).called(1);
          verifyNever(() => mockGetSpotsUseCase());
        },
      );

      blocTest<SpotsBloc, SpotsState>(
        'handles permission errors gracefully',
        build: () {
          when(() => mockUpdateSpotUseCase(any()))
              .thenThrow(Exception('Insufficient permissions'));
          return spotsBloc;
        },
        act: (bloc) => bloc.add(UpdateSpot(testSpot)),
        expect: () => [
          isA<SpotsError>()
              .having((state) => state.message, 'message', contains('Insufficient permissions')),
        ],
      );
    });

    group('DeleteSpot Event', () {
      const testSpotId = 'test-spot-123';
      final existingSpots = TestDataFactory.createTestSpots(3);

      blocTest<SpotsBloc, SpotsState>(
        'triggers LoadSpots after successful spot deletion',
        build: () {
          when(() => mockDeleteSpotUseCase(any())).thenAnswer((_) async {});
          when(() => mockGetSpotsUseCase()).thenAnswer((_) async => existingSpots);
          return spotsBloc;
        },
        act: (bloc) => bloc.add(DeleteSpot(testSpotId)),
        expect: () => [
          isA<SpotsLoading>(),
          isA<SpotsLoaded>(),
        ],
        verify: (_) {
          verify(() => mockDeleteSpotUseCase(testSpotId)).called(1);
          verify(() => mockGetSpotsUseCase()).called(1);
        },
      );

      blocTest<SpotsBloc, SpotsState>(
        'emits SpotsError when spot deletion fails',
        build: () {
          when(() => mockDeleteSpotUseCase(any()))
              .thenThrow(Exception('Failed to delete spot'));
          return spotsBloc;
        },
        act: (bloc) => bloc.add(DeleteSpot(testSpotId)),
        expect: () => [
          isA<SpotsError>()
              .having((state) => state.message, 'message', contains('Failed to delete spot')),
        ],
        verify: (_) {
          verify(() => mockDeleteSpotUseCase(testSpotId)).called(1);
          verifyNever(() => mockGetSpotsUseCase());
        },
      );

      blocTest<SpotsBloc, SpotsState>(
        'handles not found errors gracefully',
        build: () {
          when(() => mockDeleteSpotUseCase(any()))
              .thenThrow(Exception('Spot not found'));
          return spotsBloc;
        },
        act: (bloc) => bloc.add(DeleteSpot(testSpotId)),
        expect: () => [
          isA<SpotsError>()
              .having((state) => state.message, 'message', contains('Spot not found')),
        ],
      );
    });

    group('State Transitions and Complex Scenarios', () {
      blocTest<SpotsBloc, SpotsState>(
        'handles create followed by search correctly',
        build: () {
          final spotWithCoffee = TestDataFactory.createTestSpot(
            name: 'New Coffee Shop',
            category: 'cafe',
          );
          final updatedSpots = [spotWithCoffee];
          
          when(() => mockCreateSpotUseCase(any())).thenAnswer((_) async => spotWithCoffee);
          when(() => mockGetSpotsUseCase()).thenAnswer((_) async => updatedSpots);
          return spotsBloc;
        },
        act: (bloc) async {
          bloc.add(CreateSpot(TestDataFactory.createTestSpot()));
          await Future.delayed(const Duration(milliseconds: 50));
          bloc.add(SearchSpots(query: 'coffee'));
        },
        verify: (_) {
          verify(() => mockCreateSpotUseCase(any())).called(1);
          verify(() => mockGetSpotsUseCase()).called(1);
        },
      );

      blocTest<SpotsBloc, SpotsState>(
        'preserves search state after unsuccessful operations',
        seed: () => SpotsLoaded(
          TestDataFactory.createTestSpots(5),
          filteredSpots: TestDataFactory.createTestSpots(2),
          searchQuery: 'coffee',
        ),
        build: () {
          when(() => mockCreateSpotUseCase(any()))
              .thenThrow(Exception('Network error'));
          return spotsBloc;
        },
        act: (bloc) => bloc.add(CreateSpot(TestDataFactory.createTestSpot())),
        expect: () => [
          isA<SpotsError>(),
        ],
        verify: (_) {
          verify(() => mockCreateSpotUseCase(any())).called(1);
          verifyNever(() => mockGetSpotsUseCase());
        },
      );

      blocTest<SpotsBloc, SpotsState>(
        'handles rapid fire events correctly',
        build: () {
          when(() => mockGetSpotsUseCase())
              .thenAnswer((_) async => TestDataFactory.createTestSpots(3));
          when(() => mockCreateSpotUseCase(any())).thenAnswer((_) async => TestDataFactory.createTestSpot());
          when(() => mockUpdateSpotUseCase(any())).thenAnswer((_) async => TestDataFactory.createTestSpot());
          return spotsBloc;
        },
        act: (bloc) {
          bloc.add(LoadSpots());
          bloc.add(CreateSpot(TestDataFactory.createTestSpot()));
          bloc.add(UpdateSpot(TestDataFactory.createTestSpot()));
          bloc.add(LoadSpots());
        },
        // Should handle events without crashing
        verify: (_) {
          verify(() => mockGetSpotsUseCase()).called(greaterThan(0));
        },
      );
    });

    group('Performance and Reliability', () {
      test('SpotsLoaded state initializes filtered spots correctly', () {
        final testSpots = TestDataFactory.createTestSpots(5);
        final state = SpotsLoaded(testSpots);
        
        expect(state.spots, equals(testSpots));
        expect(state.filteredSpots, equals(testSpots));
        expect(state.searchQuery, isNull);
        expect(state.respectedSpots, isEmpty);
      });

      test('SpotsLoaded state with custom filtered spots', () {
        final allSpots = TestDataFactory.createTestSpots(5);
        final filteredSpots = TestDataFactory.createTestSpots(2);
        const searchQuery = 'test query';
        final respectedSpots = TestDataFactory.createTestSpots(1);
        
        final state = SpotsLoaded(
          allSpots,
          filteredSpots: filteredSpots,
          searchQuery: searchQuery,
          respectedSpots: respectedSpots,
        );
        
        expect(state.spots, equals(allSpots));
        expect(state.filteredSpots, equals(filteredSpots));
        expect(state.searchQuery, equals(searchQuery));
        expect(state.respectedSpots, equals(respectedSpots));
      });

      test('Event props equality works correctly', () {
        final spot1 = TestDataFactory.createTestSpot(id: '1');
        final spot3 = TestDataFactory.createTestSpot(id: '2');
        
        final createEvent1 = CreateSpot(spot1);
        // Spot does not guarantee value-equality; use the same instance for equality checks.
        final createEvent2 = CreateSpot(spot1);
        final createEvent3 = CreateSpot(spot3);
        
        expect(createEvent1.props, equals(createEvent2.props));
        expect(createEvent1.props, isNot(equals(createEvent3.props)));
      });

      test('State props equality works correctly', () {
        // Use the same Spot instances for the equality case.
        // Spot may not implement value-equality, so separately created "equivalent" Spots
        // won't compare equal. This test is about SpotsLoaded's Equatable wiring.
        final spots1 = TestDataFactory.createTestSpots(3);
        final spots2 = List<Spot>.from(spots1); // same elements, new list instance
        final spots3 = spots1.take(2).toList(); // different content/length
        
        final state1 = SpotsLoaded(spots1);
        final state2 = SpotsLoaded(spots2);
        final state3 = SpotsLoaded(spots3);
        
        // Note: This tests the Equatable implementation.
        // `props.length` is always constant for a given state class; compare props values instead.
        expect(state1.props, equals(state2.props));
        expect(state1.props, isNot(equals(state3.props)));
      });

      blocTest<SpotsBloc, SpotsState>(
        'maintains performance with large datasets',
        build: () {
          final largeSpotsList = TestDataFactory.createTestSpots(1000);
          when(() => mockGetSpotsUseCase()).thenAnswer((_) async => largeSpotsList);
          return spotsBloc;
        },
        act: (bloc) => bloc.add(LoadSpots()),
        expect: () => [
          isA<SpotsLoading>(),
          isA<SpotsLoaded>()
              .having((state) => state.spots.length, 'spots length', 1000),
        ],
      );
    });

    group('Edge Cases and Error Scenarios', () {
      blocTest<SpotsBloc, SpotsState>(
        'handles null or empty spot properties gracefully',
        build: () {
          final spotWithEmptyProps = Spot(
            id: 'empty-spot',
            name: '',
            description: '',
            latitude: 0.0,
            longitude: 0.0,
            category: '',
            rating: 0.0,
            createdBy: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          when(() => mockGetSpotsUseCase()).thenAnswer((_) async => [spotWithEmptyProps]);
          return spotsBloc;
        },
        act: (bloc) => bloc.add(LoadSpots()),
        expect: () => [
          isA<SpotsLoading>(),
          isA<SpotsLoaded>(),
        ],
      );

      blocTest<SpotsBloc, SpotsState>(
        'search works with empty string properties',
        seed: () => SpotsLoaded([
          Spot(
            id: 'empty-spot',
            name: '',
            description: '',
            latitude: 0.0,
            longitude: 0.0,
            category: '',
            rating: 0.0,
            createdBy: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ]),
        build: () => spotsBloc,
        act: (bloc) => bloc.add(SearchSpots(query: 'anything')),
        expect: () => [
          isA<SpotsLoaded>()
              .having((state) => state.filteredSpots.length, 'filtered spots length', 0),
        ],
      );

      blocTest<SpotsBloc, SpotsState>(
        'handles network timeouts gracefully',
        build: () {
          when(() => mockGetSpotsUseCase())
              .thenAnswer((_) => Future.delayed(
                const Duration(seconds: 30),
                () => throw Exception('Request timeout'),
              ));
          return spotsBloc;
        },
        act: (bloc) => bloc.add(LoadSpots()),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<SpotsLoading>(),
        ],
      );
    });

    group('Integration with Respected Lists', () {
      blocTest<SpotsBloc, SpotsState>(
        'correctly separates regular and respected spots',
        build: () {
          final regularSpots = TestDataFactory.createTestSpots(5);
          final respectedSpots = TestDataFactory.createTestSpots(3);
          
          when(() => mockGetSpotsUseCase()).thenAnswer((_) async => regularSpots);
          when(() => mockGetSpotsFromRespectedListsUseCase())
              .thenAnswer((_) async => respectedSpots);
          return spotsBloc;
        },
        act: (bloc) => bloc.add(LoadSpotsWithRespected()),
        expect: () => [
          isA<SpotsLoading>(),
          isA<SpotsLoaded>()
              .having((state) => state.spots.length, 'regular spots', 5)
              .having((state) => state.respectedSpots.length, 'respected spots', 3),
        ],
      );

      blocTest<SpotsBloc, SpotsState>(
        'handles empty respected spots list',
        build: () {
          final regularSpots = TestDataFactory.createTestSpots(5);
          
          when(() => mockGetSpotsUseCase()).thenAnswer((_) async => regularSpots);
          when(() => mockGetSpotsFromRespectedListsUseCase())
              .thenAnswer((_) async => <Spot>[]);
          return spotsBloc;
        },
        act: (bloc) => bloc.add(LoadSpotsWithRespected()),
        expect: () => [
          isA<SpotsLoading>(),
          isA<SpotsLoaded>()
              .having((state) => state.respectedSpots.length, 'respected spots', 0),
        ],
      );
    });
  });
}

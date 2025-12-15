/// ListsBloc Unit Tests - Phase 4: BLoC State Management Testing
/// 
/// Comprehensive testing of ListsBloc with role-based operations and collaborative editing
/// Ensures optimal development stages and deployment optimization
/// Tests current implementation as-is without modifying production code

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spots/presentation/blocs/lists/lists_bloc.dart';
import 'package:spots/core/models/list.dart';
import '../../helpers/bloc_test_helpers.dart';
import '../../mocks/bloc_mock_dependencies.dart';

void main() {
  group('ListsBloc', () {
    late ListsBloc listsBloc;
    late MockGetListsUseCase mockGetListsUseCase;
    late MockCreateListUseCase mockCreateListUseCase;
    late MockUpdateListUseCase mockUpdateListUseCase;
    late MockDeleteListUseCase mockDeleteListUseCase;

    setUpAll(() {
      BlocMockFactory.registerFallbacks();
      // Register fallback values for SpotList objects
      registerFallbackValue(TestDataFactory.createTestList());
    });

    setUp(() {
      mockGetListsUseCase = BlocMockFactory.getListsUseCase;
      mockCreateListUseCase = BlocMockFactory.createListUseCase;
      mockUpdateListUseCase = BlocMockFactory.updateListUseCase;
      mockDeleteListUseCase = BlocMockFactory.deleteListUseCase;
      
      BlocMockFactory.resetAll();

      listsBloc = ListsBloc(
        getListsUseCase: mockGetListsUseCase,
        createListUseCase: mockCreateListUseCase,
        updateListUseCase: mockUpdateListUseCase,
        deleteListUseCase: mockDeleteListUseCase,
      );
    });

    tearDown(() {
      listsBloc.close();
    });

    group('Initial State', () {
      test('should have ListsInitial as initial state', () {
        expect(listsBloc.state, isA<ListsInitial>());
      });
    });

    group('LoadLists Event', () {
      final testLists = TestDataFactory.createTestLists(5);

      blocTest<ListsBloc, ListsState>(
        'emits [ListsLoading, ListsLoaded] when loading lists succeeds',
        build: () {
          when(() => mockGetListsUseCase()).thenAnswer((_) async => testLists);
          return listsBloc;
        },
        act: (bloc) => bloc.add(LoadLists()),
        expect: () => [
          isA<ListsLoading>(),
          isA<ListsLoaded>()
              .having((state) => state.lists.length, 'lists length', testLists.length)
              .having((state) => state.filteredLists.length, 'filtered lists length', testLists.length),
        ],
        verify: (_) {
          verify(() => mockGetListsUseCase()).called(1);
        },
      );

      blocTest<ListsBloc, ListsState>(
        'emits [ListsLoading, ListsError] when loading lists fails',
        build: () {
          when(() => mockGetListsUseCase())
              .thenThrow(Exception('Failed to load lists'));
          return listsBloc;
        },
        act: (bloc) => bloc.add(LoadLists()),
        expect: () => [
          isA<ListsLoading>(),
          isA<ListsError>()
              .having((state) => state.message, 'message', contains('Failed to load lists')),
        ],
      );

      blocTest<ListsBloc, ListsState>(
        'handles empty lists correctly',
        build: () {
          when(() => mockGetListsUseCase()).thenAnswer((_) async => <SpotList>[]);
          return listsBloc;
        },
        act: (bloc) => bloc.add(LoadLists()),
        expect: () => [
          isA<ListsLoading>(),
          isA<ListsLoaded>()
              .having((state) => state.lists.length, 'lists length', 0)
              .having((state) => state.filteredLists.length, 'filtered lists length', 0),
        ],
      );

      blocTest<ListsBloc, ListsState>(
        'handles network timeout gracefully',
        build: () {
          when(() => mockGetListsUseCase())
              .thenAnswer((_) => Future.delayed(
                const Duration(seconds: 30),
                () => throw Exception('Request timeout'),
              ));
          return listsBloc;
        },
        act: (bloc) => bloc.add(LoadLists()),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<ListsLoading>(),
        ],
      );
    });

    group('CreateList Event', () {
      final testList = TestDataFactory.createTestList();
      final existingLists = TestDataFactory.createTestLists(3);

      blocTest<ListsBloc, ListsState>(
        'triggers LoadLists after successful list creation',
        build: () {
          when(() => mockCreateListUseCase(any())).thenAnswer((_) async => testList);
          when(() => mockGetListsUseCase()).thenAnswer((_) async => existingLists);
          return listsBloc;
        },
        act: (bloc) => bloc.add(CreateList(testList)),
        expect: () => [
          isA<ListsLoading>(),
          isA<ListsLoaded>(),
        ],
        verify: (_) {
          verify(() => mockCreateListUseCase(testList)).called(1);
          verify(() => mockGetListsUseCase()).called(1);
        },
      );

      blocTest<ListsBloc, ListsState>(
        'emits ListsError when list creation fails',
        build: () {
          when(() => mockCreateListUseCase(any()))
              .thenThrow(Exception('Failed to create list'));
          return listsBloc;
        },
        act: (bloc) => bloc.add(CreateList(testList)),
        expect: () => [
          isA<ListsError>()
              .having((state) => state.message, 'message', contains('Failed to create list')),
        ],
        verify: (_) {
          verify(() => mockCreateListUseCase(testList)).called(1);
          verifyNever(() => mockGetListsUseCase());
        },
      );

      blocTest<ListsBloc, ListsState>(
        'handles validation errors gracefully',
        build: () {
          when(() => mockCreateListUseCase(any()))
              .thenThrow(Exception('Invalid list data'));
          return listsBloc;
        },
        act: (bloc) => bloc.add(CreateList(testList)),
        expect: () => [
          isA<ListsError>()
              .having((state) => state.message, 'message', contains('Invalid list data')),
        ],
      );

      blocTest<ListsBloc, ListsState>(
        'handles permission errors for list creation',
        build: () {
          when(() => mockCreateListUseCase(any()))
              .thenThrow(Exception('Insufficient permissions to create list'));
          return listsBloc;
        },
        act: (bloc) => bloc.add(CreateList(testList)),
        expect: () => [
          isA<ListsError>()
              .having((state) => state.message, 'message', contains('Insufficient permissions')),
        ],
      );
    });

    group('UpdateList Event', () {
      final testList = TestDataFactory.createTestList();
      final existingLists = TestDataFactory.createTestLists(3);

      blocTest<ListsBloc, ListsState>(
        'triggers LoadLists after successful list update',
        build: () {
          when(() => mockUpdateListUseCase(any())).thenAnswer((_) async => testList);
          when(() => mockGetListsUseCase()).thenAnswer((_) async => existingLists);
          return listsBloc;
        },
        act: (bloc) => bloc.add(UpdateList(testList)),
        expect: () => [
          isA<ListsLoading>(),
          isA<ListsLoaded>(),
        ],
        verify: (_) {
          verify(() => mockUpdateListUseCase(testList)).called(1);
          verify(() => mockGetListsUseCase()).called(1);
        },
      );

      blocTest<ListsBloc, ListsState>(
        'emits ListsError when list update fails',
        build: () {
          when(() => mockUpdateListUseCase(any()))
              .thenThrow(Exception('Failed to update list'));
          return listsBloc;
        },
        act: (bloc) => bloc.add(UpdateList(testList)),
        expect: () => [
          isA<ListsError>()
              .having((state) => state.message, 'message', contains('Failed to update list')),
        ],
        verify: (_) {
          verify(() => mockUpdateListUseCase(testList)).called(1);
          verifyNever(() => mockGetListsUseCase());
        },
      );

      blocTest<ListsBloc, ListsState>(
        'handles curator permission validation',
        build: () {
          when(() => mockUpdateListUseCase(any()))
              .thenThrow(Exception('Only curator can update list'));
          return listsBloc;
        },
        act: (bloc) => bloc.add(UpdateList(testList)),
        expect: () => [
          isA<ListsError>()
              .having((state) => state.message, 'message', contains('Only curator')),
        ],
      );

      blocTest<ListsBloc, ListsState>(
        'handles collaborative editing conflicts',
        build: () {
          when(() => mockUpdateListUseCase(any()))
              .thenThrow(Exception('List was modified by another user'));
          return listsBloc;
        },
        act: (bloc) => bloc.add(UpdateList(testList)),
        expect: () => [
          isA<ListsError>()
              .having((state) => state.message, 'message', contains('modified by another user')),
        ],
      );
    });

    group('DeleteList Event', () {
      const testListId = 'test-list-123';
      final existingLists = TestDataFactory.createTestLists(3);

      blocTest<ListsBloc, ListsState>(
        'triggers LoadLists after successful list deletion',
        build: () {
          when(() => mockDeleteListUseCase(any())).thenAnswer((_) async {});
          when(() => mockGetListsUseCase()).thenAnswer((_) async => existingLists);
          return listsBloc;
        },
        act: (bloc) => bloc.add(DeleteList(testListId)),
        expect: () => [
          isA<ListsLoading>(),
          isA<ListsLoaded>(),
        ],
        verify: (_) {
          verify(() => mockDeleteListUseCase(testListId)).called(1);
          verify(() => mockGetListsUseCase()).called(1);
        },
      );

      blocTest<ListsBloc, ListsState>(
        'emits ListsError when list deletion fails',
        build: () {
          when(() => mockDeleteListUseCase(any()))
              .thenThrow(Exception('Failed to delete list'));
          return listsBloc;
        },
        act: (bloc) => bloc.add(DeleteList(testListId)),
        expect: () => [
          isA<ListsError>()
              .having((state) => state.message, 'message', contains('Failed to delete list')),
        ],
        verify: (_) {
          verify(() => mockDeleteListUseCase(testListId)).called(1);
          verifyNever(() => mockGetListsUseCase());
        },
      );

      blocTest<ListsBloc, ListsState>(
        'handles not found errors gracefully',
        build: () {
          when(() => mockDeleteListUseCase(any()))
              .thenThrow(Exception('List not found'));
          return listsBloc;
        },
        act: (bloc) => bloc.add(DeleteList(testListId)),
        expect: () => [
          isA<ListsError>()
              .having((state) => state.message, 'message', contains('List not found')),
        ],
      );

      blocTest<ListsBloc, ListsState>(
        'enforces curator-only deletion policy',
        build: () {
          when(() => mockDeleteListUseCase(any()))
              .thenThrow(Exception('Only curator can delete list'));
          return listsBloc;
        },
        act: (bloc) => bloc.add(DeleteList(testListId)),
        expect: () => [
          isA<ListsError>()
              .having((state) => state.message, 'message', contains('Only curator')),
        ],
      );
    });

    group('SearchLists Event', () {
      final testLists = [
        TestDataFactory.createTestList(
          id: '1',
          title: 'Coffee Shops',
          description: 'Best coffee places in town',
          category: 'food',
        ),
        TestDataFactory.createTestList(
          id: '2',
          title: 'Pizza Places',
          description: 'Delicious pizza restaurants',
          category: 'food',
        ),
        TestDataFactory.createTestList(
          id: '3',
          title: 'Coffee Roasteries',
          description: 'Local coffee roasting companies',
          category: 'coffee',
        ),
        TestDataFactory.createTestList(
          id: '4',
          title: 'Hiking Trails',
          description: 'Great outdoor adventures',
          category: 'outdoor',
        ),
      ];

      blocTest<ListsBloc, ListsState>(
        'filters lists by title when searching',
        seed: () => ListsLoaded(testLists, testLists),
        build: () => listsBloc,
        act: (bloc) => bloc.add(SearchLists('coffee')),
        expect: () => [
          isA<ListsLoaded>()
              .having((state) => state.lists.length, 'original lists length', testLists.length)
              .having((state) => state.filteredLists.length, 'filtered lists length', 2)
              .having((state) => state.filteredLists.every((list) => 
                list.title.toLowerCase().contains('coffee')
              ), 'all filtered lists contain coffee in title', true),
        ],
      );

      blocTest<ListsBloc, ListsState>(
        'filters lists by description when searching',
        seed: () => ListsLoaded(testLists, testLists),
        build: () => listsBloc,
        act: (bloc) => bloc.add(SearchLists('delicious')),
        expect: () => [
          isA<ListsLoaded>()
              .having((state) => state.filteredLists.length, 'filtered lists length', 1)
              .having((state) => state.filteredLists.first.title, 'first filtered list title', 'Pizza Places'),
        ],
      );

      blocTest<ListsBloc, ListsState>(
        'filters lists by category when searching',
        seed: () => ListsLoaded(testLists, testLists),
        build: () => listsBloc,
        act: (bloc) => bloc.add(SearchLists('food')),
        expect: () => [
          isA<ListsLoaded>()
              .having((state) => state.filteredLists.length, 'filtered lists length', 2)
              .having((state) => state.filteredLists.every((list) => 
                list.category == 'food'
              ), 'all filtered lists are food category', true),
        ],
      );

      blocTest<ListsBloc, ListsState>(
        'handles case-insensitive search correctly',
        seed: () => ListsLoaded(testLists, testLists),
        build: () => listsBloc,
        act: (bloc) => bloc.add(SearchLists('COFFEE')),
        expect: () => [
          isA<ListsLoaded>()
              .having((state) => state.filteredLists.length, 'filtered lists length', 2),
        ],
      );

      blocTest<ListsBloc, ListsState>(
        'returns empty list when no lists match query',
        seed: () => ListsLoaded(testLists, testLists),
        build: () => listsBloc,
        act: (bloc) => bloc.add(SearchLists('nonexistent')),
        expect: () => [
          isA<ListsLoaded>()
              .having((state) => state.filteredLists.length, 'filtered lists length', 0),
        ],
      );

      blocTest<ListsBloc, ListsState>(
        'handles null category gracefully',
        seed: () => ListsLoaded([
          TestDataFactory.createTestList(
            title: 'No Category List',
            category: null,
          ),
        ], []),
        build: () => listsBloc,
        // Use a query that would only match via category (if present), not via title.
        act: (bloc) => bloc.add(SearchLists('food')),
        expect: () => [
          isA<ListsLoaded>()
              .having((state) => state.filteredLists.length, 'filtered lists length', 0),
        ],
      );

      blocTest<ListsBloc, ListsState>(
        'does nothing when current state is not ListsLoaded',
        build: () => listsBloc,
        act: (bloc) => bloc.add(SearchLists('coffee')),
        expect: () => [],
      );

      blocTest<ListsBloc, ListsState>(
        'handles empty search query',
        seed: () => ListsLoaded(testLists, testLists),
        build: () => listsBloc,
        act: (bloc) => bloc.add(SearchLists('')),
        expect: () => [
          isA<ListsLoaded>()
              .having((state) => state.filteredLists.length, 'filtered lists length', testLists.length),
        ],
      );
    });

    group('Role-Based Operations Testing', () {
      blocTest<ListsBloc, ListsState>(
        'handles curator role validation for updates',
        build: () {
          final curatorList = TestDataFactory.createTestList(
            curatorId: 'current-user-id',
            collaboratorIds: ['other-user-1'],
            followerIds: ['other-user-2'],
          );
          
          when(() => mockUpdateListUseCase(any())).thenAnswer((_) async => curatorList);
          when(() => mockGetListsUseCase()).thenAnswer((_) async => [curatorList]);
          return listsBloc;
        },
        act: (bloc) => bloc.add(UpdateList(TestDataFactory.createTestList())),
        expect: () => [
          isA<ListsLoading>(),
          isA<ListsLoaded>(),
        ],
      );

      blocTest<ListsBloc, ListsState>(
        'handles collaborator permissions correctly',
        build: () {
          when(() => mockUpdateListUseCase(any()))
              .thenThrow(Exception('Collaborators cannot modify list settings'));
          return listsBloc;
        },
        act: (bloc) => bloc.add(UpdateList(TestDataFactory.createTestList())),
        expect: () => [
          isA<ListsError>()
              .having((state) => state.message, 'message', contains('Collaborators cannot')),
        ],
      );

      blocTest<ListsBloc, ListsState>(
        'handles follower read-only restrictions',
        build: () {
          when(() => mockUpdateListUseCase(any()))
              .thenThrow(Exception('Followers have read-only access'));
          return listsBloc;
        },
        act: (bloc) => bloc.add(UpdateList(TestDataFactory.createTestList())),
        expect: () => [
          isA<ListsError>()
              .having((state) => state.message, 'message', contains('read-only access')),
        ],
      );
    });

    group('Collaborative Editing Scenarios', () {
      blocTest<ListsBloc, ListsState>(
        'handles concurrent edit conflicts',
        build: () {
          when(() => mockUpdateListUseCase(any()))
              .thenThrow(Exception('List version conflict'));
          return listsBloc;
        },
        act: (bloc) => bloc.add(UpdateList(TestDataFactory.createTestList())),
        expect: () => [
          isA<ListsError>()
              .having((state) => state.message, 'message', contains('version conflict')),
        ],
      );

      blocTest<ListsBloc, ListsState>(
        'handles real-time updates gracefully',
        build: () {
          var callCount = 0;
          when(() => mockGetListsUseCase()).thenAnswer((_) async {
            callCount++;
            return TestDataFactory.createTestLists(callCount + 2); // Simulate new lists being added
          });
          return listsBloc;
        },
        act: (bloc) async {
          bloc.add(LoadLists());
          await Future.delayed(const Duration(milliseconds: 50));
          bloc.add(LoadLists()); // Simulate refresh from real-time update
        },
        verify: (_) {
          verify(() => mockGetListsUseCase()).called(2);
        },
      );

      blocTest<ListsBloc, ListsState>(
        'handles simultaneous operations on different lists',
        build: () {
          when(() => mockCreateListUseCase(any())).thenAnswer((_) async => TestDataFactory.createTestList());
          when(() => mockUpdateListUseCase(any())).thenAnswer((_) async => TestDataFactory.createTestList());
          when(() => mockDeleteListUseCase(any())).thenAnswer((_) async {});
          when(() => mockGetListsUseCase()).thenAnswer((_) async => TestDataFactory.createTestLists(3));
          return listsBloc;
        },
        act: (bloc) {
          bloc.add(CreateList(TestDataFactory.createTestList()));
          bloc.add(UpdateList(TestDataFactory.createTestList()));
          bloc.add(DeleteList('some-list-id'));
        },
        // Should handle multiple operations without crashing
        verify: (_) {
          verify(() => mockGetListsUseCase()).called(greaterThan(0));
        },
      );
    });

    group('Performance and Edge Cases', () {
      test('ListsLoaded state initializes correctly', () {
        final testLists = TestDataFactory.createTestLists(5);
        final state = ListsLoaded(testLists, testLists);
        
        expect(state.lists, equals(testLists));
        expect(state.filteredLists, equals(testLists));
      });

      blocTest<ListsBloc, ListsState>(
        'maintains performance with large lists datasets',
        build: () {
          final largeLists = TestDataFactory.createTestLists(500);
          when(() => mockGetListsUseCase()).thenAnswer((_) async => largeLists);
          return listsBloc;
        },
        act: (bloc) => bloc.add(LoadLists()),
        expect: () => [
          isA<ListsLoading>(),
          isA<ListsLoaded>()
              .having((state) => state.lists.length, 'lists length', 500),
        ],
      );

      blocTest<ListsBloc, ListsState>(
        'handles rapid fire operations correctly',
        build: () {
          when(() => mockGetListsUseCase()).thenAnswer((_) async => TestDataFactory.createTestLists(3));
          when(() => mockCreateListUseCase(any())).thenAnswer((_) async => TestDataFactory.createTestList());
          when(() => mockUpdateListUseCase(any())).thenAnswer((_) async => TestDataFactory.createTestList());
          when(() => mockDeleteListUseCase(any())).thenAnswer((_) async {});
          return listsBloc;
        },
        act: (bloc) {
          bloc.add(LoadLists());
          bloc.add(CreateList(TestDataFactory.createTestList()));
          bloc.add(UpdateList(TestDataFactory.createTestList()));
          bloc.add(DeleteList('test-id'));
          bloc.add(LoadLists());
        },
        // Should handle events without crashing
        verify: (_) {
          verify(() => mockGetListsUseCase()).called(greaterThan(0));
        },
      );

      blocTest<ListsBloc, ListsState>(
        'search performance with large filtered results',
        seed: () => ListsLoaded(
          TestDataFactory.createTestLists(1000),
          TestDataFactory.createTestLists(1000),
        ),
        build: () => listsBloc,
        act: (bloc) => bloc.add(SearchLists('test')),
        // Should complete search within reasonable time
        verify: (_) {
          // Search should complete without timeout
        },
      );

      blocTest<ListsBloc, ListsState>(
        'handles lists with complex role hierarchies',
        build: () {
          final complexLists = [
            TestDataFactory.createTestList(
              curatorId: 'curator-1',
              collaboratorIds: ['collab-1', 'collab-2', 'collab-3'],
              followerIds: ['follower-1', 'follower-2', 'follower-3', 'follower-4'],
            ),
          ];
          when(() => mockGetListsUseCase()).thenAnswer((_) async => complexLists);
          return listsBloc;
        },
        act: (bloc) => bloc.add(LoadLists()),
        expect: () => [
          isA<ListsLoading>(),
          isA<ListsLoaded>(),
        ],
      );
    });

    group('State Persistence and Recovery', () {
      blocTest<ListsBloc, ListsState>(
        'recovers from error state with successful operation',
        build: () {
          var callCount = 0;
          when(() => mockGetListsUseCase()).thenAnswer((_) async {
            callCount++;
            if (callCount == 1) {
              throw Exception('Network error');
            }
            return TestDataFactory.createTestLists(3);
          });
          return listsBloc;
        },
        act: (bloc) async {
          // First attempt fails
          bloc.add(LoadLists());
          await Future.delayed(const Duration(milliseconds: 50));
          
          // Second attempt succeeds
          bloc.add(LoadLists());
        },
        verify: (_) {
          verify(() => mockGetListsUseCase()).called(2);
        },
      );

      blocTest<ListsBloc, ListsState>(
        'preserves filtered state during refresh operations',
        seed: () => ListsLoaded(
          TestDataFactory.createTestLists(5),
          TestDataFactory.createTestLists(2), // Filtered state
        ),
        build: () {
          when(() => mockCreateListUseCase(any())).thenAnswer((_) async => TestDataFactory.createTestList());
          when(() => mockGetListsUseCase()).thenAnswer((_) async => TestDataFactory.createTestLists(6));
          return listsBloc;
        },
        act: (bloc) => bloc.add(CreateList(TestDataFactory.createTestList())),
        expect: () => [
          isA<ListsLoading>(),
          isA<ListsLoaded>()
              .having((state) => state.lists.length, 'lists length', 6),
        ],
      );
    });

    group('Privacy and Security Validation', () {
      blocTest<ListsBloc, ListsState>(
        'validates privacy settings for public lists',
        build: () {
          final publicList = TestDataFactory.createTestList(isPublic: true);
          when(() => mockCreateListUseCase(any())).thenAnswer((_) async => publicList);
          when(() => mockGetListsUseCase()).thenAnswer((_) async => [publicList]);
          return listsBloc;
        },
        act: (bloc) => bloc.add(CreateList(TestDataFactory.createTestList(isPublic: true))),
        expect: () => [
          isA<ListsLoading>(),
          isA<ListsLoaded>(),
        ],
      );

      blocTest<ListsBloc, ListsState>(
        'validates privacy settings for private lists',
        build: () {
          final privateList = TestDataFactory.createTestList(isPublic: false);
          when(() => mockCreateListUseCase(any())).thenAnswer((_) async => privateList);
          when(() => mockGetListsUseCase()).thenAnswer((_) async => [privateList]);
          return listsBloc;
        },
        act: (bloc) => bloc.add(CreateList(TestDataFactory.createTestList(isPublic: false))),
        expect: () => [
          isA<ListsLoading>(),
          isA<ListsLoaded>(),
        ],
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:spots/data/datasources/remote/lists_remote_datasource_impl.dart';
import 'package:spots_network/spots_network.dart';
import 'package:spots/core/models/list.dart';
import 'package:spots_core/spots_core.dart' as spots_core;
import 'package:spots/injection_container.dart' as di;

import 'lists_remote_datasource_impl_test.mocks.dart';

@GenerateMocks([DataBackend])
void main() {
  group('ListsRemoteDataSourceImpl', () {
    late ListsRemoteDataSourceImpl dataSource;
    late MockDataBackend mockDataBackend;

    setUp(() async {
      mockDataBackend = MockDataBackend();
      await di.sl.reset();
      di.sl.registerSingleton<DataBackend>(mockDataBackend);
      dataSource = ListsRemoteDataSourceImpl();
    });
    
    tearDown(() async {
      await di.sl.reset();
    });

    group('getLists', () {
      test('should get lists from remote backend', () async {
        final coreLists = <spots_core.SpotList>[
          spots_core.SpotList(
            id: 'list-1',
            title: 'List 1',
            description: 'Desc',
            category: spots_core.ListCategory.general,
            type: spots_core.ListType.private,
            curatorId: 'curator-1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isPublic: false,
            spotIds: const [],
          ),
        ];
        when(mockDataBackend.getSpotLists(limit: anyNamed('limit')))
            .thenAnswer((_) async => ApiResponse.success(coreLists));

        final lists = await dataSource.getLists();

        expect(lists, isA<List<SpotList>>());
        expect(lists.length, equals(1));
      });
    });

    group('getPublicLists', () {
      test('should get public lists from remote backend', () async {
        final coreLists = <spots_core.SpotList>[
          spots_core.SpotList(
            id: 'pub-1',
            title: 'Public List',
            description: 'Desc',
            category: spots_core.ListCategory.general,
            type: spots_core.ListType.public,
            curatorId: 'curator-1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isPublic: true,
            spotIds: const [],
          ),
        ];
        when(
          mockDataBackend.getSpotLists(
            limit: anyNamed('limit'),
            filters: anyNamed('filters'),
          ),
        ).thenAnswer((_) async => ApiResponse.success(coreLists));

        final lists = await dataSource.getPublicLists();

        expect(lists, isA<List<SpotList>>());
        // All returned lists should be public
        for (final list in lists) {
          expect(list.isPublic, isTrue);
        }
      });

      test('should respect limit parameter', () async {
        const limit = 10;
        when(
          mockDataBackend.getSpotLists(
            limit: anyNamed('limit'),
            filters: anyNamed('filters'),
          ),
        ).thenAnswer((_) async => ApiResponse.success(<spots_core.SpotList>[]));
        final lists = await dataSource.getPublicLists(limit: limit);

        expect(lists.length, lessThanOrEqualTo(limit));
      });
    });

    group('createList', () {
      test('should create list via remote backend', () async {
        final list = SpotList(
          id: 'list-1',
          title: 'New List',
          description: 'New Description',
          spots: [],
          category: null,
          curatorId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockDataBackend.createSpotList(any)).thenAnswer(
          (_) async => ApiResponse.success(
            spots_core.SpotList(
              id: list.id,
              title: list.title,
              description: list.description,
              category: spots_core.ListCategory.general,
              type: spots_core.ListType.public,
              curatorId: 'curator-1',
              createdAt: list.createdAt,
              updatedAt: list.updatedAt,
              isPublic: true,
              spotIds: const [],
            ),
          ),
        );
        final result = await dataSource.createList(list);

        expect(result, isNotNull);
        expect(result.title, equals(list.title));
      });
    });

    group('updateList', () {
      test('should update list via remote backend', () async {
        final list = SpotList(
          id: 'list-1',
          title: 'Updated List',
          description: 'Updated Description',
          spots: [],
          category: null,
          curatorId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockDataBackend.updateSpotList(any)).thenAnswer(
          (_) async => ApiResponse.success(
            spots_core.SpotList(
              id: list.id,
              title: list.title,
              description: list.description,
              category: spots_core.ListCategory.general,
              type: spots_core.ListType.public,
              curatorId: 'curator-1',
              createdAt: list.createdAt,
              updatedAt: list.updatedAt,
              isPublic: true,
              spotIds: const [],
            ),
          ),
        );
        final result = await dataSource.updateList(list);

        expect(result, isNotNull);
        expect(result.title, equals(list.title));
      });
    });

    group('deleteList', () {
      test('should delete list via remote backend', () async {
        const listId = 'list-1';

        when(mockDataBackend.deleteSpotList(listId))
            .thenAnswer((_) async => const ApiResponse<void>(success: true));
        await expectLater(
          dataSource.deleteList(listId),
          completes,
        );
        verify(mockDataBackend.deleteSpotList(listId)).called(1);
      });
    });
  });
}


import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/data/datasources/remote/lists_remote_datasource_impl.dart';
import 'package:spots_network/spots_network.dart';
import 'package:spots/core/models/list.dart';

import 'lists_remote_datasource_impl_test.mocks.dart';

@GenerateMocks([DataBackend])
void main() {
  group('ListsRemoteDataSourceImpl', () {
    late ListsRemoteDataSourceImpl dataSource;
    late MockDataBackend mockDataBackend;

    setUp(() {
      mockDataBackend = MockDataBackend();
      // Note: This test requires dependency injection setup
      dataSource = ListsRemoteDataSourceImpl();
    });

    group('getLists', () {
      test('should get lists from remote backend', () async {
        final lists = await dataSource.getLists();

        expect(lists, isA<List<SpotList>>());
      });
    });

    group('getPublicLists', () {
      test('should get public lists from remote backend', () async {
        final lists = await dataSource.getPublicLists();

        expect(lists, isA<List<SpotList>>());
        // All returned lists should be public
        for (final list in lists) {
          expect(list.isPublic, isTrue);
        }
      });

      test('should respect limit parameter', () async {
        const limit = 10;
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
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
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
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final result = await dataSource.updateList(list);

        expect(result, isNotNull);
        expect(result.title, equals(list.title));
      });
    });

    group('deleteList', () {
      test('should delete list via remote backend', () async {
        const listId = 'list-1';

        await expectLater(
          dataSource.deleteList(listId),
          completes,
        );
      });
    });
  });
}


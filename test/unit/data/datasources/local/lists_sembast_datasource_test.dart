import 'package:flutter_test/flutter_test.dart';
import 'package:spots/data/datasources/local/lists_sembast_datasource.dart';
import 'package:spots/data/datasources/local/sembast_database.dart';
import 'package:spots/core/models/list.dart';

/// Lists Sembast Data Source Tests
/// Tests local lists data storage using Sembast
void main() {
  group('ListsSembastDataSource', () {
    late ListsSembastDataSource dataSource;

    setUp(() {
      // Use in-memory database for tests
      SembastDatabase.useInMemoryForTests();
      dataSource = ListsSembastDataSource();
    });

    tearDown(() async {
      // Clean up database after each test
      await SembastDatabase.resetForTests();
    });

    group('getLists', () {
      test('should get all lists from database', () async {
        final lists = await dataSource.getLists();

        expect(lists, isA<List<SpotList>>());
      });

      test('should return empty list when database is empty', () async {
        final lists = await dataSource.getLists();

        expect(lists, isEmpty);
      });
    });

    group('saveList', () {
      test('should create new list when id is empty', () async {
        final list = SpotList(
          id: '',
          title: 'New List',
          description: 'New Description',
          spots: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final saved = await dataSource.saveList(list);

        expect(saved, isNotNull);
        expect(saved?.id, isNotEmpty);
        expect(saved?.title, equals('New List'));
      });

      test('should update existing list when id is provided', () async {
        final list = SpotList(
          id: 'list-1',
          title: 'Original Title',
          description: 'Original Description',
          spots: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await dataSource.saveList(list);
        
        final updated = list.copyWith(title: 'Updated Title');
        final saved = await dataSource.saveList(updated);

        expect(saved?.title, equals('Updated Title'));
      });
    });

    group('deleteList', () {
      test('should delete list from database', () async {
        final list = SpotList(
          id: 'list-1',
          title: 'Test List',
          description: 'Test Description',
          spots: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await dataSource.saveList(list);
        await dataSource.deleteList('list-1');

        final lists = await dataSource.getLists();
        expect(lists.where((l) => l.id == 'list-1'), isEmpty);
      });

      test('should handle deleting non-existent list gracefully', () async {
        await expectLater(
          dataSource.deleteList('non-existent'),
          completes,
        );
      });
    });
  });
}


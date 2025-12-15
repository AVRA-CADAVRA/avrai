import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart';
import 'package:spots/data/datasources/local/respected_lists_sembast_datasource.dart';
import 'package:spots/data/datasources/local/sembast_database.dart';

/// Respected Lists Sembast Data Source Tests
/// Tests storage of user-respected lists
void main() {
  group('RespectedListsSembastDataSource', () {
    late RespectedListsSembastDataSource dataSource;
    late Database database;

    setUp(() async {
      // Use in-memory database for tests
      SembastDatabase.useInMemoryForTests();
      database = await SembastDatabase.database;
      dataSource = RespectedListsSembastDataSource(database);
    });

    tearDown(() async {
      // Clean up database after each test
      await SembastDatabase.resetForTests();
    });

    group('saveRespectedLists', () {
      test('should save respected lists for user', () async {
        const userId = 'user-123';
        final listNames = ['List 1', 'List 2', 'List 3'];

        await expectLater(
          dataSource.saveRespectedLists(userId, listNames),
          completes,
        );
      });

      test('should overwrite existing respected lists', () async {
        const userId = 'user-123';
        final listNames1 = ['List 1', 'List 2'];
        final listNames2 = ['List 3', 'List 4'];

        await dataSource.saveRespectedLists(userId, listNames1);
        await dataSource.saveRespectedLists(userId, listNames2);

        final retrieved = await dataSource.getRespectedLists(userId);
        expect(retrieved, equals(listNames2));
      });
    });

    group('getRespectedLists', () {
      test('should get respected lists for user', () async {
        const userId = 'user-123';
        final listNames = ['List 1', 'List 2'];

        await dataSource.saveRespectedLists(userId, listNames);
        final retrieved = await dataSource.getRespectedLists(userId);

        expect(retrieved, equals(listNames));
      });

      test('should return empty list when user has no respected lists', () async {
        const userId = 'new-user';

        final retrieved = await dataSource.getRespectedLists(userId);

        expect(retrieved, isEmpty);
      });
    });

    group('clearRespectedLists', () {
      test('should clear respected lists for user', () async {
        const userId = 'user-123';
        final listNames = ['List 1', 'List 2'];

        await dataSource.saveRespectedLists(userId, listNames);
        await dataSource.clearRespectedLists(userId);

        final retrieved = await dataSource.getRespectedLists(userId);
        expect(retrieved, isEmpty);
      });
    });

    group('getAllRespectedLists', () {
      test('should get all respected lists for all users', () async {
        await dataSource.saveRespectedLists('user-1', ['List 1']);
        await dataSource.saveRespectedLists('user-2', ['List 2', 'List 3']);

        final all = await dataSource.getAllRespectedLists();

        expect(all.length, equals(2));
        expect(all['user-1'], equals(['List 1']));
        expect(all['user-2'], equals(['List 2', 'List 3']));
      });

      test('should return empty map when no respected lists exist', () async {
        final all = await dataSource.getAllRespectedLists();

        expect(all, isEmpty);
      });
    });
  });
}


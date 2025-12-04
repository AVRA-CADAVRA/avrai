import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_io.dart';
import 'package:spots/data/datasources/local/respected_lists_sembast_datasource.dart';

void main() {
  group('RespectedListsSembastDataSource', () {
    late RespectedListsSembastDataSource dataSource;
    late Database database;

    setUp(() async {
      // Create an in-memory database for testing
      database = await databaseFactoryIo.openDatabase('test.db');
      dataSource = RespectedListsSembastDataSource(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('should save and retrieve respected lists correctly', () async {
      // Arrange
      const userId = 'test-user-id';
      final listNames = [
        'Brooklyn Coffee Crawl',
        'Hidden Gems in Williamsburg'
      ];

      // Act - Save respected lists
      await dataSource.saveRespectedLists(userId, listNames);

      // Act - Retrieve respected lists
      final retrievedLists = await dataSource.getRespectedLists(userId);

      // Assert
      expect(retrievedLists, equals(listNames));
      expect(retrievedLists.length, equals(2));
      expect(retrievedLists.contains('Brooklyn Coffee Crawl'), isTrue);
      expect(retrievedLists.contains('Hidden Gems in Williamsburg'), isTrue);
    });

    test('should return empty list when no respected lists exist', () async {
      // Arrange
      const userId = 'non-existent-user-id';

      // Act
      final retrievedLists = await dataSource.getRespectedLists(userId);

      // Assert
      expect(retrievedLists, isEmpty);
    });

    test('should clear respected lists correctly', () async {
      // Arrange
      const userId = 'test-user-id';
      final listNames = ['Test List 1', 'Test List 2'];
      await dataSource.saveRespectedLists(userId, listNames);

      // Act
      await dataSource.clearRespectedLists(userId);
      final retrievedLists = await dataSource.getRespectedLists(userId);

      // Assert
      expect(retrievedLists, isEmpty);
    });

    test('should handle different user IDs separately', () async {
      // Arrange
      const user1Id = 'user-1-id';
      const user2Id = 'user-2-id';
      final user1Lists = ['List 1', 'List 2'];
      final user2Lists = ['List 3'];

      // Act
      await dataSource.saveRespectedLists(user1Id, user1Lists);
      await dataSource.saveRespectedLists(user2Id, user2Lists);

      final user1Retrieved = await dataSource.getRespectedLists(user1Id);
      final user2Retrieved = await dataSource.getRespectedLists(user2Id);

      // Assert
      expect(user1Retrieved, equals(user1Lists));
      expect(user2Retrieved, equals(user2Lists));
      expect(user1Retrieved.length, equals(2));
      expect(user2Retrieved.length, equals(1));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/core/models/list.dart';
import 'package:spots/core/models/spot.dart';
import 'package:spots/domain/repositories/lists_repository.dart';
import 'package:spots/domain/usecases/lists/create_list_usecase.dart';

import 'create_list_usecase_test.mocks.dart';

// Generate mocks
@GenerateMocks([ListsRepository])
void main() {
  group('CreateListUseCase', () {
    late CreateListUseCase usecase;
    late MockListsRepository mockRepository;
    late SpotList testList;
    late List<Spot> testSpots;

    setUp(() {
      mockRepository = MockListsRepository();
      usecase = CreateListUseCase(mockRepository);
      
      testSpots = [
        Spot(
          id: 'spot_1',
          name: 'Test Spot 1',
          description: 'First test spot',
          latitude: 40.7128,
          longitude: -74.0060,
          category: 'restaurant',
          rating: 4.5,
          createdBy: 'user123',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
        Spot(
          id: 'spot_2',
          name: 'Test Spot 2',
          description: 'Second test spot',
          latitude: 40.7589,
          longitude: -73.9851,
          category: 'park',
          rating: 4.2,
          createdBy: 'user123',
          createdAt: DateTime(2024, 1, 2),
          updatedAt: DateTime(2024, 1, 2),
        ),
      ];

      testList = SpotList(
        id: 'list_123',
        title: 'My Favorite Places',
        description: 'A collection of my favorite spots in the city',
        spots: testSpots,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        category: 'personal',
        isPublic: true,
        spotIds: ['spot_1', 'spot_2'],
        respectCount: 0,
      );
    });

    group('Successful list creation', () {
      test('should create list successfully with all fields', () async {
        // Arrange
        when(mockRepository.createList(testList))
            .thenAnswer((_) async => testList);

        // Act
        final result = await usecase.call(testList);

        // Assert
        expect(result, equals(testList));
        expect(result.title, equals('My Favorite Places'));
        expect(result.spots, hasLength(2));
        expect(result.spotIds, equals(['spot_1', 'spot_2']));
        expect(result.isPublic, isTrue);
        verify(mockRepository.createList(testList)).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should create minimal list with required fields only', () async {
        // Arrange
        final minimalList = SpotList(
          id: 'minimal_list',
          title: 'Minimal List',
          description: 'Simple description',
          spots: [],
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        when(mockRepository.createList(minimalList))
            .thenAnswer((_) async => minimalList);

        // Act
        final result = await usecase.call(minimalList);

        // Assert
        expect(result, equals(minimalList));
        expect(result.spots, isEmpty);
        expect(result.spotIds, isEmpty);
        expect(result.category, isNull);
        expect(result.isPublic, isTrue); // Default value
        expect(result.respectCount, equals(0)); // Default value
        verify(mockRepository.createList(minimalList)).called(1);
      });

      test('should create private list', () async {
        // Arrange
        final privateList = testList.copyWith(
          isPublic: false,
          title: 'Private List',
        );

        when(mockRepository.createList(privateList))
            .thenAnswer((_) async => privateList);

        // Act
        final result = await usecase.call(privateList);

        // Assert
        expect(result.isPublic, isFalse);
        expect(result.title, equals('Private List'));
        verify(mockRepository.createList(privateList)).called(1);
      });

      test('should create list with many spots', () async {
        // Arrange
        final manySpots = List.generate(50, (index) => Spot(
          id: 'spot_$index',
          name: 'Spot $index',
          description: 'Description $index',
          latitude: 40.0 + (index * 0.01),
          longitude: -74.0 + (index * 0.01),
          category: 'test',
          rating: (index % 5) + 1.0,
          createdBy: 'user123',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        final manySpotIds = List.generate(50, (index) => 'spot_$index');
        final largeList = testList.copyWith(
          spots: manySpots,
          spotIds: manySpotIds,
          title: 'Large List',
        );

        when(mockRepository.createList(largeList))
            .thenAnswer((_) async => largeList);

        // Act
        final result = await usecase.call(largeList);

        // Assert
        expect(result.spots, hasLength(50));
        expect(result.spotIds, hasLength(50));
        expect(result.title, equals('Large List'));
        verify(mockRepository.createList(largeList)).called(1);
      });

      test('should create list with different categories', () async {
        // Arrange
        final categories = ['food', 'entertainment', 'shopping', 'outdoor', 'culture'];

        for (final category in categories) {
          final categorizedList = testList.copyWith(
            category: category,
            title: '$category List',
            id: 'list_$category',
          );

          when(mockRepository.createList(categorizedList))
              .thenAnswer((_) async => categorizedList);

          // Act
          final result = await usecase.call(categorizedList);

          // Assert
          expect(result.category, equals(category));
          expect(result.title, equals('$category List'));
          verify(mockRepository.createList(categorizedList)).called(1);
        }
      });

      test('should preserve all list properties during creation', () async {
        // Arrange
        when(mockRepository.createList(testList))
            .thenAnswer((_) async => testList);

        // Act
        final result = await usecase.call(testList);

        // Assert
        expect(result.id, equals(testList.id));
        expect(result.title, equals(testList.title));
        expect(result.description, equals(testList.description));
        expect(result.spots, equals(testList.spots));
        expect(result.createdAt, equals(testList.createdAt));
        expect(result.updatedAt, equals(testList.updatedAt));
        expect(result.category, equals(testList.category));
        expect(result.isPublic, equals(testList.isPublic));
        expect(result.spotIds, equals(testList.spotIds));
        expect(result.respectCount, equals(testList.respectCount));
        verify(mockRepository.createList(testList)).called(1);
      });
    });

    group('Edge cases and validation', () {
      test('should handle empty title', () async {
        // Arrange
        final emptyTitleList = testList.copyWith(title: '');

        when(mockRepository.createList(emptyTitleList))
            .thenAnswer((_) async => emptyTitleList);

        // Act
        final result = await usecase.call(emptyTitleList);

        // Assert
        expect(result.title, equals(''));
        verify(mockRepository.createList(emptyTitleList)).called(1);
      });

      test('should handle empty description', () async {
        // Arrange
        final emptyDescList = testList.copyWith(description: '');

        when(mockRepository.createList(emptyDescList))
            .thenAnswer((_) async => emptyDescList);

        // Act
        final result = await usecase.call(emptyDescList);

        // Assert
        expect(result.description, equals(''));
        verify(mockRepository.createList(emptyDescList)).called(1);
      });

      test('should handle very long title', () async {
        // Arrange
        final longTitle = 'Title ' * 100;
        final longTitleList = testList.copyWith(title: longTitle);

        when(mockRepository.createList(longTitleList))
            .thenAnswer((_) async => longTitleList);

        // Act
        final result = await usecase.call(longTitleList);

        // Assert
        expect(result.title, equals(longTitle));
        verify(mockRepository.createList(longTitleList)).called(1);
      });

      test('should handle very long description', () async {
        // Arrange
        final longDescription = 'Description ' * 200;
        final longDescList = testList.copyWith(description: longDescription);

        when(mockRepository.createList(longDescList))
            .thenAnswer((_) async => longDescList);

        // Act
        final result = await usecase.call(longDescList);

        // Assert
        expect(result.description, equals(longDescription));
        verify(mockRepository.createList(longDescList)).called(1);
      });

      test('should handle special characters in title and description', () async {
        // Arrange
        final specialTitle = 'List !@#\$%^&*()_+{}|:<>?[]\\;\'\",./ Title';
        final specialDescription = 'Description !@#\$%^&*()_+{}|:<>?[]\\;\'\",./ Text';
        final specialList = testList.copyWith(
          title: specialTitle,
          description: specialDescription,
        );

        when(mockRepository.createList(specialList))
            .thenAnswer((_) async => specialList);

        // Act
        final result = await usecase.call(specialList);

        // Assert
        expect(result.title, equals(specialTitle));
        expect(result.description, equals(specialDescription));
        verify(mockRepository.createList(specialList)).called(1);
      });

      test('should handle unicode characters', () async {
        // Arrange
        final unicodeList = testList.copyWith(
          title: '我的最爱景点 🏛️ Café Münü',
          description: 'Descripción con ñ, à, é, î, ö, ü, ç and 中文',
        );

        when(mockRepository.createList(unicodeList))
            .thenAnswer((_) async => unicodeList);

        // Act
        final result = await usecase.call(unicodeList);

        // Assert
        expect(result.title, equals('我的最爱景点 🏛️ Café Münü'));
        expect(result.description, contains('中文'));
        verify(mockRepository.createList(unicodeList)).called(1);
      });

      test('should handle null category', () async {
        // Arrange
        final nullCategoryList = testList.copyWith(category: null);

        when(mockRepository.createList(nullCategoryList))
            .thenAnswer((_) async => nullCategoryList);

        // Act
        final result = await usecase.call(nullCategoryList);

        // Assert
        expect(result.category, isNull);
        verify(mockRepository.createList(nullCategoryList)).called(1);
      });

      test('should handle mismatched spots and spotIds', () async {
        // Arrange
        final mismatchedList = testList.copyWith(
          spots: [testSpots.first], // 1 spot
          spotIds: ['spot_1', 'spot_2', 'spot_3'], // 3 IDs
        );

        when(mockRepository.createList(mismatchedList))
            .thenAnswer((_) async => mismatchedList);

        // Act
        final result = await usecase.call(mismatchedList);

        // Assert
        expect(result.spots, hasLength(1));
        expect(result.spotIds, hasLength(3));
        verify(mockRepository.createList(mismatchedList)).called(1);
      });

      test('should handle extreme respect count values', () async {
        // Arrange
        final extremeRespectList = testList.copyWith(respectCount: 999999);

        when(mockRepository.createList(extremeRespectList))
            .thenAnswer((_) async => extremeRespectList);

        // Act
        final result = await usecase.call(extremeRespectList);

        // Assert
        expect(result.respectCount, equals(999999));
        verify(mockRepository.createList(extremeRespectList)).called(1);
      });

      test('should handle negative respect count', () async {
        // Arrange
        final negativeRespectList = testList.copyWith(respectCount: -5);

        when(mockRepository.createList(negativeRespectList))
            .thenAnswer((_) async => negativeRespectList);

        // Act
        final result = await usecase.call(negativeRespectList);

        // Assert
        expect(result.respectCount, equals(-5));
        verify(mockRepository.createList(negativeRespectList)).called(1);
      });
    });

    group('Error handling', () {
      test('should throw exception when repository throws exception', () async {
        // Arrange
        final exception = Exception('Failed to create list');
        when(mockRepository.createList(testList))
            .thenThrow(exception);

        // Act & Assert
        expect(
          () async => await usecase.call(testList),
          throwsA(exception),
        );
        verify(mockRepository.createList(testList)).called(1);
      });

      test('should handle validation error from repository', () async {
        // Arrange
        final validationError = ArgumentError('Invalid list data');
        when(mockRepository.createList(testList))
            .thenThrow(validationError);

        // Act & Assert
        expect(
          () async => await usecase.call(testList),
          throwsA(validationError),
        );
        verify(mockRepository.createList(testList)).called(1);
      });

      test('should handle network error during creation', () async {
        // Arrange
        final networkError = Exception('Network error');
        when(mockRepository.createList(testList))
            .thenThrow(networkError);

        // Act & Assert
        expect(
          () async => await usecase.call(testList),
          throwsA(networkError),
        );
        verify(mockRepository.createList(testList)).called(1);
      });

      test('should handle permission denied error', () async {
        // Arrange
        final permissionError = Exception('Permission denied');
        when(mockRepository.createList(testList))
            .thenThrow(permissionError);

        // Act & Assert
        expect(
          () async => await usecase.call(testList),
          throwsA(permissionError),
        );
        verify(mockRepository.createList(testList)).called(1);
      });

      test('should handle database constraint violation', () async {
        // Arrange
        final constraintError = Exception('Constraint violation');
        when(mockRepository.createList(testList))
            .thenThrow(constraintError);

        // Act & Assert
        expect(
          () async => await usecase.call(testList),
          throwsA(constraintError),
        );
        verify(mockRepository.createList(testList)).called(1);
      });

      test('should handle repository returning modified list', () async {
        // Arrange
        final modifiedList = testList.copyWith(
          id: 'server_generated_id',
          createdAt: DateTime(2024, 1, 2),
          updatedAt: DateTime(2024, 1, 2),
          respectCount: 1, // Server modified
        );

        when(mockRepository.createList(testList))
            .thenAnswer((_) async => modifiedList);

        // Act
        final result = await usecase.call(testList);

        // Assert
        expect(result.id, equals('server_generated_id'));
        expect(result.title, equals(testList.title)); // Preserved
        expect(result.respectCount, equals(1)); // Modified by server
        expect(result.createdAt, isNot(equals(testList.createdAt)));
        verify(mockRepository.createList(testList)).called(1);
      });
    });

    group('Business logic validation', () {
      test('should pass list exactly as provided to repository', () async {
        // Arrange
        when(mockRepository.createList(testList))
            .thenAnswer((_) async => testList);

        // Act
        final result = await usecase.call(testList);

        // Assert
        expect(result, equals(testList));
        // Capture the argument and assert identity (not just equality).
        final captured = verify(mockRepository.createList(captureAny)).captured.single as SpotList;
        expect(identical(captured, testList), isTrue);
      });

      test('should not modify or validate list before passing to repository', () async {
        // Arrange
        when(mockRepository.createList(testList))
            .thenAnswer((_) async => testList);

        // Act
        final result = await usecase.call(testList);

        // Assert
        expect(result, equals(testList));
        verify(mockRepository.createList(testList)).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle concurrent list creation attempts', () async {
        // Arrange
        when(mockRepository.createList(testList))
            .thenAnswer((_) async => testList);

        // Act
        final futures = List.generate(3, (_) => usecase.call(testList));
        final results = await Future.wait(futures);

        // Assert
        for (final result in results) {
          expect(result, equals(testList));
        }
        verify(mockRepository.createList(testList)).called(3);
      });

      test('should be stateless between calls', () async {
        // Arrange
        final list1 = testList.copyWith(id: 'list1', title: 'List 1');
        final list2 = testList.copyWith(id: 'list2', title: 'List 2');

        when(mockRepository.createList(list1))
            .thenAnswer((_) async => list1);
        when(mockRepository.createList(list2))
            .thenAnswer((_) async => list2);

        // Act
        final result1 = await usecase.call(list1);
        final result2 = await usecase.call(list2);

        // Assert
        expect(result1.id, equals('list1'));
        expect(result1.title, equals('List 1'));
        expect(result2.id, equals('list2'));
        expect(result2.title, equals('List 2'));
        verify(mockRepository.createList(list1)).called(1);
        verify(mockRepository.createList(list2)).called(1);
      });

      test('should preserve timestamps from input', () async {
        // Arrange
        final now = DateTime.now();
        final timestampedList = testList.copyWith(
          createdAt: now,
          updatedAt: now,
        );

        when(mockRepository.createList(timestampedList))
            .thenAnswer((_) async => timestampedList);

        // Act
        final result = await usecase.call(timestampedList);

        // Assert
        expect(result.createdAt, equals(now));
        expect(result.updatedAt, equals(now));
        verify(mockRepository.createList(timestampedList)).called(1);
      });
    });

    group('Community and collaboration features', () {
      test('should create public list for community sharing', () async {
        // Arrange
        final communityList = testList.copyWith(
          title: 'Community Favorites',
          description: 'Best spots recommended by the community',
          isPublic: true,
          category: 'community',
        );

        when(mockRepository.createList(communityList))
            .thenAnswer((_) async => communityList);

        // Act
        final result = await usecase.call(communityList);

        // Assert
        expect(result.isPublic, isTrue);
        expect(result.category, equals('community'));
        expect(result.title, contains('Community'));
        verify(mockRepository.createList(communityList)).called(1);
      });

      test('should create collaborative list with initial respect count', () async {
        // Arrange
        final collaborativeList = testList.copyWith(
          title: 'Collaborative List',
          isPublic: true,
          respectCount: 5, // Initial community interest
        );

        when(mockRepository.createList(collaborativeList))
            .thenAnswer((_) async => collaborativeList);

        // Act
        final result = await usecase.call(collaborativeList);

        // Assert
        expect(result.respectCount, equals(5));
        expect(result.isPublic, isTrue);
        verify(mockRepository.createList(collaborativeList)).called(1);
      });

      test('should create curated list with verified spots', () async {
        // Arrange
        final verifiedSpots = testSpots.map((spot) => spot.copyWith(
          metadata: {'verified': true, 'curator_approved': true},
        )).toList();

        final curatedList = testList.copyWith(
          title: 'Curated Recommendations',
          spots: verifiedSpots,
          category: 'curated',
        );

        when(mockRepository.createList(curatedList))
            .thenAnswer((_) async => curatedList);

        // Act
        final result = await usecase.call(curatedList);

        // Assert
        expect(result.category, equals('curated'));
        expect(result.spots.first.metadata['verified'], isTrue);
        verify(mockRepository.createList(curatedList)).called(1);
      });
    });

    group('Different list types', () {
      test('should create personal wishlist', () async {
        // Arrange
        final wishlist = testList.copyWith(
          title: 'Places to Visit',
          description: 'My personal wishlist of places I want to explore',
          isPublic: false,
          category: 'wishlist',
        );

        when(mockRepository.createList(wishlist))
            .thenAnswer((_) async => wishlist);

        // Act
        final result = await usecase.call(wishlist);

        // Assert
        expect(result.category, equals('wishlist'));
        expect(result.isPublic, isFalse);
        expect(result.description, contains('wishlist'));
        verify(mockRepository.createList(wishlist)).called(1);
      });

      test('should create event-specific list', () async {
        // Arrange
        final eventList = testList.copyWith(
          title: 'Wedding Venues',
          description: 'Potential wedding venues we are considering',
          category: 'event',
          isPublic: false,
        );

        when(mockRepository.createList(eventList))
            .thenAnswer((_) async => eventList);

        // Act
        final result = await usecase.call(eventList);

        // Assert
        expect(result.category, equals('event'));
        expect(result.title, contains('Wedding'));
        verify(mockRepository.createList(eventList)).called(1);
      });

      test('should create themed collection', () async {
        // Arrange
        final themedList = testList.copyWith(
          title: 'Best Coffee Shops',
          description: 'Amazing coffee shops across the city',
          category: 'themed',
          isPublic: true,
        );

        when(mockRepository.createList(themedList))
            .thenAnswer((_) async => themedList);

        // Act
        final result = await usecase.call(themedList);

        // Assert
        expect(result.category, equals('themed'));
        expect(result.title, contains('Coffee'));
        expect(result.isPublic, isTrue);
        verify(mockRepository.createList(themedList)).called(1);
      });
    });
  });
}

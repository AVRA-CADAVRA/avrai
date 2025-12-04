import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/ml/user_matching.dart';
import 'package:spots/core/models/user.dart';

void main() {
  group('UserMatchingEngine', () {
    late UserMatchingEngine engine;
    late User testUser1;
    late User testUser2;
    
    setUp(() {
      engine = UserMatchingEngine();
      testUser1 = User(
        id: 'test-user-1',
        email: 'test1@example.com',
        name: 'Test User 1',
        role: UserRole.user,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      testUser2 = User(
        id: 'test-user-2',
        email: 'test2@example.com',
        name: 'Test User 2',
        role: UserRole.user,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });
    
    test('calculateUserSimilarity returns valid similarity score', () async {
      // OUR_GUTS.md: "Authenticity Over Algorithms"
      final similarity = await engine.calculateUserSimilarity(testUser1, testUser2);
      
      expect(similarity, inInclusiveRange(0.0, 1.0));
    });
    
    test('findSimilarUsers respects privacy and authenticity', () async {
      // OUR_GUTS.md: "Our suggestions are powered by your real data"
      final similarUsers = await engine.findSimilarUsers(testUser1);
      
      expect(similarUsers, isA<List<User>>());
      // Should not include the user themselves
      expect(similarUsers.any((user) => user.id == testUser1.id), isFalse);
    });
    
    test('generateCollaborativeFiltering provides authentic recommendations', () async {
      // OUR_GUTS.md: "Authenticity Over Algorithms"
      final recommendations = await engine.generateCollaborativeFiltering(testUser1);
      
      expect(recommendations, isA<List>());
      // Recommendations should be limited to reasonable number
      expect(recommendations.length, lessThanOrEqualTo(20));
    });
  });
}

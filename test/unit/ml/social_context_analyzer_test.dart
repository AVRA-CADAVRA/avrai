import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/ml/social_context_analyzer.dart';
import 'package:spots/core/models/user.dart';

void main() {
  group('SocialContextAnalyzer', () {
    late SocialContextAnalyzer analyzer;
    late User testUser;
    
    setUp(() {
      analyzer = SocialContextAnalyzer();
      testUser = User(
        id: 'test-user',
        email: 'test@example.com',
        name: 'Test User',
        role: UserRole.user,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });
    
    test('analyzeSocialBehavior maintains high privacy standards', () async {
      // OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
      final result = await analyzer.analyzeSocialBehavior(testUser);
      
      expect(result.privacyLevel, equals(PrivacyLevel.high));
      expect(result.userId, equals(testUser.id));
      expect(result.preferredGroupSize, greaterThan(0));
    });
    
    test('identifyGroupPreferences promotes community connection', () async {
      // OUR_GUTS.md: "Community, Not Just Places"
      final users = [testUser];
      final result = await analyzer.identifyGroupPreferences(users);
      
      expect(result.optimalGroupSize, greaterThan(0));
      expect(result.compatibilityScore, inInclusiveRange(0.0, 1.0));
      expect(result.sharedInterests, isNotEmpty);
    });
  });
}

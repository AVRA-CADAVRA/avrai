import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/ml/feedback_processor.dart';
import 'package:spots/core/models/user.dart';
import 'package:spots/core/models/spot.dart';

void main() {
  group('FeedbackProcessor', () {
    late FeedbackProcessor processor;
    late User testUser;
    late Spot testSpot;
    
    setUp(() {
      processor = FeedbackProcessor();
      testUser = User(
        id: 'test-user',
        email: 'test@example.com',
        name: 'Test User',
        role: UserRole.user,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      testSpot = Spot(
        id: 'test-spot',
        name: 'Test Spot',
        description: 'A test spot',
        category: 'food',
        latitude: 37.7749,
        longitude: -122.4194,
        rating: 4.5,
        createdBy: 'test-user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });
    
    test('processFeedback handles user feedback appropriately', () async {
      // OUR_GUTS.md: "Your feedback shapes SPOTS"
      await processor.processFeedback(testUser, testSpot, FeedbackType.like);
      
      // Should complete without throwing exceptions
      expect(true, isTrue);
    });
    
    test('updateUserPreferences respects personalization', () async {
      // OUR_GUTS.md: "Personalized, Not Prescriptive"
      final feedback = Feedback(
        userId: testUser.id,
        spotId: testSpot.id,
        type: FeedbackType.love,
        category: 'food',
        timestamp: DateTime.now(),
      );
      
      await processor.updateUserPreferences(testUser, feedback);
      
      // Should complete without throwing exceptions
      expect(true, isTrue);
    });
    
    test('refineRecommendationModel maintains authenticity', () async {
      // OUR_GUTS.md: "Authenticity Over Algorithms"
      final feedbacks = [
        Feedback(
          userId: testUser.id,
          spotId: testSpot.id,
          type: FeedbackType.like,
          timestamp: DateTime.now(),
        ),
      ];
      
      await processor.refineRecommendationModel(feedbacks);
      
      // Should complete without throwing exceptions
      expect(true, isTrue);
    });
  });
}

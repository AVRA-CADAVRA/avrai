import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/ml/location_pattern_analyzer.dart';
import 'package:spots/core/models/user.dart';

void main() {
  group('LocationPatternAnalyzer', () {
    late LocationPatternAnalyzer analyzer;
    late User testUser;
    
    setUp(() {
      analyzer = LocationPatternAnalyzer();
      testUser = User(
        id: 'test-user',
        email: 'test@example.com',
        name: 'Test User',
        role: UserRole.user,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });
    
    test('analyzePassiveTracking respects user privacy', () async {
      // OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
      final result = await analyzer.analyzePassiveTracking(testUser);
      
      expect(result.privacyLevel, equals(PrivacyLevel.high));
      expect(result.userId, equals(testUser.id));
    });
    
    test('calculateTimeSpentPatterns provides meaningful insights', () async {
      final result = await analyzer.calculateTimeSpentPatterns(testUser);
      
      expect(result.averageVisitDuration.inMinutes, greaterThan(0));
      expect(result.peakHours, isNotEmpty);
      expect(result.weekdayVsWeekendRatio, inInclusiveRange(0.0, 1.0));
    });
    
    test('identifyRoutineVsExploration balances comfort and discovery', () async {
      // OUR_GUTS.md: Help users find belonging while encouraging discovery
      final result = await analyzer.identifyRoutineVsExploration(testUser);
      
      expect(result.routineScore + result.explorationScore, lessThanOrEqualTo(1.0));
      expect(result.discoveryTrend, isA<DiscoveryTrend>());
    });
  });
}

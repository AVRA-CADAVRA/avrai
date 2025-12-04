import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/ml/real_time_recommendations.dart';
import 'package:spots/core/models/user.dart';
import 'package:spots/core/models/spot.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  group('RealTimeRecommendationEngine', () {
    late RealTimeRecommendationEngine engine;
    late User testUser;
    late Position testLocation;
    
    setUp(() {
      engine = RealTimeRecommendationEngine();
      testUser = User(
        id: 'test-user',
        email: 'test@example.com',
        name: 'Test User',
        role: UserRole.user,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      testLocation = Position(
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
    });
    
    test('generateContextualRecommendations provides relevant suggestions', () async {
      // OUR_GUTS.md: "Effortless, Seamless Discovery"
      final recommendations = await engine.generateContextualRecommendations(testUser, testLocation);
      
      expect(recommendations, isA<List<Spot>>());
      expect(recommendations.length, lessThanOrEqualTo(10));
    });
    
    test('generateTimeBasedRecommendations respects user rhythm', () async {
      // OUR_GUTS.md: "Your daily rhythm is known and respected"
      final currentTime = DateTime.now();
      final recommendations = await engine.generateTimeBasedRecommendations(testUser, currentTime);
      
      expect(recommendations, isA<List<Spot>>());
      expect(recommendations.length, lessThanOrEqualTo(8));
    });
    
    test('generateWeatherBasedRecommendations considers context', () async {
      // OUR_GUTS.md: "Context-aware suggestions that make sense"
      final recommendations = await engine.generateWeatherBasedRecommendations(testUser, WeatherCondition.sunny);
      
      expect(recommendations, isA<List<Spot>>());
      expect(recommendations.length, lessThanOrEqualTo(6));
    });
  });
}

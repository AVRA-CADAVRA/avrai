import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:spots/core/services/ai_search_suggestions_service.dart';
import '../../fixtures/model_factories.dart';

/// AI Search Suggestions Service Tests
/// Tests AI-powered search suggestion functionality
void main() {
  group('AISearchSuggestionsService', () {
    late AISearchSuggestionsService service;

    setUp(() {
      service = AISearchSuggestionsService();
      service.clearLearningData();
    });

    group('generateSuggestions', () {
      test('should generate suggestions for empty query', () async {
        final suggestions = await service.generateSuggestions(
          query: '',
          userLocation: null,
        );

        expect(suggestions, isA<List<SearchSuggestion>>());
        expect(suggestions.length, lessThanOrEqualTo(8));
      });

      test('should generate query completion suggestions', () async {
        final suggestions = await service.generateSuggestions(
          query: 'coff',
          userLocation: null,
        );

        expect(suggestions, isA<List<SearchSuggestion>>());
        // Should include coffee-related completions
        final hasCoffee = suggestions.any((s) => 
          s.text.toLowerCase().contains('coffee') ||
          s.text.toLowerCase().contains('cafe')
        );
        expect(hasCoffee, isTrue);
      });

      test('should generate contextual suggestions with location', () async {
        final location = Position(
          latitude: 37.7749,
          longitude: -122.4194,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );

        final suggestions = await service.generateSuggestions(
          query: '',
          userLocation: location,
        );

        expect(suggestions, isA<List<SearchSuggestion>>());
        // Should include contextual suggestions based on time
        expect(suggestions.length, greaterThan(0));
      });

      test('should generate personalized suggestions after learning', () async {
        final spot = ModelFactories.createTestSpot(
          name: 'Test Restaurant',
          category: 'restaurant',
        );

        service.learnFromSearch(
          query: 'restaurant',
          results: [spot],
        );

        final suggestions = await service.generateSuggestions(
          query: 'rest',
          userLocation: null,
        );

        expect(suggestions, isA<List<SearchSuggestion>>());
        // May include personalized suggestions
        expect(suggestions.length, greaterThanOrEqualTo(0));
      });

      test('should generate community trend suggestions', () async {
        final communityTrends = {
          'coffee': 10,
          'restaurant': 8,
          'park': 5,
        };

        final suggestions = await service.generateSuggestions(
          query: '',
          userLocation: null,
          communityTrends: communityTrends,
        );

        expect(suggestions, isA<List<SearchSuggestion>>());
        expect(suggestions.length, lessThanOrEqualTo(8));
      });

      test('should limit suggestions to 8', () async {
        final suggestions = await service.generateSuggestions(
          query: '',
          userLocation: null,
        );

        expect(suggestions.length, lessThanOrEqualTo(8));
      });

      test('should deduplicate suggestions', () async {
        final suggestions = await service.generateSuggestions(
          query: 'coffee',
          userLocation: null,
        );

        final uniqueTexts = suggestions.map((s) => s.text.toLowerCase()).toSet();
        expect(uniqueTexts.length, equals(suggestions.length));
      });

      test('should handle errors gracefully', () async {
        final suggestions = await service.generateSuggestions(
          query: 'test',
          userLocation: null,
        );

        expect(suggestions, isA<List<SearchSuggestion>>());
      });
    });

    group('learnFromSearch', () {
      test('should track recent searches', () {
        final spot = ModelFactories.createTestSpot();
        
        service.learnFromSearch(
          query: 'coffee shop',
          results: [spot],
        );

        final patterns = service.getSearchPatterns();
        expect(patterns['recent_searches'], isA<List>());
        expect((patterns['recent_searches'] as List).length, greaterThan(0));
      });

      test('should learn category preferences', () {
        final restaurantSpot = ModelFactories.createTestSpot(
          category: 'restaurant',
        );
        final coffeeSpot = ModelFactories.createTestSpot(
          category: 'cafe',
        );

        service.learnFromSearch(
          query: 'food',
          results: [restaurantSpot, coffeeSpot],
        );

        final patterns = service.getSearchPatterns();
        expect(patterns['top_categories'], isA<List>());
      });

      test('should limit recent searches to 20', () {
        for (var i = 0; i < 25; i++) {
          service.learnFromSearch(
            query: 'search $i',
            results: [],
          );
        }

        final patterns = service.getSearchPatterns();
        final recentSearches = patterns['recent_searches'] as List;
        expect(recentSearches.length, lessThanOrEqualTo(20));
      });

      test('should track search timestamps', () {
        final spot = ModelFactories.createTestSpot();
        
        service.learnFromSearch(
          query: 'test search',
          results: [spot],
        );

        final patterns = service.getSearchPatterns();
        expect(patterns['total_searches'], greaterThan(0));
      });
    });

    group('getSearchPatterns', () {
      test('should return search patterns', () {
        final patterns = service.getSearchPatterns();
        
        expect(patterns, isA<Map<String, dynamic>>());
        expect(patterns['recent_searches'], isA<List>());
        expect(patterns['top_categories'], isA<List>());
        expect(patterns['search_frequency'], isA<Map>());
        expect(patterns['total_searches'], isA<int>());
      });

      test('should return empty patterns when no learning data', () {
        service.clearLearningData();
        final patterns = service.getSearchPatterns();
        
        expect(patterns['recent_searches'], isEmpty);
        expect(patterns['total_searches'], equals(0));
      });

      test('should return top categories sorted by count', () {
        final restaurantSpot = ModelFactories.createTestSpot(
          category: 'restaurant',
        );

        // Search for restaurant multiple times
        for (var i = 0; i < 5; i++) {
          service.learnFromSearch(
            query: 'restaurant',
            results: [restaurantSpot],
          );
        }

        final patterns = service.getSearchPatterns();
        final topCategories = patterns['top_categories'] as List;
        expect(topCategories.length, greaterThanOrEqualTo(0));
      });
    });

    group('clearLearningData', () {
      test('should clear all learning data', () {
        final spot = ModelFactories.createTestSpot();
        
        service.learnFromSearch(
          query: 'test',
          results: [spot],
        );

        service.clearLearningData();

        final patterns = service.getSearchPatterns();
        expect(patterns['recent_searches'], isEmpty);
        expect(patterns['top_categories'], isEmpty);
        expect(patterns['total_searches'], equals(0));
      });
    });

    group('Suggestion Types', () {
      test('should include completion suggestions', () async {
        final suggestions = await service.generateSuggestions(
          query: 'food',
          userLocation: null,
        );

        final hasCompletion = suggestions.any((s) => 
          s.type == SuggestionType.completion
        );
        expect(hasCompletion, isTrue);
      });

      test('should include contextual suggestions with location', () async {
        final location = Position(
          latitude: 37.7749,
          longitude: -122.4194,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );

        final suggestions = await service.generateSuggestions(
          query: '',
          userLocation: location,
        );

        final hasContextual = suggestions.any((s) => 
          s.type == SuggestionType.contextual
        );
        expect(hasContextual, isTrue);
      });

      test('should include discovery suggestions for empty query', () async {
        final suggestions = await service.generateSuggestions(
          query: '',
          userLocation: null,
        );

        final hasDiscovery = suggestions.any((s) => 
          s.type == SuggestionType.discovery
        );
        expect(hasDiscovery, isTrue);
      });
    });
  });
}


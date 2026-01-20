---
name: hybrid-search-implementation
description: Guides hybrid search implementation: vector embeddings, keyword search, fusion algorithms, caching strategies. Use when implementing search, recommendation systems, or discovery features.
---

# Hybrid Search Implementation

## Core Principle

**Community-first prioritization** - Local community knowledge comes first, external data fills gaps.

## Search Flow

```
1. Search community data (highest priority)
2. Search external data (if needed)
3. Combine and rank results
4. Apply filters
5. Return ranked results
```

## Implementation Pattern

```dart
/// Hybrid Search Repository
/// 
/// Community-first search with external data fallback
class HybridSearchRepository {
  final SpotsLocalDataSource _localDataSource;
  final GooglePlacesDataSource? _externalDataSource;
  final SearchCacheService _cacheService;
  
  /// Hybrid search with community-first prioritization
  Future<HybridSearchResult> searchSpots({
    required String query,
    double? latitude,
    double? longitude,
    int maxResults = 50,
    bool includeExternal = true,
  }) async {
    // Check cache first
    final cacheKey = _generateCacheKey(query, latitude, longitude);
    final cached = await _cacheService.getCachedResult(cacheKey);
    if (cached != null) return cached;
    
    // Step 1: Search community data (highest priority)
    final communitySpots = await _localDataSource.searchSpots(query);
    
    // Step 2: Search external data if needed
    List<Spot> externalSpots = [];
    if (includeExternal && communitySpots.length < maxResults) {
      externalSpots = await _externalDataSource?.searchPlaces(
        query: query,
        location: (latitude != null && longitude != null)
            ? LatLng(latitude, longitude)
            : null,
        maxResults: maxResults - communitySpots.length,
      ) ?? [];
    }
    
    // Step 3: Combine and rank results
    final rankedResults = _rankAndDeduplicateResults(
      communitySpots: communitySpots,
      externalSpots: externalSpots,
      query: query,
      userLatitude: latitude,
      userLongitude: longitude,
    );
    
    // Step 4: Apply result limit
    final finalResults = rankedResults.take(maxResults).toList();
    
    // Step 5: Cache result
    final result = HybridSearchResult(
      spots: finalResults,
      communityCount: communitySpots.length,
      externalCount: externalSpots.length,
    );
    await _cacheService.cacheResult(cacheKey, result);
    
    return result;
  }
}
```

## Ranking Algorithm

```dart
/// Rank and deduplicate results
List<Spot> rankAndDeduplicateResults({
  required List<Spot> communitySpots,
  required List<Spot> externalSpots,
  required String query,
  double? userLatitude,
  double? userLongitude,
}) {
  // Combine spots
  final allSpots = <Spot>[...communitySpots, ...externalSpots];
  
  // Deduplicate by place ID or coordinates
  final deduplicated = _deduplicateSpots(allSpots);
  
  // Calculate relevance scores
  final scored = deduplicated.map((spot) {
    final relevance = _calculateRelevanceScore(
      spot: spot,
      query: query,
      userLatitude: userLatitude,
      userLongitude: userLongitude,
      isCommunity: communitySpots.contains(spot),
    );
    return (spot: spot, score: relevance);
  }).toList();
  
  // Sort by score (highest first)
  scored.sort((a, b) => b.score.compareTo(a.score));
  
  return scored.map((s) => s.spot).toList();
}
```

## Relevance Scoring

```dart
/// Calculate relevance score for spot
double calculateRelevanceScore({
  required Spot spot,
  required String query,
  double? userLatitude,
  double? userLongitude,
  required bool isCommunity,
}) {
  var score = 0.0;
  
  // Community boost (higher priority)
  if (isCommunity) {
    score += 1.0; // Community spots ranked higher
  }
  
  // Text relevance
  final textMatch = _calculateTextRelevance(spot, query);
  score += textMatch * 0.5;
  
  // Distance relevance (if location provided)
  if (userLatitude != null && userLongitude != null) {
    final distance = _calculateDistance(
      userLatitude,
      userLongitude,
      spot.latitude,
      spot.longitude,
    );
    final distanceScore = 1.0 / (1.0 + distance / 1000.0); // Decay with distance
    score += distanceScore * 0.3;
  }
  
  // Popularity boost (if available)
  if (spot.reviewCount != null && spot.rating != null) {
    final popularityScore = (spot.rating! / 5.0) * (spot.reviewCount! / 100.0);
    score += popularityScore * 0.2;
  }
  
  return score.clamp(0.0, 2.0);
}
```

## Caching Strategy

```dart
/// Cache search results
Future<void> cacheResult(String cacheKey, HybridSearchResult result) async {
  // Cache for 1 hour
  await _cacheService.set(
    key: cacheKey,
    value: result.toJson(),
    ttl: Duration(hours: 1),
  );
}

/// Get cached result
Future<HybridSearchResult?> getCachedResult(String cacheKey) async {
  final cached = await _cacheService.get(cacheKey);
  if (cached == null) return null;
  
  return HybridSearchResult.fromJson(cached);
}
```

## Reference

- `lib/data/repositories/hybrid_search_repository.dart`
- `lib/core/services/search_cache_service.dart`
- `lib/presentation/blocs/search/hybrid_search_bloc.dart`

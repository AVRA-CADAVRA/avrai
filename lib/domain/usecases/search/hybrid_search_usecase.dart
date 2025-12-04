import 'package:spots/data/repositories/hybrid_search_repository.dart';

/// Hybrid Search Use Case
/// OUR_GUTS.md: "Authenticity Over Algorithms" - Community data prioritized over external sources
class HybridSearchUseCase {
  final HybridSearchRepository repository;

  HybridSearchUseCase(this.repository);

  /// Search spots with hybrid approach (community + external data)
  /// OUR_GUTS.md: "Community, Not Just Places" - Local community knowledge comes first
  Future<HybridSearchResult> searchSpots({
    required String query,
    double? latitude,
    double? longitude,
    int maxResults = 50,
    bool includeExternal = true,
  }) async {
    return await repository.searchSpots(
      query: query,
      latitude: latitude,
      longitude: longitude,
      maxResults: maxResults,
      includeExternal: includeExternal,
    );
  }

  /// Search nearby spots with hybrid approach
  /// Community spots get priority even for location-based searches
  Future<HybridSearchResult> searchNearbySpots({
    required double latitude,
    required double longitude,
    int radius = 5000,
    int maxResults = 50,
    bool includeExternal = true,
  }) async {
    return await repository.searchNearbySpots(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
      maxResults: maxResults,
      includeExternal: includeExternal,
    );
  }

  /// Get search analytics for privacy-preserving insights
  /// OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
  Map<String, int> getSearchAnalytics() {
    return repository.getSearchAnalytics();
  }
}
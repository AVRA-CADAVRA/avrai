import 'package:spots/core/services/logger.dart';
import 'package:sembast/sembast.dart';
import 'package:spots/core/models/spot.dart';
import 'package:spots/data/repositories/hybrid_search_repository.dart';
import 'package:spots/data/datasources/local/sembast_database.dart';

/// Advanced Search Cache Service for Phase 4 Performance Optimization
/// OUR_GUTS.md: "Effortless, Seamless Discovery" - Fast, offline-capable search
class SearchCacheService {
  static const String _logName = 'SearchCacheService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  
  // Cache configuration
  static const Duration _shortTermExpiry = Duration(minutes: 15); // For search results
  static const Duration _mediumTermExpiry = Duration(hours: 2);   // For popular queries
  static const Duration _longTermExpiry = Duration(days: 1);      // For frequently accessed
  static const Duration _offlineExpiry = Duration(days: 7);      // For offline access
  
  // Cache stores
  static final _searchResultsStore = StoreRef<String, Map<String, dynamic>>('search_results');
  static final _popularQueriesStore = StoreRef<String, Map<String, dynamic>>('popular_queries');
  static final _userPreferencesStore = StoreRef<String, Map<String, dynamic>>('user_preferences');
  static final _offlineCacheStore = StoreRef<String, Map<String, dynamic>>('offline_cache');
  
  // In-memory cache for ultra-fast access
  final Map<String, _CacheEntry> _memoryCache = {};
  final Map<String, int> _queryPopularity = {};
  final Map<String, DateTime> _queryTimestamps = {};
  
  // Cache statistics
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _offlineHits = 0;
  
  /// Search with intelligent caching
  /// OUR_GUTS.md: "Privacy and Control Are Non-Negotiable" - Local caching preserves privacy
  Future<HybridSearchResult?> getCachedResult({
    required String query,
    double? latitude,
    double? longitude,
    int maxResults = 50,
    bool includeExternal = true,
  }) async {
    try {
      final cacheKey = _generateCacheKey(
        query: query,
        latitude: latitude,
        longitude: longitude,
        maxResults: maxResults,
        includeExternal: includeExternal,
      );
      
      // STEP 1: Check in-memory cache first (fastest)
      if (_memoryCache.containsKey(cacheKey)) {
        final entry = _memoryCache[cacheKey]!;
        if (_isEntryValid(entry)) {
          _logger.debug('Memory cache hit: $query', tag: _logName);
          _cacheHits++;
          _trackQueryPopularity(query);
          return entry.result;
        } else {
          _memoryCache.remove(cacheKey);
        }
      }
      
      // STEP 2: Check persistent cache
      final persistentResult = await _getPersistentCachedResult(cacheKey);
      if (persistentResult != null) {
        _logger.debug('Persistent cache hit: $query', tag: _logName);
        _cacheHits++;
        _trackQueryPopularity(query);
        
        // Store in memory for future quick access
        _memoryCache[cacheKey] = _CacheEntry(
          result: persistentResult,
          timestamp: DateTime.now(),
          expiry: _determineExpiry(query),
        );
        
        return persistentResult;
      }
      
      // STEP 3: Check offline cache as last resort
      final offlineResult = await _getOfflineCachedResult(cacheKey);
      if (offlineResult != null) {
        _logger.debug('Offline cache hit: $query', tag: _logName);
        _offlineHits++;
        _trackQueryPopularity(query);
        return offlineResult;
      }
      
      _cacheMisses++;
      return null;
    } catch (e) {
      _logger.error('Error getting cached result', error: e, tag: _logName);
      return null;
    }
  }
  
  /// Cache search result with intelligent expiry
  Future<void> cacheResult({
    required String query,
    double? latitude,
    double? longitude,
    int maxResults = 50,
    bool includeExternal = true,
    required HybridSearchResult result,
  }) async {
    try {
      final cacheKey = _generateCacheKey(
        query: query,
        latitude: latitude,
        longitude: longitude,
        maxResults: maxResults,
        includeExternal: includeExternal,
      );
      
      final expiry = _determineExpiry(query);
      
      // Store in memory cache
      _memoryCache[cacheKey] = _CacheEntry(
        result: result,
        timestamp: DateTime.now(),
        expiry: expiry,
      );
      
      // Store in persistent cache
      await _storePersistentResult(cacheKey, result, expiry);
      
      // Store in offline cache if community-heavy (better for offline)
      if (result.isPrimarilyCommunityDriven) {
        await _storeOfflineResult(cacheKey, result);
      }
      
      _trackQueryPopularity(query);
      _cleanupOldEntries();
      _logger.info('Cached result for: $query (expiry: ${expiry.inMinutes}min)', tag: _logName);
    } catch (e) {
      _logger.error('Error caching result', error: e, tag: _logName);
    }
  }
  
  /// Prefetch popular searches for better performance
  /// OUR_GUTS.md: "Effortless, Seamless Discovery" - Anticipate user needs
  Future<void> prefetchPopularSearches({
    required Future<HybridSearchResult> Function(String) searchFunction,
  }) async {
    try {
      final popularQueries = await _getPopularQueries();
      
      for (final query in popularQueries.take(5)) { // Prefetch top 5
        final cached = await getCachedResult(query: query);
        if (cached == null) {
          _logger.debug('Prefetching: $query', tag: _logName);
          final result = await searchFunction(query);
          await cacheResult(query: query, result: result);
        }
      }
    } catch (e) {
      _logger.error('Error prefetching searches', error: e, tag: _logName);
    }
  }
  
  /// Warm cache with location-based searches
  Future<void> warmLocationCache({
    required double latitude,
    required double longitude,
    required Future<HybridSearchResult> Function(double, double) nearbySearchFunction,
  }) async {
    try {
      _logger.debug('Warming location cache: $latitude,$longitude', tag: _logName);
      
      final cacheKey = _generateCacheKey(
        query: 'nearby',
        latitude: latitude,
        longitude: longitude,
      );
      
      final cached = await getCachedResult(
        query: 'nearby',
        latitude: latitude,
        longitude: longitude,
      );
      
      if (cached == null) {
        final result = await nearbySearchFunction(latitude, longitude);
        await cacheResult(
          query: 'nearby',
          latitude: latitude,
          longitude: longitude,
          result: result,
        );
      }
    } catch (e) {
      _logger.error('Error warming location cache', error: e, tag: _logName);
    }
  }
  
  /// Get cache statistics for analytics
  Map<String, dynamic> getCacheStatistics() {
    final totalRequests = _cacheHits + _cacheMisses;
    final hitRate = totalRequests > 0 ? (_cacheHits / totalRequests) * 100 : 0.0;
    
    return {
      'cache_hits': _cacheHits,
      'cache_misses': _cacheMisses,
      'offline_hits': _offlineHits,
      'hit_rate_percent': hitRate.toStringAsFixed(1),
      'memory_cache_size': _memoryCache.length,
      'popular_queries': _queryPopularity.length,
      'total_requests': totalRequests,
    };
  }
  
  /// Clear cache (respecting privacy)
  Future<void> clearCache({bool preserveOffline = true}) async {
    try {
      _memoryCache.clear();
      _queryPopularity.clear();
      _queryTimestamps.clear();
      
      final db = await SembastDatabase.database;
      await _searchResultsStore.delete(db);
      await _popularQueriesStore.delete(db);
      
      if (!preserveOffline) {
        await _offlineCacheStore.delete(db);
      }
      
      _cacheHits = 0;
      _cacheMisses = 0;
      _offlineHits = 0;
      
      _logger.info('Cache cleared (offline preserved: $preserveOffline)', tag: _logName);
    } catch (e) {
      _logger.error('Error clearing cache', error: e, tag: _logName);
    }
  }

  /// Legacy maintenance hook for tests
  Future<void> performMaintenance() async {
    _cleanupOldEntries();
  }
  
  // Private helper methods
  
  String _generateCacheKey({
    required String query,
    double? latitude,
    double? longitude,
    int maxResults = 50,
    bool includeExternal = true,
  }) {
    final location = latitude != null && longitude != null 
        ? '${latitude.toStringAsFixed(3)},${longitude.toStringAsFixed(3)}'
        : 'no_location';
    return '${query.toLowerCase()}_${location}_${maxResults}_$includeExternal';
  }
  
  Duration _determineExpiry(String query) {
    final popularity = _queryPopularity[query.toLowerCase()] ?? 0;
    
    if (popularity >= 10) return _longTermExpiry;    // Very popular
    if (popularity >= 5) return _mediumTermExpiry;   // Popular
    return _shortTermExpiry;                         // Regular
  }
  
  void _trackQueryPopularity(String query) {
    final normalizedQuery = query.toLowerCase().trim();
    _queryPopularity[normalizedQuery] = (_queryPopularity[normalizedQuery] ?? 0) + 1;
    _queryTimestamps[normalizedQuery] = DateTime.now();
  }
  
  bool _isEntryValid(_CacheEntry entry) {
    return DateTime.now().isBefore(entry.timestamp.add(entry.expiry));
  }
  
  Future<HybridSearchResult?> _getPersistentCachedResult(String cacheKey) async {
    try {
      final db = await SembastDatabase.database;
      final record = await _searchResultsStore.record(cacheKey).get(db);
      
      if (record != null) {
        final expiry = DateTime.parse(record['expiry']);
        if (DateTime.now().isBefore(expiry)) {
          return _deserializeResult(record['result']);
        } else {
          // Clean up expired entry
          await _searchResultsStore.record(cacheKey).delete(db);
        }
      }
      return null;
    } catch (e) {
      _logger.error('Error getting persistent cache', error: e, tag: _logName);
      return null;
    }
  }
  
  Future<HybridSearchResult?> _getOfflineCachedResult(String cacheKey) async {
    try {
      final db = await SembastDatabase.database;
      final record = await _offlineCacheStore.record(cacheKey).get(db);
      
      if (record != null) {
        final expiry = DateTime.parse(record['expiry']);
        if (DateTime.now().isBefore(expiry)) {
          return _deserializeResult(record['result']);
        } else {
          await _offlineCacheStore.record(cacheKey).delete(db);
        }
      }
      return null;
    } catch (e) {
      _logger.error('Error getting offline cache', error: e, tag: _logName);
      return null;
    }
  }
  
  Future<void> _storePersistentResult(String cacheKey, HybridSearchResult result, Duration expiry) async {
    try {
      final db = await SembastDatabase.database;
      await _searchResultsStore.record(cacheKey).put(db, {
        'result': _serializeResult(result),
        'expiry': DateTime.now().add(expiry).toIso8601String(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logger.error('Error storing persistent result', error: e, tag: _logName);
    }
  }
  
  Future<void> _storeOfflineResult(String cacheKey, HybridSearchResult result) async {
    try {
      final db = await SembastDatabase.database;
      await _offlineCacheStore.record(cacheKey).put(db, {
        'result': _serializeResult(result),
        'expiry': DateTime.now().add(_offlineExpiry).toIso8601String(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logger.error('Error storing offline result', error: e, tag: _logName);
    }
  }
  
  Future<List<String>> _getPopularQueries() async {
    try {
      final sortedQueries = _queryPopularity.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return sortedQueries.map((e) => e.key).toList();
    } catch (e) {
      _logger.error('Error getting popular queries', error: e, tag: _logName);
      return [];
    }
  }
  
  void _cleanupOldEntries() {
    // Clean up memory cache
    _memoryCache.removeWhere((key, entry) => !_isEntryValid(entry));
    
    // Clean up old query timestamps (keep last 7 days)
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    _queryTimestamps.removeWhere((query, timestamp) => timestamp.isBefore(cutoff));
    _queryPopularity.removeWhere((query, count) => !_queryTimestamps.containsKey(query));
  }
  
  Map<String, dynamic> _serializeResult(HybridSearchResult result) {
    return {
      'spots': result.spots.map((spot) => spot.toJson()).toList(),
      'community_count': result.communityCount,
      'external_count': result.externalCount,
      'total_count': result.totalCount,
      'search_duration_ms': result.searchDuration.inMilliseconds,
      'sources': result.sources,
    };
  }
  
  HybridSearchResult _deserializeResult(Map<String, dynamic> data) {
    return HybridSearchResult(
      spots: (data['spots'] as List).map((spot) => Spot.fromJson(spot)).toList(),
      communityCount: data['community_count'],
      externalCount: data['external_count'],
      totalCount: data['total_count'],
      searchDuration: Duration(milliseconds: data['search_duration_ms']),
      sources: Map<String, int>.from(data['sources']),
    );
  }
}

/// Cache entry for in-memory storage
class _CacheEntry {
  final HybridSearchResult result;
  final DateTime timestamp;
  final Duration expiry;
  
  _CacheEntry({
    required this.result,
    required this.timestamp,
    required this.expiry,
  });
}
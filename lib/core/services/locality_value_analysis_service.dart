import 'package:spots/core/services/logger.dart';

/// Locality Value Analysis Service
/// 
/// Analyzes what users interact with most in each locality to determine
/// locality-specific values and preferences. This enables dynamic thresholds
/// that adapt to what each locality actually values.
/// 
/// **Philosophy:** Local experts shouldn't have to expand past their locality
/// to be qualified. Thresholds adapt to what the locality actually values.
/// 
/// **What This Tracks:**
/// - Events hosted (frequency, success rate)
/// - Lists created (popularity, respects)
/// - Reviews written (quality, peer endorsements)
/// - Event attendance (engagement, return rate)
/// - Professional background (credentials, experience)
/// - Positive activity trends (category + locality)
/// 
/// **How This Works:**
/// - Tracks all user activities in each locality
/// - Calculates weights for different activities based on interaction frequency
/// - Stores locality value data for threshold calculation
/// - Updates dynamically as locality behavior changes
class LocalityValueAnalysisService {
  static const String _logName = 'LocalityValueAnalysisService';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  // In-memory storage for locality value data (in production, use database)
  // Performance optimization: Cache with TTL to prevent stale data
  final Map<String, LocalityValueData> _localityValues = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheTTL = Duration(hours: 1); // Cache for 1 hour
  static const int _maxCacheSize = 500; // Limit cache size to prevent memory issues

  /// Analyze what a locality values most
  /// 
  /// Analyzes user interactions in a locality to determine which activities
  /// are most valued by the community.
  /// 
  /// **Parameters:**
  /// - `locality`: Locality name to analyze
  /// 
  /// **Returns:**
  /// LocalityValueData with activity weights and preferences
  /// 
  /// **Note:** In production, this would query database for all activities
  /// in the locality and calculate weights based on frequency and engagement.
  Future<LocalityValueData> analyzeLocalityValues(String locality) async {
    try {
      _logger.info('Analyzing locality values: $locality', tag: _logName);

      // Performance optimization: Check cache with TTL validation
      if (_localityValues.containsKey(locality)) {
        final cachedTimestamp = _cacheTimestamps[locality];
        if (cachedTimestamp != null && 
            DateTime.now().difference(cachedTimestamp) < _cacheTTL) {
          _logger.debug('Returning cached locality values: $locality', tag: _logName);
          return _localityValues[locality]!;
        } else {
          // Cache expired, remove it
          _localityValues.remove(locality);
          _cacheTimestamps.remove(locality);
        }
      }
      
      // Enforce cache size limit
      if (_localityValues.length >= _maxCacheSize) {
        _evictOldestCacheEntry();
      }

      // In production, query database for:
      // - All events hosted in locality
      // - All lists created in locality
      // - All reviews written in locality
      // - All event attendance in locality
      // - All professional backgrounds in locality
      // - Activity trends over time

      // For now, calculate from in-memory data or return default
      final valueData = _calculateLocalityValues(locality);

      // Cache the result with timestamp
      _localityValues[locality] = valueData;
      _cacheTimestamps[locality] = DateTime.now();

      _logger.info(
        'Analyzed locality values for $locality',
        tag: _logName,
      );

      return valueData;
    } catch (e, stackTrace) {
      _logger.error(
        'Error analyzing locality values: $locality',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
      // Return default values on error
      return LocalityValueData.defaultValues(locality);
    }
  }

  /// Get activity weights for a locality
  /// 
  /// Returns the weights for different activities based on what the locality
  /// values most. Higher weight = activity is more valued by locality.
  /// 
  /// **Parameters:**
  /// - `locality`: Locality name
  /// 
  /// **Returns:**
  /// Map of activity type to weight (0.0 to 1.0)
  /// 
  /// **Activity Types:**
  /// - `events_hosted`: Weight for hosting events
  /// - `lists_created`: Weight for creating lists
  /// - `reviews_written`: Weight for writing reviews
  /// - `event_attendance`: Weight for attending events
  /// - `professional_background`: Weight for professional credentials
  /// - `positive_trends`: Weight for positive activity trends
  Future<Map<String, double>> getActivityWeights(String locality) async {
    try {
      final valueData = await analyzeLocalityValues(locality);
      return valueData.activityWeights;
    } catch (e) {
      _logger.error(
        'Error getting activity weights',
        error: e,
        tag: _logName,
      );
      // Return equal weights on error
      return LocalityValueData.defaultWeights();
    }
  }

  /// Record activity in a locality
  /// 
  /// Records a user activity in a locality to update locality value analysis.
  /// 
  /// **Parameters:**
  /// - `locality`: Locality where activity occurred
  /// - `activityType`: Type of activity (events_hosted, lists_created, etc.)
  /// - `category`: Category of activity (optional)
  /// - `engagement`: Engagement level (optional, for weighting)
  /// 
  /// **Note:** In production, this would update database and trigger
  /// recalculation of locality values.
  Future<void> recordActivity({
    required String locality,
    required String activityType,
    String? category,
    double? engagement,
  }) async {
    try {
      _logger.info(
        'Recording activity: locality=$locality, type=$activityType',
        tag: _logName,
      );

      // In production, save to database
      // For now, update in-memory data
      if (_localityValues.containsKey(locality)) {
        final valueData = _localityValues[locality]!;
        valueData.recordActivity(activityType, engagement ?? 1.0);
        // Trigger recalculation
        _localityValues[locality] = _calculateLocalityValues(locality);
      } else {
        // Initialize if not exists
        await analyzeLocalityValues(locality);
      }
    } catch (e) {
      _logger.error(
        'Error recording activity',
        error: e,
        tag: _logName,
      );
    }
  }

  /// Get locality preferences for a category
  /// 
  /// Returns what activities are most valued in a locality for a specific category.
  /// 
  /// **Parameters:**
  /// - `locality`: Locality name
  /// - `category`: Category to check
  /// 
  /// **Returns:**
  /// Map of activity type to weight for this category
  Future<Map<String, double>> getCategoryPreferences(
    String locality,
    String category,
  ) async {
    try {
      final valueData = await analyzeLocalityValues(locality);
      return valueData.getCategoryPreferences(category);
    } catch (e) {
      _logger.error(
        'Error getting category preferences',
        error: e,
        tag: _logName,
      );
      return LocalityValueData.defaultWeights();
    }
  }

  // Private helper methods

  /// Calculate locality values from activity data
  /// 
  /// **Note:** In production, this would query database and calculate
  /// based on actual activity data. For now, returns default or cached values.
  LocalityValueData _calculateLocalityValues(String locality) {
    // In production, would:
    // 1. Query all events hosted in locality
    // 2. Query all lists created in locality
    // 3. Query all reviews written in locality
    // 4. Query all event attendance in locality
    // 5. Calculate weights based on frequency and engagement
    // 6. Normalize weights to sum to 1.0

    // For now, return default values
    // In production, this would be calculated from actual data
    return LocalityValueData.defaultValues(locality);
  }
  
  /// Performance optimization: Evict oldest cache entry when cache is full
  void _evictOldestCacheEntry() {
    if (_cacheTimestamps.isEmpty) return;
    
    // Find oldest entry
    String? oldestKey;
    DateTime? oldestTime;
    
    _cacheTimestamps.forEach((key, timestamp) {
      if (oldestTime == null || timestamp.isBefore(oldestTime!)) {
        oldestTime = timestamp;
        oldestKey = key;
      }
    });
    
    if (oldestKey != null) {
      _localityValues.remove(oldestKey);
      _cacheTimestamps.remove(oldestKey);
      _logger.debug('Evicted oldest cache entry: $oldestKey', tag: _logName);
    }
  }
}

/// Locality Value Data
/// 
/// Stores analyzed values and preferences for a locality.
class LocalityValueData {
  final String locality;
  final Map<String, double> activityWeights;
  final Map<String, Map<String, double>> categoryPreferences;
  final Map<String, int> activityCounts;
  final DateTime lastUpdated;

  LocalityValueData({
    required this.locality,
    required this.activityWeights,
    required this.categoryPreferences,
    required this.activityCounts,
    required this.lastUpdated,
  });

  /// Create default values for a locality
  /// 
  /// Returns equal weights for all activities (neutral starting point).
  factory LocalityValueData.defaultValues(String locality) {
    return LocalityValueData(
      locality: locality,
      activityWeights: defaultWeights(),
      categoryPreferences: {},
      activityCounts: {},
      lastUpdated: DateTime.now(),
    );
  }

  /// Get default activity weights (equal weights)
  static Map<String, double> defaultWeights() {
    return {
      'events_hosted': 0.20,
      'lists_created': 0.20,
      'reviews_written': 0.20,
      'event_attendance': 0.15,
      'professional_background': 0.15,
      'positive_trends': 0.10,
    };
  }

  /// Record an activity
  void recordActivity(String activityType, double engagement) {
    activityCounts[activityType] = (activityCounts[activityType] ?? 0) + 1;
    // In production, would recalculate weights based on new activity
  }

  /// Get category preferences
  /// 
  /// Returns activity weights adjusted for category-specific preferences.
  Map<String, double> getCategoryPreferences(String category) {
    // Check if we have category-specific preferences
    if (categoryPreferences.containsKey(category)) {
      return categoryPreferences[category]!;
    }
    // Return default weights if no category-specific data
    return activityWeights;
  }

  /// Normalize weights to sum to 1.0
  void normalizeWeights() {
    final total = activityWeights.values.fold(0.0, (a, b) => a + b);
    if (total > 0) {
      for (final key in activityWeights.keys.toList()) {
        activityWeights[key] = activityWeights[key]! / total;
      }
    }
  }
}


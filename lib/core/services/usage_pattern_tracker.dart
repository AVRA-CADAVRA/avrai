import 'package:spots/core/services/storage_service.dart' show SharedPreferencesCompat;
import 'dart:convert';
import 'package:spots/core/models/usage_pattern.dart';
import 'package:spots/core/services/logger.dart';

/// OUR_GUTS.md: "Always Learning With You"
/// Tracks how users engage with SPOTS to adapt AI behavior
/// Philosophy: The key adapts to YOUR usage style
class UsagePatternTracker {
  static const String _logName = 'UsagePatternTracker';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );
  static const String _storageKey = 'usage_pattern_';
  
  final SharedPreferencesCompat _prefs;
  
  UsagePatternTracker(this._prefs);
  
  /// Get usage pattern for user
  Future<UsagePattern> getUsagePattern(String userId) async {
    try {
      final key = '$_storageKey$userId';
      final jsonString = _prefs.getString(key);
      
      if (jsonString == null) {
        // Create new pattern
        return UsagePattern(
          userId: userId,
          firstUsed: DateTime.now(),
          lastUpdated: DateTime.now(),
        );
      }
      
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return UsagePattern.fromJson(json);
    } catch (e, stackTrace) {
      _logger.error(
        'Error loading usage pattern: $userId',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
      return UsagePattern(
        userId: userId,
        firstUsed: DateTime.now(),
        lastUpdated: DateTime.now(),
      );
    }
  }
  
  /// Save usage pattern
  Future<void> _saveUsagePattern(UsagePattern pattern) async {
    try {
      final key = '$_storageKey${pattern.userId}';
      final jsonString = jsonEncode(pattern.toJson());
      await _prefs.setString(key, jsonString);
    } catch (e, stackTrace) {
      _logger.error(
        'Error saving usage pattern: ${pattern.userId}',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
    }
  }
  
  /// Track spot visit
  Future<void> trackSpotVisit(
    String userId, {
    required bool isNewSpot,
    String? context,
  }) async {
    final pattern = await getUsagePattern(userId);
    
    // Update metrics
    final newSpotVisits = pattern.totalSpotVisits + 1;
    
    // Update loyalty: returning to favorites vs exploring new
    final loyaltyShift = isNewSpot ? -0.02 : 0.02;
    final newLoyalty = (pattern.spotLoyalty + loyaltyShift).clamp(0.0, 1.0);
    
    // Update recommendation focus (spot visits indicate recommendation usage)
    final focusShift = 0.01;
    final newRecommendationFocus = (pattern.recommendationFocus + focusShift).clamp(0.0, 1.0);
    final newCommunityFocus = (pattern.communityFocus - focusShift / 2).clamp(0.0, 1.0);
    
    // Update receptivity by context
    final newReceptivity = Map<String, double>.from(pattern.receptivityByContext);
    if (context != null) {
      newReceptivity[context] = ((newReceptivity[context] ?? 0.5) + 0.05).clamp(0.0, 1.0);
    }
    
    // Update receptivity by time
    final timeOfDay = _getTimeOfDay();
    final newTimeReceptivity = Map<String, double>.from(pattern.receptivityByTime);
    newTimeReceptivity[timeOfDay] = ((newTimeReceptivity[timeOfDay] ?? 0.5) + 0.05).clamp(0.0, 1.0);
    
    // Update door tracking
    final newOpenedDoors = Set<String>.from(pattern.openedDoorTypes);
    newOpenedDoors.add('spots');
    final newDoorFrequency = Map<String, int>.from(pattern.doorTypeFrequency);
    newDoorFrequency['spots'] = (newDoorFrequency['spots'] ?? 0) + 1;
    
    // Save updated pattern
    final updated = pattern.copyWith(
      totalSpotVisits: newSpotVisits,
      spotLoyalty: newLoyalty,
      recommendationFocus: newRecommendationFocus,
      communityFocus: newCommunityFocus,
      receptivityByContext: newReceptivity,
      receptivityByTime: newTimeReceptivity,
      openedDoorTypes: newOpenedDoors.toList(),
      doorTypeFrequency: newDoorFrequency,
      lastUpdated: DateTime.now(),
      updateCount: pattern.updateCount + 1,
    );
    
    await _saveUsagePattern(updated);
    
    _logger.debug(
      'Spot visit tracked: ${pattern.primaryMode} -> ${updated.primaryMode}',
      tag: _logName,
    );
  }
  
  /// Track event attendance
  Future<void> trackEventAttendance(
    String userId, {
    required String eventType,
    String? context,
  }) async {
    final pattern = await getUsagePattern(userId);
    
    // Update metrics
    final newEventsAttended = pattern.totalEventsAttended + 1;
    
    // Update event engagement (events attended / days active)
    final newEngagement = (newEventsAttended / (pattern.daysActive + 1)).clamp(0.0, 1.0);
    
    // Update community focus (events indicate community engagement)
    final focusShift = 0.02;
    final newCommunityFocus = (pattern.communityFocus + focusShift).clamp(0.0, 1.0);
    final newRecommendationFocus = (pattern.recommendationFocus - focusShift / 2).clamp(0.0, 1.0);
    
    // Update receptivity
    final newReceptivity = Map<String, double>.from(pattern.receptivityByContext);
    if (context != null) {
      newReceptivity[context] = ((newReceptivity[context] ?? 0.5) + 0.05).clamp(0.0, 1.0);
    }
    
    // Update time receptivity
    final timeOfDay = _getTimeOfDay();
    final newTimeReceptivity = Map<String, double>.from(pattern.receptivityByTime);
    newTimeReceptivity[timeOfDay] = ((newTimeReceptivity[timeOfDay] ?? 0.5) + 0.05).clamp(0.0, 1.0);
    
    // Update door tracking
    final newOpenedDoors = Set<String>.from(pattern.openedDoorTypes);
    newOpenedDoors.add('events');
    final newDoorFrequency = Map<String, int>.from(pattern.doorTypeFrequency);
    newDoorFrequency['events'] = (newDoorFrequency['events'] ?? 0) + 1;
    
    // Save updated pattern
    final updated = pattern.copyWith(
      totalEventsAttended: newEventsAttended,
      eventEngagement: newEngagement,
      communityFocus: newCommunityFocus,
      recommendationFocus: newRecommendationFocus,
      receptivityByContext: newReceptivity,
      receptivityByTime: newTimeReceptivity,
      openedDoorTypes: newOpenedDoors.toList(),
      doorTypeFrequency: newDoorFrequency,
      lastUpdated: DateTime.now(),
      updateCount: pattern.updateCount + 1,
    );
    
    await _saveUsagePattern(updated);
    
    _logger.debug(
      'Event attendance tracked: ${pattern.primaryMode} -> ${updated.primaryMode}',
      tag: _logName,
    );
  }
  
  /// Track community join
  Future<void> trackCommunityJoin(
    String userId, {
    String? context,
  }) async {
    final pattern = await getUsagePattern(userId);
    
    // Update metrics
    final newCommunitiesJoined = pattern.totalCommunitiesJoined + 1;
    
    // Update community focus (strong signal)
    final focusShift = 0.03;
    final newCommunityFocus = (pattern.communityFocus + focusShift).clamp(0.0, 1.0);
    final newRecommendationFocus = (pattern.recommendationFocus - focusShift / 2).clamp(0.0, 1.0);
    
    // Update door tracking
    final newOpenedDoors = Set<String>.from(pattern.openedDoorTypes);
    newOpenedDoors.add('communities');
    final newDoorFrequency = Map<String, int>.from(pattern.doorTypeFrequency);
    newDoorFrequency['communities'] = (newDoorFrequency['communities'] ?? 0) + 1;
    
    // Save updated pattern
    final updated = pattern.copyWith(
      totalCommunitiesJoined: newCommunitiesJoined,
      communityFocus: newCommunityFocus,
      recommendationFocus: newRecommendationFocus,
      openedDoorTypes: newOpenedDoors.toList(),
      doorTypeFrequency: newDoorFrequency,
      lastUpdated: DateTime.now(),
      updateCount: pattern.updateCount + 1,
    );
    
    await _saveUsagePattern(updated);
    
    _logger.debug(
      'Community join tracked: ${pattern.primaryMode} -> ${updated.primaryMode}',
      tag: _logName,
    );
  }
  
  /// Track quick recommendation usage
  Future<void> trackQuickRecommendation(
    String userId, {
    String? context,
  }) async {
    final pattern = await getUsagePattern(userId);
    
    // Update recommendation focus
    final focusShift = 0.01;
    final newRecommendationFocus = (pattern.recommendationFocus + focusShift).clamp(0.0, 1.0);
    final newCommunityFocus = (pattern.communityFocus - focusShift / 2).clamp(0.0, 1.0);
    
    // Update receptivity
    final newReceptivity = Map<String, double>.from(pattern.receptivityByContext);
    if (context != null) {
      newReceptivity[context] = ((newReceptivity[context] ?? 0.5) + 0.03).clamp(0.0, 1.0);
    }
    
    // Update time receptivity
    final timeOfDay = _getTimeOfDay();
    final newTimeReceptivity = Map<String, double>.from(pattern.receptivityByTime);
    newTimeReceptivity[timeOfDay] = ((newTimeReceptivity[timeOfDay] ?? 0.5) + 0.03).clamp(0.0, 1.0);
    
    // Save updated pattern
    final updated = pattern.copyWith(
      recommendationFocus: newRecommendationFocus,
      communityFocus: newCommunityFocus,
      receptivityByContext: newReceptivity,
      receptivityByTime: newTimeReceptivity,
      lastUpdated: DateTime.now(),
      updateCount: pattern.updateCount + 1,
    );
    
    await _saveUsagePattern(updated);
  }
  
  /// Update days active
  Future<void> updateDaysActive(String userId) async {
    final pattern = await getUsagePattern(userId);
    final lastActive = pattern.lastUpdated;
    final now = DateTime.now();
    
    // Check if it's a new day
    if (now.day != lastActive.day || now.month != lastActive.month || now.year != lastActive.year) {
      final updated = pattern.copyWith(
        daysActive: pattern.daysActive + 1,
        lastUpdated: now,
      );
      await _saveUsagePattern(updated);
    }
  }
  
  /// Check if user is receptive to suggestions right now
  Future<bool> isReceptiveNow(String userId, String context) async {
    final pattern = await getUsagePattern(userId);
    return pattern.isReceptiveNow(context);
  }
  
  /// Get recommended content type for user right now
  Future<String> getRecommendedContentType(String userId) async {
    final pattern = await getUsagePattern(userId);
    
    switch (pattern.primaryMode) {
      case UsageMode.recommendations:
        return 'quick_recommendations';
      case UsageMode.community:
        return 'community_discovery';
      case UsageMode.events:
        return 'event_suggestions';
      case UsageMode.balanced:
        return 'mixed_content';
    }
  }
  
  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'night';
    if (hour < 12) return 'morning';
    if (hour < 18) return 'afternoon';
    if (hour < 22) return 'evening';
    return 'night';
  }
}


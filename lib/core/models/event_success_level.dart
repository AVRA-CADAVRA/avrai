/// Event Success Level Enum
/// 
/// Represents the overall success level of an event based on
/// attendance, financial, and quality metrics.
/// 
/// **Success Levels:**
/// - `low`: Event underperformed across multiple metrics
/// - `medium`: Event met basic expectations
/// - `high`: Event exceeded expectations
/// - `exceptional`: Event exceeded expectations significantly
enum EventSuccessLevel {
  low,
  medium,
  high,
  exceptional;

  /// Get display name for success level
  String get displayName {
    switch (this) {
      case EventSuccessLevel.low:
        return 'Low';
      case EventSuccessLevel.medium:
        return 'Medium';
      case EventSuccessLevel.high:
        return 'High';
      case EventSuccessLevel.exceptional:
        return 'Exceptional';
    }
  }

  /// Get description for success level
  String get description {
    switch (this) {
      case EventSuccessLevel.low:
        return 'Event underperformed. Significant improvements needed.';
      case EventSuccessLevel.medium:
        return 'Event met basic expectations. Some areas for improvement.';
      case EventSuccessLevel.high:
        return 'Event exceeded expectations. Well-executed event.';
      case EventSuccessLevel.exceptional:
        return 'Event exceeded expectations significantly. Outstanding performance.';
    }
  }

  /// Get emoji for success level
  String get emoji {
    switch (this) {
      case EventSuccessLevel.low:
        return '📉';
      case EventSuccessLevel.medium:
        return '📊';
      case EventSuccessLevel.high:
        return '📈';
      case EventSuccessLevel.exceptional:
        return '🌟';
    }
  }

  /// Determine success level from overall score (0-100)
  static EventSuccessLevel fromScore(double score) {
    if (score >= 90) return EventSuccessLevel.exceptional;
    if (score >= 75) return EventSuccessLevel.high;
    if (score >= 60) return EventSuccessLevel.medium;
    return EventSuccessLevel.low;
  }

  /// Determine success level from metrics
  static EventSuccessLevel fromMetrics({
    required double attendanceRate,
    required double revenueTargetMet,
    required double averageRating,
  }) {
    // Weighted score calculation
    final attendanceWeight = 0.2;
    final revenueWeight = 0.3;
    final qualityWeight = 0.5;
    
    final overallScore = (attendanceRate * attendanceWeight) +
        (revenueTargetMet * revenueWeight) +
        ((averageRating / 5.0 * 100) * qualityWeight);
    
    return fromScore(overallScore);
  }

  /// Convert to string for JSON serialization
  String toJson() => name;

  /// Create from string (for JSON deserialization)
  static EventSuccessLevel fromJson(String value) {
    return EventSuccessLevel.values.firstWhere(
      (level) => level.name == value,
      orElse: () => EventSuccessLevel.medium,
    );
  }
}


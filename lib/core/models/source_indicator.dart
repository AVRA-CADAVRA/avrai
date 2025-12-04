import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';

/// Source Indicator for transparent data source visualization
/// OUR_GUTS.md: "Privacy and Control Are Non-Negotiable" - Users must know data sources
class SourceIndicator {
  final SourceType type;
  final String sourceName;
  final DateTime lastUpdated;
  final TrustLevel trustLevel;
  final bool isVerified;
  final bool isCommunityContributed;
  final DataQualityMetrics qualityMetrics;
  final Color badgeColor;
  final IconData badgeIcon;
  final String displayText;

  SourceIndicator({
    required this.type,
    required this.sourceName,
    required this.lastUpdated,
    required this.trustLevel,
    required this.isVerified,
    required this.isCommunityContributed,
    required this.qualityMetrics,
    required this.badgeColor,
    required this.badgeIcon,
    required this.displayText,
  });

  /// Create source indicator from spot metadata
  factory SourceIndicator.fromSpotMetadata(Map<String, dynamic> metadata) {
    final source = metadata['source']?.toString() ?? 'community';
    final isExternal = metadata['is_external'] == true;
    final isCommunityData = metadata['is_community_data'] == true;
    
    switch (source) {
      case 'google_places':
        return SourceIndicator._googlePlaces(metadata);
      case 'openstreetmap':
        return SourceIndicator._openStreetMap(metadata);
      case 'community':
      default:
        return SourceIndicator._community(metadata);
    }
  }

  /// Community data source indicator
  factory SourceIndicator._community(Map<String, dynamic> metadata) {
    return SourceIndicator(
      type: SourceType.community,
      sourceName: 'Community',
      lastUpdated: DateTime.now(), // Would be parsed from metadata in real app
      trustLevel: TrustLevel.high,
      isVerified: true,
      isCommunityContributed: true,
      qualityMetrics: DataQualityMetrics.fromCommunityData(metadata),
      badgeColor: AppColors.electricGreen,
      badgeIcon: Icons.people,
      displayText: 'Community Verified',
    );
  }

  /// Google Places source indicator
  factory SourceIndicator._googlePlaces(Map<String, dynamic> metadata) {
    return SourceIndicator(
      type: SourceType.googlePlaces,
      sourceName: 'Google Places',
      lastUpdated: DateTime.now(),
      trustLevel: TrustLevel.medium,
      isVerified: false,
      isCommunityContributed: false,
      qualityMetrics: DataQualityMetrics.fromGooglePlaces(metadata),
      badgeColor: AppColors.electricGreen,
      badgeIcon: Icons.business,
      displayText: 'External Data',
    );
  }

  /// OpenStreetMap source indicator
  factory SourceIndicator._openStreetMap(Map<String, dynamic> metadata) {
    return SourceIndicator(
      type: SourceType.openStreetMap,
      sourceName: 'OpenStreetMap',
      lastUpdated: DateTime.now(),
      trustLevel: TrustLevel.high, // Community-driven like our own data
      isVerified: false,
      isCommunityContributed: true, // OSM is community-contributed
      qualityMetrics: DataQualityMetrics.fromOpenStreetMap(metadata),
      badgeColor: AppColors.warning,
      badgeIcon: Icons.map,
      displayText: 'Community Map Data',
    );
  }

  /// Get data freshness indicator
  DataFreshness get freshness {
    final age = DateTime.now().difference(lastUpdated);
    
    if (age.inDays < 1) return DataFreshness.fresh;
    if (age.inDays < 7) return DataFreshness.recent;
    if (age.inDays < 30) return DataFreshness.stale;
    return DataFreshness.outdated;
  }

  /// Get warning level for external data
  WarningLevel get warningLevel {
    // OUR_GUTS.md: "Authenticity Over Algorithms" - External data gets warnings
    if (type == SourceType.community) return WarningLevel.none;
    if (isCommunityContributed) return WarningLevel.low;
    return WarningLevel.medium;
  }

  /// Get source trust score (0.0 to 1.0)
  double get trustScore {
    double score = 0.5; // Base score
    
    // Community bonus (OUR_GUTS.md: "Community, Not Just Places")
    if (type == SourceType.community) score += 0.4;
    if (isCommunityContributed) score += 0.2;
    
    // Verification bonus
    if (isVerified) score += 0.1;
    
    // Trust level adjustment
    switch (trustLevel) {
      case TrustLevel.high:
        score += 0.2;
        break;
      case TrustLevel.medium:
        // No adjustment
        break;
      case TrustLevel.low:
        score -= 0.2;
        break;
    }
    
    // Quality metrics adjustment
    score += qualityMetrics.overallScore * 0.2;
    
    // Freshness adjustment
    switch (freshness) {
      case DataFreshness.fresh:
        score += 0.1;
        break;
      case DataFreshness.recent:
        score += 0.05;
        break;
      case DataFreshness.stale:
        score -= 0.05;
        break;
      case DataFreshness.outdated:
        score -= 0.1;
        break;
    }
    
    return score.clamp(0.0, 1.0);
  }

  /// Get user-friendly warning message
  String get warningMessage {
    switch (warningLevel) {
      case WarningLevel.none:
        return '';
      case WarningLevel.low:
        return 'Community-contributed external data';
      case WarningLevel.medium:
        return 'External data - may not reflect local community knowledge';
      case WarningLevel.high:
        return 'Unverified external data - use with caution';
    }
  }
}

/// Types of data sources
enum SourceType {
  community,
  googlePlaces,
  openStreetMap,
  other,
}

/// Trust levels for data sources
enum TrustLevel {
  high,
  medium,
  low,
}

/// Data freshness indicators
enum DataFreshness {
  fresh,    // < 1 day
  recent,   // < 1 week
  stale,    // < 1 month
  outdated, // > 1 month
}

/// Warning levels for external data
enum WarningLevel {
  none,
  low,
  medium,
  high,
}

/// Data quality metrics for source evaluation
class DataQualityMetrics {
  final double completeness;     // 0.0 to 1.0 - how complete is the data
  final double accuracy;         // 0.0 to 1.0 - how accurate is the data
  final double reliability;      // 0.0 to 1.0 - how reliable is the source
  final double communityRating;  // 0.0 to 1.0 - community validation score
  final int validationCount;     // Number of community validations

  DataQualityMetrics({
    required this.completeness,
    required this.accuracy,
    required this.reliability,
    required this.communityRating,
    required this.validationCount,
  });

  /// Create quality metrics for community data
  factory DataQualityMetrics.fromCommunityData(Map<String, dynamic> metadata) {
    return DataQualityMetrics(
      completeness: 0.9, // Community data tends to be complete
      accuracy: 0.95,    // High accuracy from local knowledge
      reliability: 0.9,  // High reliability from community verification
      communityRating: 0.95, // High community trust
      validationCount: metadata['validation_count'] ?? 1,
    );
  }

  /// Create quality metrics for Google Places data
  factory DataQualityMetrics.fromGooglePlaces(Map<String, dynamic> metadata) {
    return DataQualityMetrics(
      completeness: 0.8,  // Good completeness but may miss local details
      accuracy: 0.85,     // Generally accurate but may be outdated
      reliability: 0.8,   // Reliable but commercial focus
      communityRating: 0.6, // Lower community rating for external data
      validationCount: 0,  // No community validation yet
    );
  }

  /// Create quality metrics for OpenStreetMap data
  factory DataQualityMetrics.fromOpenStreetMap(Map<String, dynamic> metadata) {
    return DataQualityMetrics(
      completeness: 0.75, // Variable completeness
      accuracy: 0.8,      // Good accuracy from community contributions
      reliability: 0.85,  // High reliability from open community
      communityRating: 0.8, // High rating for community-contributed data
      validationCount: 0,  // No local community validation yet
    );
  }

  /// Calculate overall quality score
  double get overallScore {
    return (completeness + accuracy + reliability + communityRating) / 4.0;
  }

  /// Get quality grade (A, B, C, D, F)
  String get qualityGrade {
    final score = overallScore;
    if (score >= 0.9) return 'A';
    if (score >= 0.8) return 'B';
    if (score >= 0.7) return 'C';
    if (score >= 0.6) return 'D';
    return 'F';
  }
}

/// Source preference settings for users
class SourcePreferences {
  final bool allowGooglePlaces;
  final bool allowOpenStreetMap;
  final bool preferCommunityData;
  final bool showSourceWarnings;
  final bool showQualityMetrics;
  final double minimumTrustScore;

  SourcePreferences({
    this.allowGooglePlaces = true,
    this.allowOpenStreetMap = true,
    this.preferCommunityData = true,  // OUR_GUTS.md: "Authenticity Over Algorithms"
    this.showSourceWarnings = true,   // OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
    this.showQualityMetrics = true,
    this.minimumTrustScore = 0.5,
  });

  /// Create default preferences aligned with OUR_GUTS.md
  factory SourcePreferences.defaultSettings() {
    return SourcePreferences(
      allowGooglePlaces: true,
      allowOpenStreetMap: true,
      preferCommunityData: true,  // Always prefer community
      showSourceWarnings: true,   // Always show transparency
      showQualityMetrics: true,   // Always show quality info
      minimumTrustScore: 0.6,     // Moderate trust threshold
    );
  }

  /// Create privacy-focused preferences
  factory SourcePreferences.privacyFocused() {
    return SourcePreferences(
      allowGooglePlaces: false,   // Disable commercial data
      allowOpenStreetMap: true,   // Allow community-driven data
      preferCommunityData: true,
      showSourceWarnings: true,
      showQualityMetrics: true,
      minimumTrustScore: 0.8,     // High trust threshold
    );
  }

  /// Check if source is allowed by user preferences
  bool isSourceAllowed(SourceType sourceType) {
    switch (sourceType) {
      case SourceType.community:
        return true; // Always allow community data
      case SourceType.googlePlaces:
        return allowGooglePlaces;
      case SourceType.openStreetMap:
        return allowOpenStreetMap;
      case SourceType.other:
        return false; // Conservative approach for unknown sources
    }
  }
}
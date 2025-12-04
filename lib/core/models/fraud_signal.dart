/// Fraud Signal Enum
/// 
/// Represents different types of fraud signals detected during analysis.
/// 
/// **Fraud Signals:**
/// - `newHostExpensiveEvent`: New host with expensive event
/// - `invalidLocation`: Location doesn't exist or is invalid
/// - `stockPhotos`: Event images appear to be stock photos
/// - `duplicateEvent`: Event duplicates another existing event
/// - `suspiciouslyLowPrice`: Price too low compared to similar events
/// - `genericDescription`: Generic or low-quality description
/// - `noContactInfo`: Missing contact information
/// - `rapidEventCreation`: Many events created in short time
/// - `unverifiedHost`: Host not verified
/// - `unusualPaymentPattern`: Suspicious payment activity
enum FraudSignal {
  // Event fraud signals
  newHostExpensiveEvent,
  invalidLocation,
  stockPhotos,
  duplicateEvent,
  suspiciouslyLowPrice,
  genericDescription,
  noContactInfo,
  rapidEventCreation,
  unverifiedHost,
  unusualPaymentPattern,
  // Review fraud signals
  allFiveStar,
  sameDayClustering,
  genericReviews,
  similarLanguage,
  coordinatedReviews;

  /// Get display name for fraud signal
  String get displayName {
    switch (this) {
      case FraudSignal.newHostExpensiveEvent:
        return 'New Host with Expensive Event';
      case FraudSignal.invalidLocation:
        return 'Invalid Location';
      case FraudSignal.stockPhotos:
        return 'Stock Photos Detected';
      case FraudSignal.duplicateEvent:
        return 'Duplicate Event';
      case FraudSignal.suspiciouslyLowPrice:
        return 'Suspiciously Low Price';
      case FraudSignal.genericDescription:
        return 'Generic Description';
      case FraudSignal.noContactInfo:
        return 'Missing Contact Info';
      case FraudSignal.rapidEventCreation:
        return 'Rapid Event Creation';
      case FraudSignal.unverifiedHost:
        return 'Unverified Host';
      case FraudSignal.unusualPaymentPattern:
        return 'Unusual Payment Pattern';
      case FraudSignal.allFiveStar:
        return 'All 5-Star Reviews';
      case FraudSignal.sameDayClustering:
        return 'Same-Day Review Clustering';
      case FraudSignal.genericReviews:
        return 'Generic Review Text';
      case FraudSignal.similarLanguage:
        return 'Similar Language Patterns';
      case FraudSignal.coordinatedReviews:
        return 'Coordinated Fake Reviews';
    }
  }

  /// Get risk weight for this signal (0.0 to 1.0)
  double get riskWeight {
    switch (this) {
      case FraudSignal.duplicateEvent:
        return 0.5; // High weight
      case FraudSignal.invalidLocation:
        return 0.4; // High weight
      case FraudSignal.newHostExpensiveEvent:
        return 0.3; // Medium weight
      case FraudSignal.suspiciouslyLowPrice:
        return 0.3; // Medium weight
      case FraudSignal.unusualPaymentPattern:
        return 0.4; // High weight
      case FraudSignal.stockPhotos:
        return 0.2; // Low weight
      case FraudSignal.genericDescription:
        return 0.15; // Low weight
      case FraudSignal.noContactInfo:
        return 0.1; // Low weight
      case FraudSignal.rapidEventCreation:
        return 0.25; // Medium weight
      case FraudSignal.unverifiedHost:
        return 0.2; // Low weight
      case FraudSignal.allFiveStar:
        return 0.3; // Medium weight
      case FraudSignal.sameDayClustering:
        return 0.4; // High weight
      case FraudSignal.genericReviews:
        return 0.2; // Low weight
      case FraudSignal.similarLanguage:
        return 0.3; // Medium weight
      case FraudSignal.coordinatedReviews:
        return 0.5; // High weight
    }
  }

  /// Get description for fraud signal
  String get description {
    switch (this) {
      case FraudSignal.newHostExpensiveEvent:
        return 'Host has no previous events but created an expensive event';
      case FraudSignal.invalidLocation:
        return 'Event location does not exist or cannot be verified';
      case FraudSignal.stockPhotos:
        return 'Event images appear to be stock photos';
      case FraudSignal.duplicateEvent:
        return 'Event duplicates another existing event';
      case FraudSignal.suspiciouslyLowPrice:
        return 'Price is unusually low compared to similar events';
      case FraudSignal.genericDescription:
        return 'Event description is generic or low-quality';
      case FraudSignal.noContactInfo:
        return 'Missing contact information';
      case FraudSignal.rapidEventCreation:
        return 'Host created many events in a short time';
      case FraudSignal.unverifiedHost:
        return 'Host account is not verified';
      case FraudSignal.unusualPaymentPattern:
        return 'Suspicious payment activity detected';
      case FraudSignal.allFiveStar:
        return 'All reviews are 5-star ratings';
      case FraudSignal.sameDayClustering:
        return 'Multiple reviews submitted on the same day';
      case FraudSignal.genericReviews:
        return 'Reviews contain generic or low-quality text';
      case FraudSignal.similarLanguage:
        return 'Reviews have similar language patterns';
      case FraudSignal.coordinatedReviews:
        return 'Coordinated fake review campaign detected';
    }
  }

  /// Convert to string for JSON serialization
  String toJson() => name;

  /// Create from string (for JSON deserialization)
  static FraudSignal fromJson(String value) {
    return FraudSignal.values.firstWhere(
      (signal) => signal.name == value,
      orElse: () => FraudSignal.genericDescription,
    );
  }
}


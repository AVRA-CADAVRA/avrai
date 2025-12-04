/// Refund Policy Utility Class
/// 
/// Provides time-based refund calculations and policy enforcement.
/// 
/// **Philosophy Alignment:**
/// - Enables fair and transparent refund policies
/// - Supports time-based refund windows
/// - Provides clear refund calculations
/// 
/// **Refund Windows (typical):**
/// - Full refund: > 48 hours before event
/// - 50% refund: 24-48 hours before event
/// - No refund: < 24 hours before event
/// - Force majeure: Always full refund
/// 
/// **Usage:**
/// ```dart
/// final policy = RefundPolicy.standard();
/// final refundAmount = policy.calculateRefundAmount(
///   ticketPrice: 50.00,
///   hoursUntilEvent: 36, // 36 hours before event
///   isForceMajeure: false,
/// );
/// // Returns: 25.00 (50% refund)
/// ```
class RefundPolicy {
  /// Hours before event for full refund window
  final int fullRefundHours;
  
  /// Hours before event for partial refund window
  final int partialRefundHours;
  
  /// Partial refund percentage (0-100)
  final double partialRefundPercentage;
  
  /// Minimum refund amount (e.g., $0.50)
  final double minimumRefundAmount;

  const RefundPolicy({
    this.fullRefundHours = 48,
    this.partialRefundHours = 24,
    this.partialRefundPercentage = 50.0,
    this.minimumRefundAmount = 0.50,
  });

  /// Standard refund policy (48hr full, 24hr partial 50%)
  factory RefundPolicy.standard() {
    return const RefundPolicy(
      fullRefundHours: 48,
      partialRefundHours: 24,
      partialRefundPercentage: 50.0,
      minimumRefundAmount: 0.50,
    );
  }

  /// Lenient refund policy (72hr full, 24hr partial 75%)
  factory RefundPolicy.lenient() {
    return const RefundPolicy(
      fullRefundHours: 72,
      partialRefundHours: 24,
      partialRefundPercentage: 75.0,
      minimumRefundAmount: 0.50,
    );
  }

  /// Strict refund policy (24hr full, 12hr partial 25%)
  factory RefundPolicy.strict() {
    return const RefundPolicy(
      fullRefundHours: 24,
      partialRefundHours: 12,
      partialRefundPercentage: 25.0,
      minimumRefundAmount: 0.50,
    );
  }

  /// No refund policy (event organizer decides)
  factory RefundPolicy.noRefund() {
    return const RefundPolicy(
      fullRefundHours: 0,
      partialRefundHours: 0,
      partialRefundPercentage: 0.0,
      minimumRefundAmount: 0.0,
    );
  }

  /// Calculate refund amount based on time until event
  /// 
  /// Returns:
  /// - Full refund if hoursUntilEvent > fullRefundHours
  /// - Partial refund if hoursUntilEvent > partialRefundHours
  /// - No refund if hoursUntilEvent <= partialRefundHours
  /// - Always full refund if force majeure
  double calculateRefundAmount({
    required double ticketPrice,
    required double hoursUntilEvent,
    bool isForceMajeure = false,
  }) {
    // Force majeure always gets full refund
    if (isForceMajeure) {
      return ticketPrice;
    }

    // No refund window defined
    if (fullRefundHours == 0 && partialRefundHours == 0) {
      return 0.0;
    }

    // Full refund window
    if (hoursUntilEvent > fullRefundHours) {
      return ticketPrice;
    }

    // Partial refund window
    if (hoursUntilEvent > partialRefundHours) {
      final partialAmount = ticketPrice * (partialRefundPercentage / 100.0);
      return partialAmount >= minimumRefundAmount
          ? partialAmount
          : 0.0;
    }

    // No refund (too close to event)
    return 0.0;
  }

  /// Calculate refund percentage (0-100) based on time until event
  double calculateRefundPercentage({
    required double hoursUntilEvent,
    bool isForceMajeure = false,
  }) {
    if (isForceMajeure) {
      return 100.0;
    }

    if (fullRefundHours == 0 && partialRefundHours == 0) {
      return 0.0;
    }

    if (hoursUntilEvent > fullRefundHours) {
      return 100.0;
    }

    if (hoursUntilEvent > partialRefundHours) {
      return partialRefundPercentage;
    }

    return 0.0;
  }

  /// Check if refund is eligible at given time
  bool isRefundEligible({
    required double hoursUntilEvent,
    bool isForceMajeure = false,
  }) {
    if (isForceMajeure) {
      return true;
    }

    if (fullRefundHours == 0 && partialRefundHours == 0) {
      return false;
    }

    return hoursUntilEvent > partialRefundHours;
  }

  /// Get refund window description
  String getRefundWindowDescription() {
    if (fullRefundHours == 0 && partialRefundHours == 0) {
      return 'No refund policy';
    }

    if (fullRefundHours == partialRefundHours) {
      return 'Full refund up to ${fullRefundHours}h before event';
    }

    return 'Full refund >${fullRefundHours}h, '
        '${partialRefundPercentage}% refund ${partialRefundHours}-${fullRefundHours}h';
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'fullRefundHours': fullRefundHours,
      'partialRefundHours': partialRefundHours,
      'partialRefundPercentage': partialRefundPercentage,
      'minimumRefundAmount': minimumRefundAmount,
    };
  }

  /// Create from JSON
  factory RefundPolicy.fromJson(Map<String, dynamic> json) {
    return RefundPolicy(
      fullRefundHours: json['fullRefundHours'] as int? ?? 48,
      partialRefundHours: json['partialRefundHours'] as int? ?? 24,
      partialRefundPercentage:
          (json['partialRefundPercentage'] as num?)?.toDouble() ?? 50.0,
      minimumRefundAmount:
          (json['minimumRefundAmount'] as num?)?.toDouble() ?? 0.50,
    );
  }
}

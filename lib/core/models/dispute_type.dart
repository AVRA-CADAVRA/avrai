/// Dispute Type Enum
/// 
/// Represents the type/category of a dispute.
/// 
/// **Dispute Types:**
/// - `cancellation`: Dispute related to cancellation/refund
/// - `payment`: Dispute related to payment issue
/// - `event`: Dispute related to event quality/service
/// - `partnership`: Dispute related to partnership agreement
/// - `safety`: Dispute related to safety concerns
/// - `other`: Other type of dispute
enum DisputeType {
  cancellation,
  payment,
  event,
  partnership,
  safety,
  other;

  /// Get display name for dispute type
  String get displayName {
    switch (this) {
      case DisputeType.cancellation:
        return 'Cancellation';
      case DisputeType.payment:
        return 'Payment';
      case DisputeType.event:
        return 'Event Quality';
      case DisputeType.partnership:
        return 'Partnership';
      case DisputeType.safety:
        return 'Safety';
      case DisputeType.other:
        return 'Other';
    }
  }

  /// Get description for dispute type
  String get description {
    switch (this) {
      case DisputeType.cancellation:
        return 'Dispute related to event cancellation or refund';
      case DisputeType.payment:
        return 'Dispute related to payment processing or charges';
      case DisputeType.event:
        return 'Dispute related to event quality or service';
      case DisputeType.partnership:
        return 'Dispute related to partnership agreement';
      case DisputeType.safety:
        return 'Dispute related to safety concerns';
      case DisputeType.other:
        return 'Other type of dispute';
    }
  }

  /// Convert to string for JSON serialization
  String toJson() => name;

  /// Create from string (for JSON deserialization)
  static DisputeType fromJson(String value) {
    return DisputeType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => DisputeType.other,
    );
  }
}


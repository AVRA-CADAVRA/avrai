/// Tax Status Enum
/// 
/// Represents the current status of a tax document or tax requirement.
/// 
/// **Status Flow:**
/// - `notRequired`: Earnings < $600 threshold, no tax documents needed
/// - `pending`: Needs tax document generation
/// - `generated`: Document has been generated
/// - `sent`: Document sent to user
/// - `filed`: Document filed with IRS
enum TaxStatus {
  notRequired,
  pending,
  generated,
  sent,
  filed;

  /// Get display name for tax status
  String get displayName {
    switch (this) {
      case TaxStatus.notRequired:
        return 'Not Required';
      case TaxStatus.pending:
        return 'Pending';
      case TaxStatus.generated:
        return 'Generated';
      case TaxStatus.sent:
        return 'Sent';
      case TaxStatus.filed:
        return 'Filed';
    }
  }

  /// Check if status indicates action needed
  bool get needsAction => this == TaxStatus.pending;

  /// Check if status is in terminal state
  bool get isTerminal => this == TaxStatus.filed || this == TaxStatus.notRequired;

  /// Check if document is ready to send
  bool get isReadyToSend => this == TaxStatus.generated;

  /// Convert to string for JSON serialization
  String toJson() => name;

  /// Create from string (for JSON deserialization)
  static TaxStatus fromJson(String value) {
    return TaxStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => TaxStatus.notRequired,
    );
  }
}


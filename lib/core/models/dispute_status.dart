/// Dispute Status Enum
/// 
/// Represents the current status of a dispute.
/// 
/// **Status Flow:**
/// - `pending`: Dispute submitted, awaiting admin assignment
/// - `inReview`: Admin assigned, dispute under review
/// - `waitingResponse`: Waiting for user response
/// - `resolved`: Dispute resolved
/// - `closed`: Dispute closed (no resolution needed)
enum DisputeStatus {
  pending,
  inReview,
  waitingResponse,
  resolved,
  closed;

  /// Get display name for dispute status
  String get displayName {
    switch (this) {
      case DisputeStatus.pending:
        return 'Pending';
      case DisputeStatus.inReview:
        return 'In Review';
      case DisputeStatus.waitingResponse:
        return 'Waiting for Response';
      case DisputeStatus.resolved:
        return 'Resolved';
      case DisputeStatus.closed:
        return 'Closed';
    }
  }

  /// Check if dispute is active (not resolved/closed)
  bool get isActive =>
      this == DisputeStatus.pending ||
      this == DisputeStatus.inReview ||
      this == DisputeStatus.waitingResponse;

  /// Check if dispute is resolved
  bool get isResolved => this == DisputeStatus.resolved;

  /// Check if dispute is closed
  bool get isClosed => this == DisputeStatus.closed;

  /// Check if dispute is in terminal state
  bool get isTerminal =>
      this == DisputeStatus.resolved || this == DisputeStatus.closed;

  /// Convert to string for JSON serialization
  String toJson() => name;

  /// Create from string (for JSON deserialization)
  static DisputeStatus fromJson(String value) {
    return DisputeStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => DisputeStatus.pending,
    );
  }
}


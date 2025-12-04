/// Refund Status Enum
/// 
/// Represents the current status of a refund transaction.
/// 
/// **Status Flow:**
/// - `pending`: Refund requested but not yet processed
/// - `processing`: Refund is being processed (Stripe, etc.)
/// - `completed`: Refund successfully completed
/// - `failed`: Refund failed (payment method issue, etc.)
/// - `disputed`: Refund is under dispute/resolution
enum RefundStatus {
  pending,
  processing,
  completed,
  failed,
  disputed;

  /// Get display name for refund status
  String get displayName {
    switch (this) {
      case RefundStatus.pending:
        return 'Pending';
      case RefundStatus.processing:
        return 'Processing';
      case RefundStatus.completed:
        return 'Completed';
      case RefundStatus.failed:
        return 'Failed';
      case RefundStatus.disputed:
        return 'Disputed';
    }
  }

  /// Check if refund is in a terminal state (completed, failed, disputed)
  bool get isTerminal =>
      this == RefundStatus.completed ||
      this == RefundStatus.failed ||
      this == RefundStatus.disputed;

  /// Check if refund is successful
  bool get isSuccessful => this == RefundStatus.completed;

  /// Check if refund is in progress
  bool get isInProgress =>
      this == RefundStatus.pending || this == RefundStatus.processing;

  /// Convert to string for JSON serialization
  String toJson() => name;

  /// Create from string (for JSON deserialization)
  static RefundStatus fromJson(String value) {
    return RefundStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => RefundStatus.pending,
    );
  }
}


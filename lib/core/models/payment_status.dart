/// Payment Status Enum
/// 
/// Represents the current status of a payment transaction.
/// 
/// **Status Flow:**
/// - `pending`: Payment initiated but not yet processed
/// - `processing`: Payment is being processed by Stripe
/// - `completed`: Payment successfully completed
/// - `failed`: Payment failed (insufficient funds, declined, etc.)
/// - `refunded`: Payment was refunded to the customer
enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  refunded;

  /// Get display name for payment status
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  /// Check if payment is in a terminal state (completed, failed, or refunded)
  bool get isTerminal => this == PaymentStatus.completed || 
                        this == PaymentStatus.failed || 
                        this == PaymentStatus.refunded;

  /// Check if payment is successful
  bool get isSuccessful => this == PaymentStatus.completed;

  /// Convert to string for JSON serialization
  String toJson() => name;

  /// Create from string (for JSON deserialization)
  static PaymentStatus fromJson(String value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => PaymentStatus.pending,
    );
  }
}


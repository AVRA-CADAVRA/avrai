/// Verification Status Enum
/// 
/// Represents the current status of an identity verification.
/// 
/// **Status Flow:**
/// - `pending`: Verification session created, awaiting user action
/// - `processing`: Verification in progress
/// - `verified`: Verification completed successfully
/// - `failed`: Verification failed
/// - `expired`: Verification session expired
enum VerificationStatus {
  pending,
  processing,
  verified,
  failed,
  expired;

  /// Get display name for verification status
  String get displayName {
    switch (this) {
      case VerificationStatus.pending:
        return 'Pending';
      case VerificationStatus.processing:
        return 'Processing';
      case VerificationStatus.verified:
        return 'Verified';
      case VerificationStatus.failed:
        return 'Failed';
      case VerificationStatus.expired:
        return 'Expired';
    }
  }

  /// Check if status is in progress
  bool get isInProgress =>
      this == VerificationStatus.pending ||
      this == VerificationStatus.processing;

  /// Check if verification is complete (verified or failed)
  bool get isComplete =>
      this == VerificationStatus.verified ||
      this == VerificationStatus.failed ||
      this == VerificationStatus.expired;

  /// Check if verification is successful
  bool get isSuccessful => this == VerificationStatus.verified;

  /// Check if verification is in terminal state
  bool get isTerminal =>
      this == VerificationStatus.verified ||
      this == VerificationStatus.failed ||
      this == VerificationStatus.expired;

  /// Convert to string for JSON serialization
  String toJson() => name;

  /// Create from string (for JSON deserialization)
  static VerificationStatus fromJson(String value) {
    return VerificationStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => VerificationStatus.pending,
    );
  }
}


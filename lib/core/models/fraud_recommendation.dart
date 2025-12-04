/// Fraud Recommendation Enum
/// 
/// Represents the recommended action based on fraud risk assessment.
/// 
/// **Recommendations:**
/// - `approve`: Low risk, approve automatically
/// - `review`: Medium risk, requires admin review
/// - `requireVerification`: High risk, require identity verification
/// - `reject`: Very high risk, reject automatically
enum FraudRecommendation {
  approve,
  review,
  requireVerification,
  reject;

  /// Get display name for fraud recommendation
  String get displayName {
    switch (this) {
      case FraudRecommendation.approve:
        return 'Approve';
      case FraudRecommendation.review:
        return 'Review Required';
      case FraudRecommendation.requireVerification:
        return 'Require Verification';
      case FraudRecommendation.reject:
        return 'Reject';
    }
  }

  /// Get description for fraud recommendation
  String get description {
    switch (this) {
      case FraudRecommendation.approve:
        return 'Low risk, event can be approved automatically';
      case FraudRecommendation.review:
        return 'Medium risk, requires admin review before approval';
      case FraudRecommendation.requireVerification:
        return 'High risk, requires identity verification before approval';
      case FraudRecommendation.reject:
        return 'Very high risk, event should be rejected';
    }
  }

  /// Determine recommendation from risk score
  static FraudRecommendation fromRiskScore(double riskScore) {
    if (riskScore >= 0.8) return FraudRecommendation.reject;
    if (riskScore >= 0.6) return FraudRecommendation.requireVerification;
    if (riskScore >= 0.4) return FraudRecommendation.review;
    return FraudRecommendation.approve;
  }

  /// Check if recommendation requires action
  bool get requiresAction =>
      this == FraudRecommendation.review ||
      this == FraudRecommendation.requireVerification ||
      this == FraudRecommendation.reject;

  /// Check if recommendation allows auto-approval
  bool get allowsAutoApproval => this == FraudRecommendation.approve;

  /// Convert to string for JSON serialization
  String toJson() => name;

  /// Create from string (for JSON deserialization)
  static FraudRecommendation fromJson(String value) {
    return FraudRecommendation.values.firstWhere(
      (recommendation) => recommendation.name == value,
      orElse: () => FraudRecommendation.review,
    );
  }
}


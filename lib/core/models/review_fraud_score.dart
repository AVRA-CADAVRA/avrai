import 'package:equatable/equatable.dart';
import 'package:spots/core/models/fraud_signal.dart';
import 'package:spots/core/models/fraud_recommendation.dart';

/// Review Fraud Score Model
/// 
/// Represents a fraud risk assessment for a review/feedback submission.
/// Used to detect fake or fraudulent reviews.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to authentic feedback
/// - Enables review quality control
/// - Supports platform trust
/// 
/// **Usage:**
/// ```dart
/// final reviewFraudScore = ReviewFraudScore(
///   id: 'review-fraud-123',
///   feedbackId: 'feedback-456',
///   riskScore: 0.75,
///   signals: [FraudSignal.allFiveStar, FraudSignal.sameDayClustering],
///   recommendation: FraudRecommendation.review,
/// );
/// ```
class ReviewFraudScore extends Equatable {
  /// Unique review fraud score identifier
  final String id;
  
  /// Feedback/review ID this score is for
  final String feedbackId;
  
  /// Risk score (0.0 to 1.0, where 1.0 is highest risk)
  final double riskScore;
  
  /// Fraud signals detected
  final List<FraudSignal> signals;
  
  /// Recommendation based on risk score
  final FraudRecommendation recommendation;
  
  /// When score was calculated
  final DateTime calculatedAt;
  
  /// When score was last updated
  final DateTime updatedAt;
  
  /// Admin review status (if reviewed)
  final bool reviewedByAdmin;
  
  /// Admin who reviewed (if reviewed)
  final String? reviewedByAdminId;
  
  /// When reviewed by admin
  final DateTime? reviewedAt;
  
  /// Admin decision (approve, remove)
  final String? adminDecision;
  
  /// Optional metadata
  final Map<String, dynamic> metadata;

  const ReviewFraudScore({
    required this.id,
    required this.feedbackId,
    required this.riskScore,
    this.signals = const [],
    required this.recommendation,
    required this.calculatedAt,
    required this.updatedAt,
    this.reviewedByAdmin = false,
    this.reviewedByAdminId,
    this.reviewedAt,
    this.adminDecision,
    this.metadata = const {},
  });

  /// Create a copy with updated fields
  ReviewFraudScore copyWith({
    String? id,
    String? feedbackId,
    double? riskScore,
    List<FraudSignal>? signals,
    FraudRecommendation? recommendation,
    DateTime? calculatedAt,
    DateTime? updatedAt,
    bool? reviewedByAdmin,
    String? reviewedByAdminId,
    DateTime? reviewedAt,
    String? adminDecision,
    Map<String, dynamic>? metadata,
  }) {
    return ReviewFraudScore(
      id: id ?? this.id,
      feedbackId: feedbackId ?? this.feedbackId,
      riskScore: riskScore ?? this.riskScore,
      signals: signals ?? this.signals,
      recommendation: recommendation ?? this.recommendation,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reviewedByAdmin: reviewedByAdmin ?? this.reviewedByAdmin,
      reviewedByAdminId: reviewedByAdminId ?? this.reviewedByAdminId,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      adminDecision: adminDecision ?? this.adminDecision,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'feedbackId': feedbackId,
      'riskScore': riskScore,
      'signals': signals.map((s) => s.toJson()).toList(),
      'recommendation': recommendation.toJson(),
      'calculatedAt': calculatedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'reviewedByAdmin': reviewedByAdmin,
      'reviewedByAdminId': reviewedByAdminId,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'adminDecision': adminDecision,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory ReviewFraudScore.fromJson(Map<String, dynamic> json) {
    return ReviewFraudScore(
      id: json['id'] as String,
      feedbackId: json['feedbackId'] as String,
      riskScore: (json['riskScore'] as num).toDouble(),
      signals: (json['signals'] as List<dynamic>?)
              ?.map((s) => FraudSignal.fromJson(s as String))
              .toList() ??
          [],
      recommendation: FraudRecommendation.fromJson(json['recommendation'] as String),
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      reviewedByAdmin: json['reviewedByAdmin'] as bool? ?? false,
      reviewedByAdminId: json['reviewedByAdminId'] as String?,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'] as String)
          : null,
      adminDecision: json['adminDecision'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Check if high risk (score >= 0.7)
  bool get isHighRisk => riskScore >= 0.7;

  /// Check if requires admin review
  bool get requiresReview => isHighRisk || signals.length >= 2;

  @override
  List<Object?> get props => [
        id,
        feedbackId,
        riskScore,
        signals,
        recommendation,
        calculatedAt,
        updatedAt,
        reviewedByAdmin,
        reviewedByAdminId,
        reviewedAt,
        adminDecision,
        metadata,
      ];
}


import 'package:equatable/equatable.dart';
import 'package:spots/core/models/fraud_signal.dart';
import 'package:spots/core/models/fraud_recommendation.dart';

/// Fraud Score Model
/// 
/// Represents a fraud risk assessment for an event or transaction.
/// Used for fraud detection and prevention.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to platform safety and trust
/// - Enables fraud prevention
/// - Supports user protection
/// 
/// **Usage:**
/// ```dart
/// final fraudScore = FraudScore(
///   id: 'fraud-123',
///   eventId: 'event-456',
///   riskScore: 0.65,
///   signals: [FraudSignal.newHostExpensiveEvent, FraudSignal.stockPhotos],
///   recommendation: FraudRecommendation.requireVerification,
/// );
/// ```
class FraudScore extends Equatable {
  /// Unique fraud score identifier
  final String id;
  
  /// Event ID this score is for
  final String eventId;
  
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
  
  /// Admin decision (approved, rejected, require_verification)
  final String? adminDecision;
  
  /// Optional metadata
  final Map<String, dynamic> metadata;

  const FraudScore({
    required this.id,
    required this.eventId,
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
  FraudScore copyWith({
    String? id,
    String? eventId,
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
    return FraudScore(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
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
      'eventId': eventId,
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
  factory FraudScore.fromJson(Map<String, dynamic> json) {
    return FraudScore(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
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

  /// Check if medium risk (0.4 <= score < 0.7)
  bool get isMediumRisk => riskScore >= 0.4 && riskScore < 0.7;

  /// Check if low risk (score < 0.4)
  bool get isLowRisk => riskScore < 0.4;

  /// Check if requires admin review
  bool get requiresReview => isHighRisk || signals.length >= 3;

  @override
  List<Object?> get props => [
        id,
        eventId,
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


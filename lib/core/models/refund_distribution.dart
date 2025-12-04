import 'package:equatable/equatable.dart';

/// Refund Distribution Model
/// 
/// Represents how a refund is distributed to different parties.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to transparent refund processing
/// - Enables fair distribution of refunds
/// - Supports multi-party refund scenarios
/// 
/// **Usage:**
/// ```dart
/// final distribution = RefundDistribution(
///   userId: 'user-123',
///   role: 'attendee',
///   amount: 25.00,
///   stripeRefundId: 're_1234567890',
/// );
/// ```
class RefundDistribution extends Equatable {
  /// User ID who receives the refund
  final String userId;
  
  /// Role of the user (attendee, host, venue, sponsor, etc.)
  final String role;
  
  /// Refund amount in dollars
  final double amount;
  
  /// Stripe refund ID (if processed through Stripe)
  final String? stripeRefundId;
  
  /// When refund was completed
  final DateTime? completedAt;
  
  /// Refund status message (optional)
  final String? statusMessage;
  
  /// Optional metadata
  final Map<String, dynamic> metadata;

  const RefundDistribution({
    required this.userId,
    required this.role,
    required this.amount,
    this.stripeRefundId,
    this.completedAt,
    this.statusMessage,
    this.metadata = const {},
  });

  /// Create a copy with updated fields
  RefundDistribution copyWith({
    String? userId,
    String? role,
    double? amount,
    String? stripeRefundId,
    DateTime? completedAt,
    String? statusMessage,
    Map<String, dynamic>? metadata,
  }) {
    return RefundDistribution(
      userId: userId ?? this.userId,
      role: role ?? this.role,
      amount: amount ?? this.amount,
      stripeRefundId: stripeRefundId ?? this.stripeRefundId,
      completedAt: completedAt ?? this.completedAt,
      statusMessage: statusMessage ?? this.statusMessage,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'role': role,
      'amount': amount,
      'stripeRefundId': stripeRefundId,
      'completedAt': completedAt?.toIso8601String(),
      'statusMessage': statusMessage,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory RefundDistribution.fromJson(Map<String, dynamic> json) {
    return RefundDistribution(
      userId: json['userId'] as String,
      role: json['role'] as String,
      amount: (json['amount'] as num).toDouble(),
      stripeRefundId: json['stripeRefundId'] as String?,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      statusMessage: json['statusMessage'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Check if refund has been processed
  bool get isProcessed => stripeRefundId != null && completedAt != null;

  @override
  List<Object?> get props => [
        userId,
        role,
        amount,
        stripeRefundId,
        completedAt,
        statusMessage,
        metadata,
      ];
}

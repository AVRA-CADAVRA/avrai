import 'package:equatable/equatable.dart';
import 'package:spots/core/models/cancellation_initiator.dart';
import 'package:spots/core/models/refund_status.dart';

/// Cancellation Model
/// 
/// Represents a cancellation of an event or ticket purchase.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to trust and user protection
/// - Enables fair cancellation policies
/// - Supports transparent refund processing
/// - Creates pathways for dispute resolution
/// 
/// **Usage:**
/// ```dart
/// final cancellation = Cancellation(
///   id: 'cancellation-123',
///   eventId: 'event-456',
///   userId: 'user-789',
///   initiator: CancellationInitiator.attendee,
///   reason: 'Unable to attend',
///   refundStatus: RefundStatus.pending,
///   createdAt: DateTime.now(),
/// );
/// ```
class Cancellation extends Equatable {
  /// Unique cancellation identifier
  final String id;
  
  /// Event ID that was cancelled
  final String eventId;
  
  /// User ID who initiated the cancellation (or affected user)
  final String userId;
  
  /// Who initiated the cancellation
  final CancellationInitiator initiator;
  
  /// Reason for cancellation
  final String? reason;
  
  /// Current refund status
  final RefundStatus refundStatus;
  
  /// Payment ID(s) associated with this cancellation (for refund processing)
  final List<String> paymentIds;
  
  /// Cancellation timestamp
  final DateTime createdAt;
  
  /// Last update timestamp
  final DateTime updatedAt;
  
  /// When refund was processed (if applicable)
  final DateTime? refundProcessedAt;
  
  /// Refund amount (calculated based on policy)
  final double? refundAmount;
  
  /// Whether this is a full event cancellation (vs. individual ticket cancellation)
  final bool isFullEventCancellation;
  
  /// Whether cancellation was due to force majeure (weather, emergency, etc.)
  final bool isForceMajeure;
  
  /// Optional metadata for additional information
  final Map<String, dynamic> metadata;

  const Cancellation({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.initiator,
    this.reason,
    this.refundStatus = RefundStatus.pending,
    this.paymentIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.refundProcessedAt,
    this.refundAmount,
    this.isFullEventCancellation = false,
    this.isForceMajeure = false,
    this.metadata = const {},
  });

  /// Create a copy with updated fields
  Cancellation copyWith({
    String? id,
    String? eventId,
    String? userId,
    CancellationInitiator? initiator,
    String? reason,
    RefundStatus? refundStatus,
    List<String>? paymentIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? refundProcessedAt,
    double? refundAmount,
    bool? isFullEventCancellation,
    bool? isForceMajeure,
    Map<String, dynamic>? metadata,
  }) {
    return Cancellation(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      initiator: initiator ?? this.initiator,
      reason: reason ?? this.reason,
      refundStatus: refundStatus ?? this.refundStatus,
      paymentIds: paymentIds ?? this.paymentIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      refundProcessedAt: refundProcessedAt ?? this.refundProcessedAt,
      refundAmount: refundAmount ?? this.refundAmount,
      isFullEventCancellation: isFullEventCancellation ?? this.isFullEventCancellation,
      isForceMajeure: isForceMajeure ?? this.isForceMajeure,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'userId': userId,
      'initiator': initiator.toJson(),
      'reason': reason,
      'refundStatus': refundStatus.toJson(),
      'paymentIds': paymentIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'refundProcessedAt': refundProcessedAt?.toIso8601String(),
      'refundAmount': refundAmount,
      'isFullEventCancellation': isFullEventCancellation,
      'isForceMajeure': isForceMajeure,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory Cancellation.fromJson(Map<String, dynamic> json) {
    return Cancellation(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      userId: json['userId'] as String,
      initiator: CancellationInitiator.fromJson(json['initiator'] as String),
      reason: json['reason'] as String?,
      refundStatus: RefundStatus.fromJson(json['refundStatus'] as String),
      paymentIds: List<String>.from(json['paymentIds'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      refundProcessedAt: json['refundProcessedAt'] != null
          ? DateTime.parse(json['refundProcessedAt'] as String)
          : null,
      refundAmount: json['refundAmount'] != null
          ? (json['refundAmount'] as num).toDouble()
          : null,
      isFullEventCancellation: json['isFullEventCancellation'] as bool? ?? false,
      isForceMajeure: json['isForceMajeure'] as bool? ?? false,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Check if refund is pending
  bool get isRefundPending => refundStatus == RefundStatus.pending;

  /// Check if refund was completed
  bool get isRefundCompleted => refundStatus == RefundStatus.completed;

  /// Check if refund failed
  bool get isRefundFailed => refundStatus == RefundStatus.failed;

  /// Check if refund is disputed
  bool get isRefundDisputed => refundStatus == RefundStatus.disputed;

  @override
  List<Object?> get props => [
        id,
        eventId,
        userId,
        initiator,
        reason,
        refundStatus,
        paymentIds,
        createdAt,
        updatedAt,
        refundProcessedAt,
        refundAmount,
        isFullEventCancellation,
        isForceMajeure,
        metadata,
      ];
}


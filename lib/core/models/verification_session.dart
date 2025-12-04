import 'package:equatable/equatable.dart';

/// Verification Status Enum
enum VerificationStatus {
  pending,
  processing,
  verified,
  failed,
  expired,
  cancelled,
}

/// Verification Session Model
/// 
/// Represents an identity verification session for a user.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to platform security
/// - Enables trust through verification
/// - Supports compliance with regulations
/// 
/// **Usage:**
/// ```dart
/// final session = VerificationSession(
///   id: 'session-123',
///   userId: 'user-456',
///   status: VerificationStatus.pending,
///   verificationUrl: 'https://verify.stripe.com/...',
///   createdAt: DateTime.now(),
/// );
/// ```
class VerificationSession extends Equatable {
  /// Unique session identifier
  final String id;
  
  /// User ID being verified
  final String userId;
  
  /// Verification status
  final VerificationStatus status;
  
  /// URL for user to complete verification
  final String? verificationUrl;
  
  /// Stripe verification session ID (if using Stripe Identity)
  final String? stripeSessionId;
  
  /// When session was created
  final DateTime createdAt;
  
  /// When session expires
  final DateTime? expiresAt;
  
  /// When verification was completed
  final DateTime? completedAt;
  
  /// Optional metadata
  final Map<String, dynamic> metadata;

  const VerificationSession({
    required this.id,
    required this.userId,
    required this.status,
    this.verificationUrl,
    this.stripeSessionId,
    required this.createdAt,
    this.expiresAt,
    this.completedAt,
    this.metadata = const {},
  });

  /// Create a copy with updated fields
  VerificationSession copyWith({
    String? id,
    String? userId,
    VerificationStatus? status,
    String? verificationUrl,
    String? stripeSessionId,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) {
    return VerificationSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      verificationUrl: verificationUrl ?? this.verificationUrl,
      stripeSessionId: stripeSessionId ?? this.stripeSessionId,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        status,
        verificationUrl,
        stripeSessionId,
        createdAt,
        expiresAt,
        completedAt,
        metadata,
      ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'status': status.name,
      'verificationUrl': verificationUrl,
      'stripeSessionId': stripeSessionId,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory VerificationSession.fromJson(Map<String, dynamic> json) {
    return VerificationSession(
      id: json['id'] as String,
      userId: json['userId'] as String,
      status: VerificationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => VerificationStatus.pending,
      ),
      verificationUrl: json['verificationUrl'] as String?,
      stripeSessionId: json['stripeSessionId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

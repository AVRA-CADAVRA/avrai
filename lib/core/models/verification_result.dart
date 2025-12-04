import 'package:equatable/equatable.dart';
import 'package:spots/core/models/verification_session.dart';

/// Verification Result Model
/// 
/// Represents the result of an identity verification session.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to platform security
/// - Enables trust through verification
/// - Supports compliance with regulations
/// 
/// **Usage:**
/// ```dart
/// final result = VerificationResult(
///   sessionId: 'session-123',
///   status: VerificationStatus.verified,
///   verified: true,
///   verifiedAt: DateTime.now(),
/// );
/// ```
class VerificationResult extends Equatable {
  /// Verification session ID
  final String sessionId;
  
  /// Verification status
  final VerificationStatus status;
  
  /// Whether verification was successful
  final bool verified;
  
  /// When verification was completed
  final DateTime? verifiedAt;
  
  /// Failure reason (if verification failed)
  final String? failureReason;
  
  /// Verified identity details (if successful)
  final Map<String, dynamic>? identityDetails;
  
  /// Optional metadata
  final Map<String, dynamic> metadata;

  const VerificationResult({
    required this.sessionId,
    required this.status,
    required this.verified,
    this.verifiedAt,
    this.failureReason,
    this.identityDetails,
    this.metadata = const {},
  });

  /// Create a copy with updated fields
  VerificationResult copyWith({
    String? sessionId,
    VerificationStatus? status,
    bool? verified,
    DateTime? verifiedAt,
    String? failureReason,
    Map<String, dynamic>? identityDetails,
    Map<String, dynamic>? metadata,
  }) {
    return VerificationResult(
      sessionId: sessionId ?? this.sessionId,
      status: status ?? this.status,
      verified: verified ?? this.verified,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      failureReason: failureReason ?? this.failureReason,
      identityDetails: identityDetails ?? this.identityDetails,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        status,
        verified,
        verifiedAt,
        failureReason,
        identityDetails,
        metadata,
      ];

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'status': status.name,
      'verified': verified,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'failureReason': failureReason,
      'identityDetails': identityDetails,
      'metadata': metadata,
    };
  }

  factory VerificationResult.fromJson(Map<String, dynamic> json) {
    return VerificationResult(
      sessionId: json['sessionId'] as String,
      status: VerificationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => VerificationStatus.pending,
      ),
      verified: json['verified'] as bool? ?? false,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'] as String)
          : null,
      failureReason: json['failureReason'] as String?,
      identityDetails: json['identityDetails'] != null
          ? Map<String, dynamic>.from(json['identityDetails'] as Map)
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

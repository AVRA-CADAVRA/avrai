import 'package:equatable/equatable.dart';

/// User Agreement Model
/// 
/// Represents a user's agreement to legal documents (Terms of Service,
/// Privacy Policy, Event Waivers, etc.). Tracks version and acceptance.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to legal compliance
/// - Enables transparent agreement tracking
/// - Supports version management
/// - Creates pathways for legal protection
/// 
/// **Usage:**
/// ```dart
/// final agreement = UserAgreement(
///   id: 'agreement-123',
///   userId: 'user-456',
///   documentType: 'terms_of_service',
///   version: '1.0.0',
///   agreedAt: DateTime.now(),
///   ipAddress: '192.168.1.1',
/// );
/// ```
class UserAgreement extends Equatable {
  /// Unique agreement identifier
  final String id;
  
  /// User ID who agreed
  final String userId;
  
  /// Document type (terms_of_service, privacy_policy, event_waiver, host_agreement)
  final String documentType;
  
  /// Document version
  final String version;
  
  /// When user agreed
  final DateTime agreedAt;
  
  /// IP address when agreed (for legal record)
  final String? ipAddress;
  
  /// User agent (browser/device info)
  final String? userAgent;
  
  /// Event ID (if this is an event waiver)
  final String? eventId;
  
  /// Whether agreement is still active
  final bool isActive;
  
  /// When agreement was revoked (if applicable)
  final DateTime? revokedAt;
  
  /// Reason for revocation (if applicable)
  final String? revocationReason;
  
  /// When agreement was last updated
  final DateTime updatedAt;
  
  /// Optional metadata
  final Map<String, dynamic> metadata;

  const UserAgreement({
    required this.id,
    required this.userId,
    required this.documentType,
    required this.version,
    required this.agreedAt,
    this.ipAddress,
    this.userAgent,
    this.eventId,
    this.isActive = true,
    this.revokedAt,
    this.revocationReason,
    required this.updatedAt,
    this.metadata = const {},
  });

  /// Create a copy with updated fields
  UserAgreement copyWith({
    String? id,
    String? userId,
    String? documentType,
    String? version,
    DateTime? agreedAt,
    String? ipAddress,
    String? userAgent,
    String? eventId,
    bool? isActive,
    DateTime? revokedAt,
    String? revocationReason,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return UserAgreement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      documentType: documentType ?? this.documentType,
      version: version ?? this.version,
      agreedAt: agreedAt ?? this.agreedAt,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      eventId: eventId ?? this.eventId,
      isActive: isActive ?? this.isActive,
      revokedAt: revokedAt ?? this.revokedAt,
      revocationReason: revocationReason ?? this.revocationReason,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'documentType': documentType,
      'version': version,
      'agreedAt': agreedAt.toIso8601String(),
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'eventId': eventId,
      'isActive': isActive,
      'revokedAt': revokedAt?.toIso8601String(),
      'revocationReason': revocationReason,
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory UserAgreement.fromJson(Map<String, dynamic> json) {
    return UserAgreement(
      id: json['id'] as String,
      userId: json['userId'] as String,
      documentType: json['documentType'] as String,
      version: json['version'] as String,
      agreedAt: DateTime.parse(json['agreedAt'] as String),
      ipAddress: json['ipAddress'] as String?,
      userAgent: json['userAgent'] as String?,
      eventId: json['eventId'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      revokedAt: json['revokedAt'] != null
          ? DateTime.parse(json['revokedAt'] as String)
          : null,
      revocationReason: json['revocationReason'] as String?,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Check if this is an event waiver
  bool get isEventWaiver => documentType == 'event_waiver' && eventId != null;

  /// Check if this is terms of service
  bool get isTermsOfService => documentType == 'terms_of_service';

  /// Check if this is privacy policy
  bool get isPrivacyPolicy => documentType == 'privacy_policy';

  /// Check if agreement is revoked
  bool get isRevoked => revokedAt != null || !isActive;

  @override
  List<Object?> get props => [
        id,
        userId,
        documentType,
        version,
        agreedAt,
        ipAddress,
        userAgent,
        eventId,
        isActive,
        revokedAt,
        revocationReason,
        updatedAt,
        metadata,
      ];
}


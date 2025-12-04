import 'package:equatable/equatable.dart';

/// Tax Classification Enum
enum TaxClassification {
  individual,
  soleProprietor,
  partnership,
  corporation,
  llc,
}

/// Tax Profile Model
/// 
/// Represents a user's tax profile information (W-9 data).
/// 
/// **Philosophy Alignment:**
/// - Opens doors to tax compliance
/// - Enables accurate tax reporting
/// - Supports secure information handling
/// 
/// **Security Notes:**
/// - SSN/EIN stored encrypted
/// - Only accessible by authorized services
/// - Used only for tax document generation
/// 
/// **Usage:**
/// ```dart
/// final profile = TaxProfile(
///   userId: 'user-123',
///   classification: TaxClassification.individual,
///   w9Submitted: true,
///   w9SubmittedAt: DateTime.now(),
/// );
/// ```
class TaxProfile extends Equatable {
  /// User ID
  final String userId;
  
  /// Social Security Number (encrypted in production)
  /// Only last 4 digits shown in UI
  final String? ssn;
  
  /// Employer Identification Number (EIN)
  /// Used for businesses
  final String? ein;
  
  /// Business name (if applicable)
  final String? businessName;
  
  /// Tax classification
  final TaxClassification classification;
  
  /// Whether W-9 has been submitted
  final bool w9Submitted;
  
  /// When W-9 was submitted
  final DateTime? w9SubmittedAt;
  
  /// Optional metadata
  final Map<String, dynamic> metadata;

  const TaxProfile({
    required this.userId,
    this.ssn,
    this.ein,
    this.businessName,
    required this.classification,
    required this.w9Submitted,
    this.w9SubmittedAt,
    this.metadata = const {},
  });

  /// Get last 4 digits of SSN (safe for display)
  String? get ssnLast4 {
    if (ssn == null || ssn!.length < 4) return null;
    return '****-**-${ssn!.substring(ssn!.length - 4)}';
  }

  /// Get masked EIN (safe for display)
  String? get einMasked {
    if (ein == null || ein!.length < 4) return null;
    return '**-${ein!.substring(ein!.length - 4)}';
  }

  /// Create a copy with updated fields
  TaxProfile copyWith({
    String? userId,
    String? ssn,
    String? ein,
    String? businessName,
    TaxClassification? classification,
    bool? w9Submitted,
    DateTime? w9SubmittedAt,
    Map<String, dynamic>? metadata,
  }) {
    return TaxProfile(
      userId: userId ?? this.userId,
      ssn: ssn ?? this.ssn,
      ein: ein ?? this.ein,
      businessName: businessName ?? this.businessName,
      classification: classification ?? this.classification,
      w9Submitted: w9Submitted ?? this.w9Submitted,
      w9SubmittedAt: w9SubmittedAt ?? this.w9SubmittedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        ssn,
        ein,
        businessName,
        classification,
        w9Submitted,
        w9SubmittedAt,
        metadata,
      ];

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'ssn': ssn, // In production, this should be encrypted before storing
      'ein': ein,
      'businessName': businessName,
      'classification': classification.name,
      'w9Submitted': w9Submitted,
      'w9SubmittedAt': w9SubmittedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory TaxProfile.fromJson(Map<String, dynamic> json) {
    return TaxProfile(
      userId: json['userId'] as String,
      ssn: json['ssn'] as String?,
      ein: json['ein'] as String?,
      businessName: json['businessName'] as String?,
      classification: TaxClassification.values.firstWhere(
        (e) => e.name == json['classification'],
        orElse: () => TaxClassification.individual,
      ),
      w9Submitted: json['w9Submitted'] as bool? ?? false,
      w9SubmittedAt: json['w9SubmittedAt'] != null
          ? DateTime.parse(json['w9SubmittedAt'] as String)
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

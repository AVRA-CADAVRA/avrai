import 'package:equatable/equatable.dart';

/// Brand Account Model
/// 
/// Represents a brand account that can sponsor events.
/// Separate from BusinessAccount - this is specifically for brands seeking sponsorship opportunities.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to brand partnerships
/// - Enables brand discovery and matching
/// - Supports brand verification and trust
/// - Creates pathways for brand collaboration
/// 
/// **Usage:**
/// ```dart
/// final brand = BrandAccount(
///   id: 'brand-123',
///   name: 'Premium Olive Oil Co.',
///   brandType: 'Food & Beverage',
///   categories: ['Gourmet', 'Premium Products'],
///   contactEmail: 'partnerships@premiumoil.com',
///   contactPhone: '+1-555-0123',
///   verificationStatus: BrandVerificationStatus.verified,
///   stripeConnectAccountId: 'acct_1234567890',
///   createdAt: DateTime.now(),
///   updatedAt: DateTime.now(),
/// );
/// ```
class BrandAccount extends Equatable {
  /// Brand ID
  final String id;
  
  /// Brand name
  final String name;
  
  /// Brand type/category (e.g., "Food & Beverage", "Technology", "Fashion")
  final String brandType;
  
  /// Brand categories (e.g., ["Gourmet", "Premium Products"])
  final List<String> categories;
  
  /// Contact information
  final String contactEmail;
  final String? contactPhone;
  final String? contactWebsite;
  final String? contactAddress;
  
  /// Brand logo/image URL
  final String? logoUrl;
  
  /// Brand description
  final String? description;
  
  /// Verification status
  final BrandVerificationStatus verificationStatus;
  
  /// Stripe Connect account ID (for payouts)
  final String? stripeConnectAccountId;
  
  /// Brand preferences for event matching
  final Map<String, dynamic>? matchingPreferences;
  
  /// Active sponsorship count
  final int activeSponsorshipCount;
  
  /// Total sponsorship count (all time)
  final int totalSponsorshipCount;
  
  /// Metadata for additional information
  final Map<String, dynamic> metadata;
  
  /// Created timestamp
  final DateTime createdAt;
  
  /// Updated timestamp
  final DateTime updatedAt;

  const BrandAccount({
    required this.id,
    required this.name,
    required this.brandType,
    this.categories = const [],
    required this.contactEmail,
    this.contactPhone,
    this.contactWebsite,
    this.contactAddress,
    this.logoUrl,
    this.description,
    this.verificationStatus = BrandVerificationStatus.pending,
    this.stripeConnectAccountId,
    this.matchingPreferences,
    this.activeSponsorshipCount = 0,
    this.totalSponsorshipCount = 0,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if brand is verified
  bool get isVerified => verificationStatus == BrandVerificationStatus.verified;

  /// Check if brand can sponsor events
  bool get canSponsor => isVerified;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brandType': brandType,
      'categories': categories,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'contactWebsite': contactWebsite,
      'contactAddress': contactAddress,
      'logoUrl': logoUrl,
      'description': description,
      'verificationStatus': verificationStatus.name,
      'stripeConnectAccountId': stripeConnectAccountId,
      'matchingPreferences': matchingPreferences,
      'activeSponsorshipCount': activeSponsorshipCount,
      'totalSponsorshipCount': totalSponsorshipCount,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory BrandAccount.fromJson(Map<String, dynamic> json) {
    return BrandAccount(
      id: json['id'] as String,
      name: json['name'] as String,
      brandType: json['brandType'] as String,
      categories: List<String>.from(json['categories'] ?? []),
      contactEmail: json['contactEmail'] as String,
      contactPhone: json['contactPhone'] as String?,
      contactWebsite: json['contactWebsite'] as String?,
      contactAddress: json['contactAddress'] as String?,
      logoUrl: json['logoUrl'] as String?,
      description: json['description'] as String?,
      verificationStatus: BrandVerificationStatusExtension.fromString(
        json['verificationStatus'] as String? ?? 'pending',
      ),
      stripeConnectAccountId: json['stripeConnectAccountId'] as String?,
      matchingPreferences: json['matchingPreferences'] != null
          ? Map<String, dynamic>.from(json['matchingPreferences'] as Map)
          : null,
      activeSponsorshipCount:
          (json['activeSponsorshipCount'] as num?)?.toInt() ?? 0,
      totalSponsorshipCount:
          (json['totalSponsorshipCount'] as num?)?.toInt() ?? 0,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Create a copy with updated fields
  BrandAccount copyWith({
    String? id,
    String? name,
    String? brandType,
    List<String>? categories,
    String? contactEmail,
    String? contactPhone,
    String? contactWebsite,
    String? contactAddress,
    String? logoUrl,
    String? description,
    BrandVerificationStatus? verificationStatus,
    String? stripeConnectAccountId,
    Map<String, dynamic>? matchingPreferences,
    int? activeSponsorshipCount,
    int? totalSponsorshipCount,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BrandAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      brandType: brandType ?? this.brandType,
      categories: categories ?? this.categories,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      contactWebsite: contactWebsite ?? this.contactWebsite,
      contactAddress: contactAddress ?? this.contactAddress,
      logoUrl: logoUrl ?? this.logoUrl,
      description: description ?? this.description,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      stripeConnectAccountId:
          stripeConnectAccountId ?? this.stripeConnectAccountId,
      matchingPreferences: matchingPreferences ?? this.matchingPreferences,
      activeSponsorshipCount:
          activeSponsorshipCount ?? this.activeSponsorshipCount,
      totalSponsorshipCount: totalSponsorshipCount ?? this.totalSponsorshipCount,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        brandType,
        categories,
        contactEmail,
        contactPhone,
        contactWebsite,
        contactAddress,
        logoUrl,
        description,
        verificationStatus,
        stripeConnectAccountId,
        matchingPreferences,
        activeSponsorshipCount,
        totalSponsorshipCount,
        metadata,
        createdAt,
        updatedAt,
      ];
}

/// Brand Verification Status
enum BrandVerificationStatus {
  pending,    // Verification pending
  submitted,  // Verification documents submitted
  reviewing,  // Under review
  verified,   // Verified and approved
  rejected,   // Verification rejected
}

extension BrandVerificationStatusExtension on BrandVerificationStatus {
  String get displayName {
    switch (this) {
      case BrandVerificationStatus.pending:
        return 'Pending';
      case BrandVerificationStatus.submitted:
        return 'Submitted';
      case BrandVerificationStatus.reviewing:
        return 'Reviewing';
      case BrandVerificationStatus.verified:
        return 'Verified';
      case BrandVerificationStatus.rejected:
        return 'Rejected';
    }
  }

  static BrandVerificationStatus fromString(String? value) {
    if (value == null) return BrandVerificationStatus.pending;
    switch (value.toLowerCase()) {
      case 'pending':
        return BrandVerificationStatus.pending;
      case 'submitted':
        return BrandVerificationStatus.submitted;
      case 'reviewing':
        return BrandVerificationStatus.reviewing;
      case 'verified':
        return BrandVerificationStatus.verified;
      case 'rejected':
        return BrandVerificationStatus.rejected;
      default:
        return BrandVerificationStatus.pending;
    }
  }
}


import 'package:equatable/equatable.dart';

/// Sponsorship Model
/// 
/// Represents a sponsorship relationship between a brand and an event.
/// Supports financial, product, and hybrid sponsorship types.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to brand partnerships
/// - Enables multi-party event funding
/// - Supports diverse contribution types
/// - Creates pathways for brand collaboration
/// 
/// **Sponsorship Types:**
/// - Financial: Cash contribution
/// - Product: Product/in-kind contribution
/// - Hybrid: Combination of financial and product
/// 
/// **Usage:**
/// ```dart
/// final sponsorship = Sponsorship(
///   id: 'sponsor-123',
///   eventId: 'event-456',
///   brandId: 'brand-789',
///   type: SponsorshipType.financial,
///   contributionAmount: 500.00,
///   status: SponsorshipStatus.pending,
///   createdAt: DateTime.now(),
///   updatedAt: DateTime.now(),
/// );
/// ```
class Sponsorship extends Equatable {
  /// Sponsorship ID
  final String id;
  
  /// Event reference (the event being sponsored)
  final String eventId;
  
  /// Brand reference (the brand providing sponsorship)
  final String brandId;
  
  /// Sponsorship type (financial, product, hybrid)
  final SponsorshipType type;
  
  /// Contribution amount/value (for financial or hybrid)
  final double? contributionAmount;
  
  /// Product contribution value (for product or hybrid)
  final double? productValue;
  
  /// Total contribution value
  double get totalContributionValue {
    return (contributionAmount ?? 0.0) + (productValue ?? 0.0);
  }
  
  /// Sponsorship status
  final SponsorshipStatus status;
  
  /// Agreement terms (JSON structure for flexible terms)
  final Map<String, dynamic>? agreementTerms;
  
  /// Agreement version
  final String? agreementVersion;
  
  /// When agreement was signed
  final DateTime? agreementSignedAt;
  
  /// Who signed the agreement (brand representative ID)
  final String? agreementSignedBy;
  
  /// Revenue share percentage (if applicable)
  final double? revenueSharePercentage;
  
  /// Metadata for additional information
  final Map<String, dynamic> metadata;
  
  /// Created timestamp
  final DateTime createdAt;
  
  /// Updated timestamp
  final DateTime updatedAt;

  const Sponsorship({
    required this.id,
    required this.eventId,
    required this.brandId,
    required this.type,
    this.contributionAmount,
    this.productValue,
    required this.status,
    this.agreementTerms,
    this.agreementVersion,
    this.agreementSignedAt,
    this.agreementSignedBy,
    this.revenueSharePercentage,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if sponsorship is approved
  bool get isApproved => status == SponsorshipStatus.approved ||
                         status == SponsorshipStatus.active;

  /// Check if sponsorship is active
  bool get isActive => status == SponsorshipStatus.active;

  /// Check if sponsorship is locked (agreement finalized)
  bool get isLocked => status == SponsorshipStatus.locked ||
                       status == SponsorshipStatus.active;

  /// Check if sponsorship can be modified
  bool get canBeModified => status == SponsorshipStatus.pending ||
                            status == SponsorshipStatus.proposed;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'brandId': brandId,
      'type': type.name,
      'contributionAmount': contributionAmount,
      'productValue': productValue,
      'status': status.name,
      'agreementTerms': agreementTerms,
      'agreementVersion': agreementVersion,
      'agreementSignedAt': agreementSignedAt?.toIso8601String(),
      'agreementSignedBy': agreementSignedBy,
      'revenueSharePercentage': revenueSharePercentage,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory Sponsorship.fromJson(Map<String, dynamic> json) {
    return Sponsorship(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      brandId: json['brandId'] as String,
      type: SponsorshipTypeExtension.fromString(
        json['type'] as String? ?? 'financial',
      ),
      contributionAmount: (json['contributionAmount'] as num?)?.toDouble(),
      productValue: (json['productValue'] as num?)?.toDouble(),
      status: SponsorshipStatusExtension.fromString(
        json['status'] as String? ?? 'pending',
      ),
      agreementTerms: json['agreementTerms'] != null
          ? Map<String, dynamic>.from(json['agreementTerms'] as Map)
          : null,
      agreementVersion: json['agreementVersion'] as String?,
      agreementSignedAt: json['agreementSignedAt'] != null
          ? DateTime.parse(json['agreementSignedAt'] as String)
          : null,
      agreementSignedBy: json['agreementSignedBy'] as String?,
      revenueSharePercentage:
          (json['revenueSharePercentage'] as num?)?.toDouble(),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Create a copy with updated fields
  Sponsorship copyWith({
    String? id,
    String? eventId,
    String? brandId,
    SponsorshipType? type,
    double? contributionAmount,
    double? productValue,
    SponsorshipStatus? status,
    Map<String, dynamic>? agreementTerms,
    String? agreementVersion,
    DateTime? agreementSignedAt,
    String? agreementSignedBy,
    double? revenueSharePercentage,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Sponsorship(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      brandId: brandId ?? this.brandId,
      type: type ?? this.type,
      contributionAmount: contributionAmount ?? this.contributionAmount,
      productValue: productValue ?? this.productValue,
      status: status ?? this.status,
      agreementTerms: agreementTerms ?? this.agreementTerms,
      agreementVersion: agreementVersion ?? this.agreementVersion,
      agreementSignedAt: agreementSignedAt ?? this.agreementSignedAt,
      agreementSignedBy: agreementSignedBy ?? this.agreementSignedBy,
      revenueSharePercentage:
          revenueSharePercentage ?? this.revenueSharePercentage,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        eventId,
        brandId,
        type,
        contributionAmount,
        productValue,
        status,
        agreementTerms,
        agreementVersion,
        agreementSignedAt,
        agreementSignedBy,
        revenueSharePercentage,
        metadata,
        createdAt,
        updatedAt,
      ];
}

/// Sponsorship Type
enum SponsorshipType {
  financial, // Cash contribution only
  product,   // Product/in-kind contribution only
  hybrid,     // Combination of financial and product
}

extension SponsorshipTypeExtension on SponsorshipType {
  String get displayName {
    switch (this) {
      case SponsorshipType.financial:
        return 'Financial';
      case SponsorshipType.product:
        return 'Product';
      case SponsorshipType.hybrid:
        return 'Hybrid';
    }
  }

  static SponsorshipType fromString(String? value) {
    if (value == null) return SponsorshipType.financial;
    switch (value.toLowerCase()) {
      case 'financial':
        return SponsorshipType.financial;
      case 'product':
        return SponsorshipType.product;
      case 'hybrid':
        return SponsorshipType.hybrid;
      default:
        return SponsorshipType.financial;
    }
  }
}

/// Sponsorship Status
enum SponsorshipStatus {
  pending,    // Sponsorship proposed, awaiting approval
  proposed,   // Sponsorship proposal sent
  negotiating, // Terms negotiation in progress
  approved,   // Sponsorship approved by all parties
  locked,     // Agreement locked before event starts (CRITICAL)
  active,     // Sponsorship active (event in progress)
  completed,  // Sponsorship completed successfully
  cancelled,  // Sponsorship cancelled
  disputed,   // Issue requiring resolution
}

extension SponsorshipStatusExtension on SponsorshipStatus {
  String get displayName {
    switch (this) {
      case SponsorshipStatus.pending:
        return 'Pending';
      case SponsorshipStatus.proposed:
        return 'Proposed';
      case SponsorshipStatus.negotiating:
        return 'Negotiating';
      case SponsorshipStatus.approved:
        return 'Approved';
      case SponsorshipStatus.locked:
        return 'Locked';
      case SponsorshipStatus.active:
        return 'Active';
      case SponsorshipStatus.completed:
        return 'Completed';
      case SponsorshipStatus.cancelled:
        return 'Cancelled';
      case SponsorshipStatus.disputed:
        return 'Disputed';
    }
  }

  static SponsorshipStatus fromString(String? value) {
    if (value == null) return SponsorshipStatus.pending;
    switch (value.toLowerCase()) {
      case 'pending':
        return SponsorshipStatus.pending;
      case 'proposed':
        return SponsorshipStatus.proposed;
      case 'negotiating':
        return SponsorshipStatus.negotiating;
      case 'approved':
        return SponsorshipStatus.approved;
      case 'locked':
        return SponsorshipStatus.locked;
      case 'active':
        return SponsorshipStatus.active;
      case 'completed':
        return SponsorshipStatus.completed;
      case 'cancelled':
        return SponsorshipStatus.cancelled;
      case 'disputed':
        return SponsorshipStatus.disputed;
      default:
        return SponsorshipStatus.pending;
    }
  }
}


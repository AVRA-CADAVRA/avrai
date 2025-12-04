import 'package:equatable/equatable.dart';
import 'package:spots/core/models/revenue_split.dart';

/// Multi-Party Sponsorship Model
/// 
/// Represents a sponsorship with multiple brands (N-way partnerships).
/// Supports complex revenue split configurations across multiple sponsors.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to multi-party brand partnerships
/// - Enables complex revenue sharing agreements
/// - Supports N-way sponsorship configurations
/// - Creates pathways for collaborative brand events
/// 
/// **Usage:**
/// ```dart
/// final multiParty = MultiPartySponsorship(
///   id: 'multi-sponsor-123',
///   eventId: 'event-456',
///   brandIds: ['brand-1', 'brand-2', 'brand-3'],
///   revenueSplitId: 'split-789',
///   agreementStatus: MultiPartyAgreementStatus.approved,
///   createdAt: DateTime.now(),
///   updatedAt: DateTime.now(),
/// );
/// ```
class MultiPartySponsorship extends Equatable {
  /// Sponsorship ID
  final String id;
  
  /// Event reference (the event being sponsored)
  final String eventId;
  
  /// Multiple brand references (N-way)
  final List<String> brandIds;
  
  /// Revenue split configuration reference
  final String? revenueSplitId;
  
  /// Revenue split object (loaded separately)
  final RevenueSplit? revenueSplit;
  
  /// Agreement status
  final MultiPartyAgreementStatus agreementStatus;
  
  /// Agreement terms (JSON structure for flexible terms)
  final Map<String, dynamic>? agreementTerms;
  
  /// Agreement version
  final String? agreementVersion;
  
  /// When agreement was signed
  final DateTime? agreementSignedAt;
  
  /// Who signed the agreement (list of brand representative IDs)
  final List<String> agreementSignedBy;
  
  /// Revenue split configuration (map of brandId -> percentage)
  final Map<String, double> revenueSplitConfiguration;
  
  /// Total contribution value (sum of all brand contributions)
  final double totalContributionValue;
  
  /// Metadata for additional information
  final Map<String, dynamic> metadata;
  
  /// Created timestamp
  final DateTime createdAt;
  
  /// Updated timestamp
  final DateTime updatedAt;

  const MultiPartySponsorship({
    required this.id,
    required this.eventId,
    required this.brandIds,
    this.revenueSplitId,
    this.revenueSplit,
    required this.agreementStatus,
    this.agreementTerms,
    this.agreementVersion,
    this.agreementSignedAt,
    this.agreementSignedBy = const [],
    this.revenueSplitConfiguration = const {},
    this.totalContributionValue = 0.0,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get number of brands in this sponsorship
  int get brandCount => brandIds.length;

  /// Check if sponsorship is approved by all parties
  bool get isApproved => agreementStatus == MultiPartyAgreementStatus.approved ||
                         agreementStatus == MultiPartyAgreementStatus.locked ||
                         agreementStatus == MultiPartyAgreementStatus.active;

  /// Check if sponsorship is active
  bool get isActive => agreementStatus == MultiPartyAgreementStatus.active;

  /// Check if sponsorship is locked (agreement finalized)
  bool get isLocked => agreementStatus == MultiPartyAgreementStatus.locked ||
                       agreementStatus == MultiPartyAgreementStatus.active;

  /// Check if sponsorship can be modified
  bool get canBeModified => agreementStatus == MultiPartyAgreementStatus.pending ||
                             agreementStatus == MultiPartyAgreementStatus.proposed ||
                             agreementStatus == MultiPartyAgreementStatus.negotiating;

  /// Verify revenue split configuration adds up to 100%
  bool get isRevenueSplitValid {
    if (revenueSplitConfiguration.isEmpty) return false;
    final total = revenueSplitConfiguration.values.fold<double>(
      0.0,
      (sum, percentage) => sum + percentage,
    );
    return (total - 100.0).abs() < 0.01;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'brandIds': brandIds,
      'revenueSplitId': revenueSplitId,
      'revenueSplit': revenueSplit?.toJson(),
      'agreementStatus': agreementStatus.name,
      'agreementTerms': agreementTerms,
      'agreementVersion': agreementVersion,
      'agreementSignedAt': agreementSignedAt?.toIso8601String(),
      'agreementSignedBy': agreementSignedBy,
      'revenueSplitConfiguration': revenueSplitConfiguration,
      'totalContributionValue': totalContributionValue,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory MultiPartySponsorship.fromJson(Map<String, dynamic> json) {
    return MultiPartySponsorship(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      brandIds: List<String>.from(json['brandIds'] ?? []),
      revenueSplitId: json['revenueSplitId'] as String?,
      revenueSplit: json['revenueSplit'] != null
          ? RevenueSplit.fromJson(
              json['revenueSplit'] as Map<String, dynamic>,
            )
          : null,
      agreementStatus: MultiPartyAgreementStatusExtension.fromString(
        json['agreementStatus'] as String? ?? 'pending',
      ),
      agreementTerms: json['agreementTerms'] != null
          ? Map<String, dynamic>.from(json['agreementTerms'] as Map)
          : null,
      agreementVersion: json['agreementVersion'] as String?,
      agreementSignedAt: json['agreementSignedAt'] != null
          ? DateTime.parse(json['agreementSignedAt'] as String)
          : null,
      agreementSignedBy: List<String>.from(json['agreementSignedBy'] ?? []),
      revenueSplitConfiguration: json['revenueSplitConfiguration'] != null
          ? Map<String, double>.from(
              (json['revenueSplitConfiguration'] as Map).map(
                (key, value) => MapEntry(key as String, (value as num).toDouble()),
              ),
            )
          : {},
      totalContributionValue:
          (json['totalContributionValue'] as num?)?.toDouble() ?? 0.0,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Create a copy with updated fields
  MultiPartySponsorship copyWith({
    String? id,
    String? eventId,
    List<String>? brandIds,
    String? revenueSplitId,
    RevenueSplit? revenueSplit,
    MultiPartyAgreementStatus? agreementStatus,
    Map<String, dynamic>? agreementTerms,
    String? agreementVersion,
    DateTime? agreementSignedAt,
    List<String>? agreementSignedBy,
    Map<String, double>? revenueSplitConfiguration,
    double? totalContributionValue,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MultiPartySponsorship(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      brandIds: brandIds ?? this.brandIds,
      revenueSplitId: revenueSplitId ?? this.revenueSplitId,
      revenueSplit: revenueSplit ?? this.revenueSplit,
      agreementStatus: agreementStatus ?? this.agreementStatus,
      agreementTerms: agreementTerms ?? this.agreementTerms,
      agreementVersion: agreementVersion ?? this.agreementVersion,
      agreementSignedAt: agreementSignedAt ?? this.agreementSignedAt,
      agreementSignedBy: agreementSignedBy ?? this.agreementSignedBy,
      revenueSplitConfiguration:
          revenueSplitConfiguration ?? this.revenueSplitConfiguration,
      totalContributionValue:
          totalContributionValue ?? this.totalContributionValue,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        eventId,
        brandIds,
        revenueSplitId,
        revenueSplit,
        agreementStatus,
        agreementTerms,
        agreementVersion,
        agreementSignedAt,
        agreementSignedBy,
        revenueSplitConfiguration,
        totalContributionValue,
        metadata,
        createdAt,
        updatedAt,
      ];
}

/// Multi-Party Agreement Status
enum MultiPartyAgreementStatus {
  pending,     // Agreement pending, awaiting all parties
  proposed,   // Agreement proposed to all parties
  negotiating, // Terms negotiation in progress
  approved,   // All parties approved
  locked,     // Agreement locked before event starts (CRITICAL)
  active,     // Agreement active (event in progress)
  completed,  // Agreement completed successfully
  cancelled,  // Agreement cancelled
  disputed,   // Issue requiring resolution
}

extension MultiPartyAgreementStatusExtension on MultiPartyAgreementStatus {
  String get displayName {
    switch (this) {
      case MultiPartyAgreementStatus.pending:
        return 'Pending';
      case MultiPartyAgreementStatus.proposed:
        return 'Proposed';
      case MultiPartyAgreementStatus.negotiating:
        return 'Negotiating';
      case MultiPartyAgreementStatus.approved:
        return 'Approved';
      case MultiPartyAgreementStatus.locked:
        return 'Locked';
      case MultiPartyAgreementStatus.active:
        return 'Active';
      case MultiPartyAgreementStatus.completed:
        return 'Completed';
      case MultiPartyAgreementStatus.cancelled:
        return 'Cancelled';
      case MultiPartyAgreementStatus.disputed:
        return 'Disputed';
    }
  }

  static MultiPartyAgreementStatus fromString(String? value) {
    if (value == null) return MultiPartyAgreementStatus.pending;
    switch (value.toLowerCase()) {
      case 'pending':
        return MultiPartyAgreementStatus.pending;
      case 'proposed':
        return MultiPartyAgreementStatus.proposed;
      case 'negotiating':
        return MultiPartyAgreementStatus.negotiating;
      case 'approved':
        return MultiPartyAgreementStatus.approved;
      case 'locked':
        return MultiPartyAgreementStatus.locked;
      case 'active':
        return MultiPartyAgreementStatus.active;
      case 'completed':
        return MultiPartyAgreementStatus.completed;
      case 'cancelled':
        return MultiPartyAgreementStatus.cancelled;
      case 'disputed':
        return MultiPartyAgreementStatus.disputed;
      default:
        return MultiPartyAgreementStatus.pending;
    }
  }
}


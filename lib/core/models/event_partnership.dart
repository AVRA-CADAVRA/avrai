import 'package:equatable/equatable.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/business_account.dart';
import 'package:spots/core/models/revenue_split.dart';

/// Event Partnership Model
/// 
/// Represents a partnership between a user (expert) and a business for hosting events.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to business partnerships
/// - Enables multi-party event hosting
/// - Supports revenue sharing agreements
/// - Creates pathways for business collaboration
/// 
/// **Partnership Workflow:**
/// 1. Discovery - AI suggests compatible partners (70%+ vibe match only)
/// 2. Proposal - One party proposes partnership with revenue split
/// 3. Negotiation - Revenue split discussion (can counter-propose)
/// 4. Agreement - ALL parties must approve and LOCK before event starts
/// 5. Execution - Event happens
/// 6. Payment - Automatic revenue distribution (2 days after event)
/// 7. Feedback - Mutual ratings (both can rate each other)
class EventPartnership extends Equatable {
  /// Partnership ID
  final String id;
  
  /// Event reference (the event this partnership is for)
  final String eventId;
  
  /// Partners (user + business)
  final String userId; // Expert/User ID
  final String businessId; // Business ID
  
  /// Partner objects (loaded separately)
  final UnifiedUser? user;
  final BusinessAccount? business;
  
  /// Partnership status
  final PartnershipStatus status;
  
  /// Agreement terms
  final PartnershipAgreement? agreement;
  
  /// Revenue split reference (if paid event)
  final String? revenueSplitId;
  final RevenueSplit? revenueSplit;
  
  /// Partnership type
  final PartnershipType type;
  
  /// Partnership scope
  final List<String> sharedResponsibilities;
  final String? venueLocation;
  final int? expectedEventCount; // For ongoing partnerships
  
  /// Events under this partnership
  final List<String> eventIds;
  
  /// Terms and agreement
  final DateTime? termsAgreedAt;
  final String? termsVersion;
  final bool userApproved;
  final bool businessApproved;
  
  /// Vibe compatibility score (70%+ required for suggestions)
  final double? vibeCompatibilityScore;
  
  /// Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startDate;
  final DateTime? endDate; // For term-limited partnerships

  const EventPartnership({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.businessId,
    this.user,
    this.business,
    this.status = PartnershipStatus.pending,
    this.agreement,
    this.revenueSplitId,
    this.revenueSplit,
    this.type = PartnershipType.eventBased,
    this.sharedResponsibilities = const [],
    this.venueLocation,
    this.expectedEventCount,
    this.eventIds = const [],
    this.termsAgreedAt,
    this.termsVersion,
    this.userApproved = false,
    this.businessApproved = false,
    this.vibeCompatibilityScore,
    required this.createdAt,
    required this.updatedAt,
    this.startDate,
    this.endDate,
  });

  /// Check if partnership is approved by all parties
  bool get isApproved => userApproved && businessApproved;

  /// Check if partnership is locked (agreement finalized before event)
  bool get isLocked => 
      status == PartnershipStatus.locked || 
      status == PartnershipStatus.active;

  /// Check if partnership can be modified
  bool get canBeModified => 
      status == PartnershipStatus.pending || 
      status == PartnershipStatus.proposed;

  /// Check if partnership is active
  bool get isActive => status == PartnershipStatus.active;

  /// Check if partnership is completed
  bool get isCompleted => status == PartnershipStatus.completed;

  /// Check if partnership is cancelled
  bool get isCancelled => status == PartnershipStatus.cancelled;

  /// Check if partnership is disputed
  bool get isDisputed => status == PartnershipStatus.disputed;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'userId': userId,
      'businessId': businessId,
      'status': status.name,
      'agreement': agreement?.toJson(),
      'revenueSplitId': revenueSplitId,
      'revenueSplit': revenueSplit?.toJson(),
      'type': type.name,
      'sharedResponsibilities': sharedResponsibilities,
      'venueLocation': venueLocation,
      'expectedEventCount': expectedEventCount,
      'eventIds': eventIds,
      'termsAgreedAt': termsAgreedAt?.toIso8601String(),
      'termsVersion': termsVersion,
      'userApproved': userApproved,
      'businessApproved': businessApproved,
      'vibeCompatibilityScore': vibeCompatibilityScore,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory EventPartnership.fromJson(Map<String, dynamic> json) {
    return EventPartnership(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      userId: json['userId'] as String,
      businessId: json['businessId'] as String,
      status: PartnershipStatusExtension.fromString(
        json['status'] as String? ?? 'pending',
      ),
      agreement: json['agreement'] != null
          ? PartnershipAgreement.fromJson(
              json['agreement'] as Map<String, dynamic>,
            )
          : null,
      revenueSplitId: json['revenueSplitId'] as String?,
      revenueSplit: json['revenueSplit'] != null
          ? RevenueSplit.fromJson(
              json['revenueSplit'] as Map<String, dynamic>,
            )
          : null,
      type: PartnershipTypeExtension.fromString(
        json['type'] as String? ?? 'eventBased',
      ),
      sharedResponsibilities: List<String>.from(
        json['sharedResponsibilities'] ?? [],
      ),
      venueLocation: json['venueLocation'] as String?,
      expectedEventCount: json['expectedEventCount'] as int?,
      eventIds: List<String>.from(json['eventIds'] ?? []),
      termsAgreedAt: json['termsAgreedAt'] != null
          ? DateTime.parse(json['termsAgreedAt'] as String)
          : null,
      termsVersion: json['termsVersion'] as String?,
      userApproved: json['userApproved'] as bool? ?? false,
      businessApproved: json['businessApproved'] as bool? ?? false,
      vibeCompatibilityScore: (json['vibeCompatibilityScore'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
    );
  }

  /// Copy with method
  EventPartnership copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? businessId,
    UnifiedUser? user,
    BusinessAccount? business,
    PartnershipStatus? status,
    PartnershipAgreement? agreement,
    String? revenueSplitId,
    RevenueSplit? revenueSplit,
    PartnershipType? type,
    List<String>? sharedResponsibilities,
    String? venueLocation,
    int? expectedEventCount,
    List<String>? eventIds,
    DateTime? termsAgreedAt,
    String? termsVersion,
    bool? userApproved,
    bool? businessApproved,
    double? vibeCompatibilityScore,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return EventPartnership(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      businessId: businessId ?? this.businessId,
      user: user ?? this.user,
      business: business ?? this.business,
      status: status ?? this.status,
      agreement: agreement ?? this.agreement,
      revenueSplitId: revenueSplitId ?? this.revenueSplitId,
      revenueSplit: revenueSplit ?? this.revenueSplit,
      type: type ?? this.type,
      sharedResponsibilities: sharedResponsibilities ?? this.sharedResponsibilities,
      venueLocation: venueLocation ?? this.venueLocation,
      expectedEventCount: expectedEventCount ?? this.expectedEventCount,
      eventIds: eventIds ?? this.eventIds,
      termsAgreedAt: termsAgreedAt ?? this.termsAgreedAt,
      termsVersion: termsVersion ?? this.termsVersion,
      userApproved: userApproved ?? this.userApproved,
      businessApproved: businessApproved ?? this.businessApproved,
      vibeCompatibilityScore: vibeCompatibilityScore ?? this.vibeCompatibilityScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  List<Object?> get props => [
        id,
        eventId,
        userId,
        businessId,
        user,
        business,
        status,
        agreement,
        revenueSplitId,
        revenueSplit,
        type,
        sharedResponsibilities,
        venueLocation,
        expectedEventCount,
        eventIds,
        termsAgreedAt,
        termsVersion,
        userApproved,
        businessApproved,
        vibeCompatibilityScore,
        createdAt,
        updatedAt,
        startDate,
        endDate,
      ];
}

/// Partnership Status
enum PartnershipStatus {
  pending,      // Partnership proposed, awaiting approval
  proposed,     // Partnership proposal sent
  negotiating,  // Revenue split negotiation in progress
  approved,     // All parties approved, ready to lock
  locked,       // Agreement locked before event starts (CRITICAL)
  active,       // Partnership active (event in progress)
  completed,    // Partnership completed successfully
  cancelled,    // Partnership cancelled
  disputed,     // Issue requiring resolution
}

extension PartnershipStatusExtension on PartnershipStatus {
  String get displayName {
    switch (this) {
      case PartnershipStatus.pending:
        return 'Pending';
      case PartnershipStatus.proposed:
        return 'Proposed';
      case PartnershipStatus.negotiating:
        return 'Negotiating';
      case PartnershipStatus.approved:
        return 'Approved';
      case PartnershipStatus.locked:
        return 'Locked';
      case PartnershipStatus.active:
        return 'Active';
      case PartnershipStatus.completed:
        return 'Completed';
      case PartnershipStatus.cancelled:
        return 'Cancelled';
      case PartnershipStatus.disputed:
        return 'Disputed';
    }
  }

  static PartnershipStatus fromString(String? value) {
    if (value == null) return PartnershipStatus.pending;
    switch (value.toLowerCase()) {
      case 'pending':
        return PartnershipStatus.pending;
      case 'proposed':
        return PartnershipStatus.proposed;
      case 'negotiating':
        return PartnershipStatus.negotiating;
      case 'approved':
        return PartnershipStatus.approved;
      case 'locked':
        return PartnershipStatus.locked;
      case 'active':
        return PartnershipStatus.active;
      case 'completed':
        return PartnershipStatus.completed;
      case 'cancelled':
        return PartnershipStatus.cancelled;
      case 'disputed':
        return PartnershipStatus.disputed;
      default:
        return PartnershipStatus.pending;
    }
  }
}

/// Partnership Type
enum PartnershipType {
  eventBased,   // Single event partnership
  ongoing,      // Ongoing partnership (multiple events)
  exclusive,    // Exclusive partnership (only with this partner)
}

extension PartnershipTypeExtension on PartnershipType {
  String get displayName {
    switch (this) {
      case PartnershipType.eventBased:
        return 'Event-Based';
      case PartnershipType.ongoing:
        return 'Ongoing';
      case PartnershipType.exclusive:
        return 'Exclusive';
    }
  }

  static PartnershipType fromString(String? value) {
    if (value == null) return PartnershipType.eventBased;
    switch (value.toLowerCase()) {
      case 'eventbased':
      case 'event_based':
        return PartnershipType.eventBased;
      case 'ongoing':
        return PartnershipType.ongoing;
      case 'exclusive':
        return PartnershipType.exclusive;
      default:
        return PartnershipType.eventBased;
    }
  }
}

/// Partnership Agreement
/// Contains the terms and conditions of the partnership
class PartnershipAgreement extends Equatable {
  final String id;
  final String partnershipId;
  final Map<String, dynamic> terms; // Flexible terms structure
  final String? customArrangementDetails;
  final DateTime agreedAt;
  final String agreedBy; // User ID who agreed
  final String version;

  const PartnershipAgreement({
    required this.id,
    required this.partnershipId,
    required this.terms,
    this.customArrangementDetails,
    required this.agreedAt,
    required this.agreedBy,
    this.version = '1.0',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partnershipId': partnershipId,
      'terms': terms,
      'customArrangementDetails': customArrangementDetails,
      'agreedAt': agreedAt.toIso8601String(),
      'agreedBy': agreedBy,
      'version': version,
    };
  }

  factory PartnershipAgreement.fromJson(Map<String, dynamic> json) {
    return PartnershipAgreement(
      id: json['id'] as String,
      partnershipId: json['partnershipId'] as String,
      terms: Map<String, dynamic>.from(json['terms'] as Map),
      customArrangementDetails: json['customArrangementDetails'] as String?,
      agreedAt: DateTime.parse(json['agreedAt'] as String),
      agreedBy: json['agreedBy'] as String,
      version: json['version'] as String? ?? '1.0',
    );
  }

  @override
  List<Object?> get props => [
        id,
        partnershipId,
        terms,
        customArrangementDetails,
        agreedAt,
        agreedBy,
        version,
      ];
}


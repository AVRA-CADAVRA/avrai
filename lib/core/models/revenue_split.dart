import 'package:equatable/equatable.dart';

/// Revenue Split Model
/// 
/// Represents the revenue split calculation for an event.
/// Supports N-way splits for multi-party partnerships.
/// 
/// **Revenue Split Breakdown:**
/// - Platform Fee: 10% to SPOTS
/// - Processing Fee: ~3% to Stripe (2.9% + $0.30 per transaction)
/// - Split parties: N-way distribution (user, business, sponsors, etc.)
/// 
/// **Philosophy Alignment:**
/// - Opens doors to multi-party partnerships
/// - Enables transparent revenue sharing
/// - Supports pre-event agreement locking
/// 
/// **Usage:**
/// ```dart
/// // Solo event
/// final revenueSplit = RevenueSplit(
///   eventId: 'event-123',
///   totalAmount: 100.00,
///   platformFee: 10.00, // 10%
///   processingFee: 3.20, // ~3% + $0.30
///   hostPayout: 86.80, // Remaining
///   calculatedAt: DateTime.now(),
/// );
/// 
/// // N-way partnership
/// final partnershipSplit = RevenueSplit.nWay(
///   eventId: 'event-456',
///   totalAmount: 1000.00,
///   ticketsSold: 20,
///   parties: [
///     SplitParty(userId: 'user-1', percentage: 50.0),
///     SplitParty(businessId: 'biz-1', percentage: 30.0),
///     SplitParty(sponsorId: 'sponsor-1', percentage: 20.0),
///   ],
/// );
/// ```
class RevenueSplit extends Equatable {
  /// Split ID
  final String id;
  
  /// Event ID this revenue split is for
  final String eventId;
  
  /// Partnership reference (if part of a partnership)
  final String? partnershipId;
  
  /// Total amount collected from ticket sales
  final double totalAmount;
  
  /// Platform fee (10% to SPOTS)
  final double platformFee;
  
  /// Processing fee (~3% to Stripe: 2.9% + $0.30 per transaction)
  final double processingFee;
  
  /// Amount paid out to host (remaining after fees) - Legacy field for solo events
  final double? hostPayout;
  
  /// Split parties (N-way) - For multi-party partnerships
  final List<SplitParty> parties;
  
  /// Locked status (pre-event) - CRITICAL: Cannot be changed after event starts
  final bool isLocked;
  
  /// When split was locked (before event starts)
  final DateTime? lockedAt;
  
  /// Who locked the split (user ID)
  final String? lockedBy;
  
  /// When revenue split was calculated
  final DateTime calculatedAt;
  
  /// Number of tickets sold
  final int ticketsSold;
  
  /// Optional metadata
  final Map<String, dynamic> metadata;

  const RevenueSplit({
    required this.id,
    required this.eventId,
    this.partnershipId,
    required this.totalAmount,
    required this.platformFee,
    required this.processingFee,
    this.hostPayout,
    this.parties = const [],
    this.isLocked = false,
    this.lockedAt,
    this.lockedBy,
    required this.calculatedAt,
    this.ticketsSold = 0,
    this.metadata = const {},
  });

  /// Create a copy with updated fields
  RevenueSplit copyWith({
    String? id,
    String? eventId,
    String? partnershipId,
    double? totalAmount,
    double? platformFee,
    double? processingFee,
    double? hostPayout,
    List<SplitParty>? parties,
    bool? isLocked,
    DateTime? lockedAt,
    String? lockedBy,
    DateTime? calculatedAt,
    int? ticketsSold,
    Map<String, dynamic>? metadata,
  }) {
    return RevenueSplit(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      partnershipId: partnershipId ?? this.partnershipId,
      totalAmount: totalAmount ?? this.totalAmount,
      platformFee: platformFee ?? this.platformFee,
      processingFee: processingFee ?? this.processingFee,
      hostPayout: hostPayout ?? this.hostPayout,
      parties: parties ?? this.parties,
      isLocked: isLocked ?? this.isLocked,
      lockedAt: lockedAt ?? this.lockedAt,
      lockedBy: lockedBy ?? this.lockedBy,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      ticketsSold: ticketsSold ?? this.ticketsSold,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'partnershipId': partnershipId,
      'totalAmount': totalAmount,
      'platformFee': platformFee,
      'processingFee': processingFee,
      'hostPayout': hostPayout,
      'parties': parties.map((p) => p.toJson()).toList(),
      'isLocked': isLocked,
      'lockedAt': lockedAt?.toIso8601String(),
      'lockedBy': lockedBy,
      'calculatedAt': calculatedAt.toIso8601String(),
      'ticketsSold': ticketsSold,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory RevenueSplit.fromJson(Map<String, dynamic> json) {
    return RevenueSplit(
      id: json['id'] as String? ?? json['eventId'] as String, // Fallback for legacy
      eventId: json['eventId'] as String,
      partnershipId: json['partnershipId'] as String?,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      platformFee: (json['platformFee'] as num).toDouble(),
      processingFee: (json['processingFee'] as num).toDouble(),
      hostPayout: (json['hostPayout'] as num?)?.toDouble(),
      parties: (json['parties'] as List?)
          ?.map((p) => SplitParty.fromJson(p as Map<String, dynamic>))
          .toList() ??
          [],
      isLocked: json['isLocked'] as bool? ?? false,
      lockedAt: json['lockedAt'] != null
          ? DateTime.parse(json['lockedAt'] as String)
          : null,
      lockedBy: json['lockedBy'] as String?,
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
      ticketsSold: json['ticketsSold'] as int? ?? 0,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Calculate revenue split from total amount (solo event)
  /// 
  /// **Formula:**
  /// - Platform Fee: 10% of total
  /// - Processing Fee: (2.9% of total) + ($0.30 * ticketsSold)
  /// - Host Payout: Total - Platform Fee - Processing Fee
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID
  /// - `totalAmount`: Total revenue in dollars
  /// - `ticketsSold`: Number of tickets sold (for Stripe fixed fee calculation)
  /// 
  /// **Returns:**
  /// RevenueSplit with calculated fees
  factory RevenueSplit.calculate({
    required String eventId,
    required double totalAmount,
    required int ticketsSold,
    DateTime? calculatedAt,
  }) {
    // Platform fee: 10%
    final platformFee = totalAmount * 0.10;
    
    // Processing fee: 2.9% + $0.30 per transaction
    final processingFeePercentage = totalAmount * 0.029;
    final processingFeeFixed = ticketsSold * 0.30;
    final processingFee = processingFeePercentage + processingFeeFixed;
    
    // Host payout: remaining amount
    final hostPayout = totalAmount - platformFee - processingFee;
    
    return RevenueSplit(
      id: eventId, // Use eventId as ID for solo events
      eventId: eventId,
      totalAmount: totalAmount,
      platformFee: platformFee,
      processingFee: processingFee,
      hostPayout: hostPayout,
      calculatedAt: calculatedAt ?? DateTime.now(),
      ticketsSold: ticketsSold,
    );
  }

  /// Calculate N-way revenue split for partnerships
  /// 
  /// **Formula:**
  /// - Platform Fee: 10% of total
  /// - Processing Fee: (2.9% of total) + ($0.30 * ticketsSold)
  /// - Split Amount: Total - Platform Fee - Processing Fee
  /// - Each party gets: Split Amount * (party percentage / 100)
  /// 
  /// **Parameters:**
  /// - `id`: Split ID
  /// - `eventId`: Event ID
  /// - `partnershipId`: Partnership ID (if part of partnership)
  /// - `totalAmount`: Total revenue in dollars
  /// - `ticketsSold`: Number of tickets sold
  /// - `parties`: List of split parties with percentages
  /// 
  /// **Returns:**
  /// RevenueSplit with N-way distribution
  factory RevenueSplit.nWay({
    required String id,
    required String eventId,
    String? partnershipId,
    required double totalAmount,
    required int ticketsSold,
    required List<SplitParty> parties,
    DateTime? calculatedAt,
  }) {
    // Platform fee: 10%
    final platformFee = totalAmount * 0.10;
    
    // Processing fee: 2.9% + $0.30 per transaction
    final processingFeePercentage = totalAmount * 0.029;
    final processingFeeFixed = ticketsSold * 0.30;
    final processingFee = processingFeePercentage + processingFeeFixed;
    
    // Split amount: remaining after fees
    final splitAmount = totalAmount - platformFee - processingFee;
    
    // Calculate amounts for each party
    final calculatedParties = parties.map((party) {
      final amount = splitAmount * (party.percentage / 100.0);
      return party.copyWith(amount: amount);
    }).toList();
    
    return RevenueSplit(
      id: id,
      eventId: eventId,
      partnershipId: partnershipId,
      totalAmount: totalAmount,
      platformFee: platformFee,
      processingFee: processingFee,
      parties: calculatedParties,
      calculatedAt: calculatedAt ?? DateTime.now(),
      ticketsSold: ticketsSold,
    );
  }

  /// Get platform fee percentage
  double get platformFeePercentage => totalAmount > 0 
      ? (platformFee / totalAmount) * 100 
      : 0.0;

  /// Get processing fee percentage
  double get processingFeePercentage => totalAmount > 0 
      ? (processingFee / totalAmount) * 100 
      : 0.0;

  /// Get host payout percentage (for solo events)
  double get hostPayoutPercentage => totalAmount > 0 && hostPayout != null
      ? (hostPayout! / totalAmount) * 100 
      : 0.0;

  /// Get split amount (total after fees, for N-way splits)
  double get splitAmount => totalAmount - platformFee - processingFee;

  /// Verify that fees add up correctly
  bool get isValid {
    if (parties.isNotEmpty) {
      // N-way split: verify parties add up to 100%
      final totalPercentage = parties.fold<double>(
        0.0,
        (sum, party) => sum + party.percentage,
      );
      final percentageValid = (totalPercentage - 100.0).abs() < 0.01;
      
      // Verify amounts add up to split amount
      final totalAmounts = parties.fold<double>(
        0.0,
        (sum, party) => sum + (party.amount ?? 0.0),
      );
      final amountsValid = (splitAmount - totalAmounts).abs() < 0.01;
      
      return percentageValid && amountsValid;
    } else {
      // Solo event: verify host payout
      if (hostPayout == null) return false;
      final sum = platformFee + processingFee + hostPayout!;
      final difference = (totalAmount - sum).abs();
      return difference < 0.01;
    }
  }

  /// Lock the split (pre-event) - CRITICAL: Cannot be changed after event starts
  RevenueSplit lock({required String lockedBy, DateTime? lockedAt}) {
    if (isLocked) {
      throw StateError('Revenue split is already locked');
    }
    return copyWith(
      isLocked: true,
      lockedAt: lockedAt ?? DateTime.now(),
      lockedBy: lockedBy,
    );
  }

  /// Check if split can be modified
  bool get canBeModified => !isLocked;

  @override
  List<Object?> get props => [
        id,
        eventId,
        partnershipId,
        totalAmount,
        platformFee,
        processingFee,
        hostPayout,
        parties,
        isLocked,
        lockedAt,
        lockedBy,
        calculatedAt,
        ticketsSold,
        metadata,
      ];
}

/// Split Party
/// Represents one party in an N-way revenue split
class SplitParty extends Equatable {
  /// Party ID (userId, businessId, sponsorId, etc.)
  final String partyId;
  
  /// Party type
  final SplitPartyType type;
  
  /// Percentage of split (0-100)
  final double percentage;
  
  /// Calculated amount (set after calculation)
  final double? amount;
  
  /// Party name (for display)
  final String? name;
  
  /// Optional metadata
  final Map<String, dynamic> metadata;

  const SplitParty({
    required this.partyId,
    required this.type,
    required this.percentage,
    this.amount,
    this.name,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'partyId': partyId,
      'type': type.name,
      'percentage': percentage,
      'amount': amount,
      'name': name,
      'metadata': metadata,
    };
  }

  factory SplitParty.fromJson(Map<String, dynamic> json) {
    return SplitParty(
      partyId: json['partyId'] as String,
      type: SplitPartyTypeExtension.fromString(
        json['type'] as String? ?? 'user',
      ),
      percentage: (json['percentage'] as num).toDouble(),
      amount: (json['amount'] as num?)?.toDouble(),
      name: json['name'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  SplitParty copyWith({
    String? partyId,
    SplitPartyType? type,
    double? percentage,
    double? amount,
    String? name,
    Map<String, dynamic>? metadata,
  }) {
    return SplitParty(
      partyId: partyId ?? this.partyId,
      type: type ?? this.type,
      percentage: percentage ?? this.percentage,
      amount: amount ?? this.amount,
      name: name ?? this.name,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        partyId,
        type,
        percentage,
        amount,
        name,
        metadata,
      ];
}

/// Split Party Type
enum SplitPartyType {
  user,       // User/Expert
  business,   // Business/Venue
  sponsor,    // Sponsor/Company
  other,      // Other party type
}

extension SplitPartyTypeExtension on SplitPartyType {
  String get displayName {
    switch (this) {
      case SplitPartyType.user:
        return 'User';
      case SplitPartyType.business:
        return 'Business';
      case SplitPartyType.sponsor:
        return 'Sponsor';
      case SplitPartyType.other:
        return 'Other';
    }
  }

  static SplitPartyType fromString(String? value) {
    if (value == null) return SplitPartyType.user;
    switch (value.toLowerCase()) {
      case 'user':
        return SplitPartyType.user;
      case 'business':
        return SplitPartyType.business;
      case 'sponsor':
        return SplitPartyType.sponsor;
      case 'other':
        return SplitPartyType.other;
      default:
        return SplitPartyType.user;
    }
  }
}


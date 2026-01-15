// Reservation Model
//
// Phase 15: Reservation System Implementation
// Section 15.1: Foundation - Models & Core Service
// Enhanced with Quantum Entanglement Integration
//
// Represents a reservation to a spot, business, or event in SPOTS.
// Includes quantum state for matching and compatibility calculations.

import 'package:equatable/equatable.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/quantum_entity_state.dart';

/// Reservation Type
enum ReservationType {
  /// Reservation at a spot (restaurant, bar, venue)
  spot,

  /// Reservation with a business account
  business,

  /// Reservation for an event
  event,
}

/// Reservation Status
enum ReservationStatus {
  /// Awaiting confirmation
  pending,

  /// Confirmed by business/spot
  confirmed,

  /// Cancelled (by user or business)
  cancelled,

  /// Reservation fulfilled
  completed,

  /// User didn't show up
  noShow,
}

/// Cancellation Policy
class CancellationPolicy extends Equatable {
  /// Hours before reservation that cancellation is allowed
  final int hoursBefore;

  /// Whether full refund is available
  final bool fullRefund;

  /// Whether partial refund is available
  final bool partialRefund;

  /// Refund percentage (0.0 to 1.0) if partial refund
  final double? refundPercentage;

  /// Whether cancellation fee applies
  final bool hasCancellationFee;

  /// Cancellation fee amount (if applicable)
  final double? cancellationFee;

  const CancellationPolicy({
    required this.hoursBefore,
    this.fullRefund = true,
    this.partialRefund = false,
    this.refundPercentage,
    this.hasCancellationFee = false,
    this.cancellationFee,
  });

  /// Default 24-hour cancellation policy
  factory CancellationPolicy.defaultPolicy() {
    return const CancellationPolicy(
      hoursBefore: 24,
      fullRefund: true,
      partialRefund: false,
      hasCancellationFee: false,
    );
  }

  @override
  List<Object?> get props => [
        hoursBefore,
        fullRefund,
        partialRefund,
        refundPercentage,
        hasCancellationFee,
        cancellationFee,
      ];

  Map<String, dynamic> toJson() {
    return {
      'hoursBefore': hoursBefore,
      'fullRefund': fullRefund,
      'partialRefund': partialRefund,
      'refundPercentage': refundPercentage,
      'hasCancellationFee': hasCancellationFee,
      'cancellationFee': cancellationFee,
    };
  }

  factory CancellationPolicy.fromJson(Map<String, dynamic> json) {
    return CancellationPolicy(
      hoursBefore: json['hoursBefore'] as int,
      fullRefund: json['fullRefund'] as bool? ?? true,
      partialRefund: json['partialRefund'] as bool? ?? false,
      refundPercentage: json['refundPercentage'] as double?,
      hasCancellationFee: json['hasCancellationFee'] as bool? ?? false,
      cancellationFee: json['cancellationFee'] as double?,
    );
  }
}

/// Dispute Status
enum DisputeStatus {
  /// No dispute
  none,

  /// Dispute submitted
  submitted,

  /// Dispute under review
  underReview,

  /// Dispute resolved
  resolved,
}

/// Dispute Reason
enum DisputeReason {
  /// Injury preventing attendance
  injury,

  /// Illness preventing attendance
  illness,

  /// Death in family
  death,

  /// Other extenuating circumstances
  other,
}

/// Reservation Model
///
/// **Philosophy Alignment:**
/// - "Doors, not badges" - Reservations are doors to experiences
/// - "The key opens doors" - Reservation system is a key that opens doors
/// - "Spots → Community → Life" - Reservations help users access their spots
///
/// **Quantum Integration:**
/// - Includes quantum state for matching and compatibility calculations
/// - Uses atomic timestamp for precise temporal tracking
/// - Supports quantum entanglement matching with events, businesses, spots
class Reservation extends Equatable {
  /// Unique reservation identifier
  final String id;

  /// Agent ID (privacy-protected internal tracking)
  /// CRITICAL: Uses agentId, not userId, for privacy protection
  final String agentId;

  /// Optional user data (shared with business/host if user consents)
  /// See: Dual Identity System (agentId + Optional User Data)
  final Map<String, dynamic>? userData;

  /// Reservation type (spot, business, event)
  final ReservationType type;

  /// Target ID (spot ID, business ID, or event ID)
  final String targetId;

  /// Reservation time
  final DateTime reservationTime;

  /// Party size (number of people)
  final int partySize;

  /// Ticket count (can be different from partySize if business has limit)
  final int ticketCount;

  /// Special requests
  final String? specialRequests;

  /// Current status
  final ReservationStatus status;

  /// Ticket price (if paid reservation)
  final double? ticketPrice;

  /// Deposit amount (if deposit required)
  final double? depositAmount;

  /// Seat ID (if seating chart used)
  final String? seatId;

  /// Calendar event ID (Phase 10.2: Calendar integration)
  /// Links reservation to device calendar event
  final String? calendarEventId;

  /// Cancellation policy
  final CancellationPolicy? cancellationPolicy;

  /// Modification count (max 3 modifications)
  final int modificationCount;

  /// Last modification time
  final DateTime? lastModifiedAt;

  /// Dispute status
  final DisputeStatus disputeStatus;

  /// Dispute reason (if disputed)
  final DisputeReason? disputeReason;

  /// Dispute description (if disputed)
  final String? disputeDescription;

  /// Atomic timestamp for ticket purchase (queue ordering)
  /// CRITICAL: Used for first-come-first-served queue ordering
  final AtomicTimestamp? atomicTimestamp;

  /// Quantum state for matching and compatibility calculations
  /// Phase 15 Quantum Enhancement: Full quantum entanglement integration
  final QuantumEntityState? quantumState;

  /// Reservation metadata (optional fields)
  final Map<String, dynamic> metadata;

  /// Created at
  final DateTime createdAt;

  /// Updated at
  final DateTime updatedAt;

  const Reservation({
    required this.id,
    required this.agentId,
    this.userData,
    required this.type,
    required this.targetId,
    required this.reservationTime,
    required this.partySize,
    this.ticketCount = 1,
    this.specialRequests,
    this.status = ReservationStatus.pending,
    this.ticketPrice,
    this.depositAmount,
    this.seatId,
    this.calendarEventId,
    this.cancellationPolicy,
    this.modificationCount = 0,
    this.lastModifiedAt,
    this.disputeStatus = DisputeStatus.none,
    this.disputeReason,
    this.disputeDescription,
    this.atomicTimestamp,
    this.quantumState,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if reservation can be modified
  bool canModify() {
    // Max 3 modifications
    if (modificationCount >= 3) return false;

    // Can't modify within 1 hour of reservation time
    final now = DateTime.now();
    final timeUntilReservation = reservationTime.difference(now);
    if (timeUntilReservation.inHours < 1) return false;

    // Can't modify if cancelled or completed
    if (status == ReservationStatus.cancelled ||
        status == ReservationStatus.completed) {
      return false;
    }

    return true;
  }

  /// Check if reservation can be cancelled
  bool canCancel() {
    // Can't cancel if already cancelled or completed
    if (status == ReservationStatus.cancelled ||
        status == ReservationStatus.completed) {
      return false;
    }

    return true;
  }

  /// Check if cancellation is within policy window
  bool isWithinCancellationWindow() {
    if (cancellationPolicy == null) return false;

    final now = DateTime.now();
    final timeUntilReservation = reservationTime.difference(now);
    return timeUntilReservation.inHours >= cancellationPolicy!.hoursBefore;
  }

  /// Create a copy with updated fields
  Reservation copyWith({
    String? id,
    String? agentId,
    Map<String, dynamic>? userData,
    ReservationType? type,
    String? targetId,
    DateTime? reservationTime,
    int? partySize,
    int? ticketCount,
    String? specialRequests,
    ReservationStatus? status,
    double? ticketPrice,
    double? depositAmount,
    String? seatId,
    String? calendarEventId,
    CancellationPolicy? cancellationPolicy,
    int? modificationCount,
    DateTime? lastModifiedAt,
    DisputeStatus? disputeStatus,
    DisputeReason? disputeReason,
    String? disputeDescription,
    AtomicTimestamp? atomicTimestamp,
    QuantumEntityState? quantumState,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reservation(
      id: id ?? this.id,
      agentId: agentId ?? this.agentId,
      userData: userData ?? this.userData,
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      reservationTime: reservationTime ?? this.reservationTime,
      partySize: partySize ?? this.partySize,
      ticketCount: ticketCount ?? this.ticketCount,
      specialRequests: specialRequests ?? this.specialRequests,
      status: status ?? this.status,
      ticketPrice: ticketPrice ?? this.ticketPrice,
      depositAmount: depositAmount ?? this.depositAmount,
      seatId: seatId ?? this.seatId,
      calendarEventId: calendarEventId ?? this.calendarEventId,
      cancellationPolicy: cancellationPolicy ?? this.cancellationPolicy,
      modificationCount: modificationCount ?? this.modificationCount,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      disputeStatus: disputeStatus ?? this.disputeStatus,
      disputeReason: disputeReason ?? this.disputeReason,
      disputeDescription: disputeDescription ?? this.disputeDescription,
      atomicTimestamp: atomicTimestamp ?? this.atomicTimestamp,
      quantumState: quantumState ?? this.quantumState,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agentId': agentId,
      'userData': userData,
      'type': type.name,
      'targetId': targetId,
      'reservationTime': reservationTime.toIso8601String(),
      'partySize': partySize,
      'ticketCount': ticketCount,
      'specialRequests': specialRequests,
      'status': status.name,
      'ticketPrice': ticketPrice,
      'depositAmount': depositAmount,
      'seatId': seatId,
      'calendarEventId': calendarEventId,
      'cancellationPolicy': cancellationPolicy?.toJson(),
      'modificationCount': modificationCount,
      'lastModifiedAt': lastModifiedAt?.toIso8601String(),
      'disputeStatus': disputeStatus.name,
      'disputeReason': disputeReason?.name,
      'disputeDescription': disputeDescription,
      'atomicTimestamp': atomicTimestamp?.toJson(),
      'quantumState': quantumState?.toJson(),
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'] as String,
      agentId: json['agentId'] as String,
      userData: json['userData'] != null
          ? Map<String, dynamic>.from(json['userData'] as Map)
          : null,
      type: ReservationType.values.firstWhere(
        (e) => e.name == json['type'] as String,
        orElse: () => ReservationType.spot,
      ),
      targetId: json['targetId'] as String,
      reservationTime: DateTime.parse(json['reservationTime'] as String),
      partySize: json['partySize'] as int,
      ticketCount: json['ticketCount'] as int? ?? 1,
      specialRequests: json['specialRequests'] as String?,
      status: ReservationStatus.values.firstWhere(
        (e) => e.name == json['status'] as String,
        orElse: () => ReservationStatus.pending,
      ),
      ticketPrice: json['ticketPrice'] as double?,
      depositAmount: json['depositAmount'] as double?,
      seatId: json['seatId'] as String?,
      calendarEventId: json['calendarEventId'] as String?,
      cancellationPolicy: json['cancellationPolicy'] != null
          ? CancellationPolicy.fromJson(
              json['cancellationPolicy'] as Map<String, dynamic>)
          : null,
      modificationCount: json['modificationCount'] as int? ?? 0,
      lastModifiedAt: json['lastModifiedAt'] != null
          ? DateTime.parse(json['lastModifiedAt'] as String)
          : null,
      disputeStatus: DisputeStatus.values.firstWhere(
        (e) => e.name == json['disputeStatus'] as String,
        orElse: () => DisputeStatus.none,
      ),
      disputeReason: json['disputeReason'] != null
          ? DisputeReason.values
              .firstWhere((e) => e.name == json['disputeReason'] as String)
          : null,
      disputeDescription: json['disputeDescription'] as String?,
      atomicTimestamp: json['atomicTimestamp'] != null
          ? AtomicTimestamp.fromJson(
              json['atomicTimestamp'] as Map<String, dynamic>)
          : null,
      quantumState: json['quantumState'] != null
          ? QuantumEntityState.fromJson(
              json['quantumState'] as Map<String, dynamic>)
          : null,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        agentId,
        userData,
        type,
        targetId,
        reservationTime,
        partySize,
        ticketCount,
        specialRequests,
        status,
        ticketPrice,
        depositAmount,
        seatId,
        calendarEventId,
        cancellationPolicy,
        modificationCount,
        lastModifiedAt,
        disputeStatus,
        disputeReason,
        disputeDescription,
        atomicTimestamp,
        quantumState,
        metadata,
        createdAt,
        updatedAt,
      ];
}

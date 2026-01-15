// Reservation Dispute Service
//
// Phase 15: Reservation System Implementation
// Section 15.1.6: Reservation Dispute Service
//
// Purpose: Handle disputes for extenuating circumstances

import 'dart:developer' as developer;
import 'dart:convert';

import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/services/reservation_service.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai/core/services/storage_service.dart';
import 'package:avrai/core/services/supabase_service.dart';
import 'package:avrai/core/services/payment_service.dart';
import 'package:avrai/core/services/refund_service.dart';
import 'package:uuid/uuid.dart';
import 'package:get_it/get_it.dart';

/// Dispute decision
enum DisputeDecision {
  /// Dispute approved
  approved,

  /// Dispute denied
  denied,
}

/// Reservation dispute model
class ReservationDispute {
  /// Unique dispute ID
  final String id;

  /// Reservation ID
  final String reservationId;

  /// Agent ID (privacy-protected internal tracking)
  /// CRITICAL: Uses agentId, not userId
  final String agentId;

  /// Dispute reason
  final DisputeReason reason;

  /// Dispute description
  final String description;

  /// Evidence URLs (if any)
  final List<String> evidenceUrls;

  /// Dispute status
  final DisputeStatus status;

  /// Dispute decision (if resolved)
  final DisputeDecision? decision;

  /// Admin notes (if reviewed)
  final String? adminNotes;

  /// Created at
  final DateTime createdAt;

  /// Updated at
  final DateTime updatedAt;

  /// Resolved at (if resolved)
  final DateTime? resolvedAt;

  const ReservationDispute({
    required this.id,
    required this.reservationId,
    required this.agentId,
    required this.reason,
    required this.description,
    this.evidenceUrls = const [],
    required this.status,
    this.decision,
    this.adminNotes,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
  });

  /// Create a copy with updated fields
  ReservationDispute copyWith({
    String? id,
    String? reservationId,
    String? agentId,
    DisputeReason? reason,
    String? description,
    List<String>? evidenceUrls,
    DisputeStatus? status,
    DisputeDecision? decision,
    String? adminNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
  }) {
    return ReservationDispute(
      id: id ?? this.id,
      reservationId: reservationId ?? this.reservationId,
      agentId: agentId ?? this.agentId,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      evidenceUrls: evidenceUrls ?? this.evidenceUrls,
      status: status ?? this.status,
      decision: decision ?? this.decision,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reservationId': reservationId,
      'agentId': agentId,
      'reason': reason.name,
      'description': description,
      'evidenceUrls': evidenceUrls,
      'status': status.name,
      'decision': decision?.name,
      'adminNotes': adminNotes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory ReservationDispute.fromJson(Map<String, dynamic> json) {
    return ReservationDispute(
      id: json['id'] as String,
      reservationId: json['reservationId'] as String,
      agentId: json['agentId'] as String,
      reason: DisputeReason.values.firstWhere(
        (e) => e.name == json['reason'] as String,
        orElse: () => DisputeReason.other,
      ),
      description: json['description'] as String,
      evidenceUrls: (json['evidenceUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      status: DisputeStatus.values.firstWhere(
        (e) => e.name == json['status'] as String,
        orElse: () => DisputeStatus.submitted,
      ),
      decision: json['decision'] != null
          ? DisputeDecision.values.firstWhere(
              (e) => e.name == json['decision'] as String,
            )
          : null,
      adminNotes: json['adminNotes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
    );
  }
}

/// Reservation Dispute Service
///
/// **Purpose:** Handle disputes for extenuating circumstances
///
/// **Dispute Reasons:**
/// - Injury preventing attendance
/// - Illness preventing attendance
/// - Death in family
/// - Other extenuating circumstances
class ReservationDisputeService {
  static const String _logName = 'ReservationDisputeService';
  static const String _storageKeyPrefix = 'dispute_';

  final ReservationService _reservationService;
  final AgentIdService _agentIdService;
  final StorageService _storageService;
  final SupabaseService _supabaseService;
  final PaymentService? _paymentService;
  final RefundService? _refundService;
  final Uuid _uuid = const Uuid();

  ReservationDisputeService({
    ReservationService? reservationService,
    AgentIdService? agentIdService,
    StorageService? storageService,
    SupabaseService? supabaseService,
    PaymentService? paymentService,
    RefundService? refundService,
  })  : _reservationService =
            reservationService ?? GetIt.instance<ReservationService>(),
        _agentIdService =
            agentIdService ?? GetIt.instance<AgentIdService>(),
        _storageService =
            storageService ?? GetIt.instance<StorageService>(),
        _supabaseService =
            supabaseService ?? GetIt.instance<SupabaseService>(),
        _paymentService = paymentService ??
            (GetIt.instance.isRegistered<PaymentService>()
                ? GetIt.instance<PaymentService>()
                : null),
        _refundService = refundService ??
            (GetIt.instance.isRegistered<RefundService>()
                ? GetIt.instance<RefundService>()
                : null);

  /// File dispute
  ///
  /// **CRITICAL:** Uses agentId (not userId) for privacy-protected tracking
  Future<ReservationDispute> fileDispute({
    required String userId, // Will be converted to agentId internally
    required String reservationId,
    required DisputeReason reason,
    required String description,
    List<String>? evidenceUrls,
  }) async {
    developer.log(
      'Filing dispute: reservationId=$reservationId, reason=$reason',
      name: _logName,
    );

    try {
      // Get reservation (via getUserReservations and filter)
      final allReservations = await _reservationService.getUserReservations();
      final reservation = allReservations.firstWhere(
        (r) => r.id == reservationId,
        orElse: () => throw Exception('Reservation not found: $reservationId'),
      );

      // Get agentId for privacy-protected internal tracking
      final agentId = await _agentIdService.getUserAgentId(userId);

      // Verify agentId matches (privacy protection)
      if (reservation.agentId != agentId) {
        throw Exception('Reservation does not belong to user');
      }

      // Create dispute
      final dispute = ReservationDispute(
        id: _uuid.v4(),
        reservationId: reservationId,
        agentId: agentId, // CRITICAL: Uses agentId, not userId
        reason: reason,
        description: description,
        evidenceUrls: evidenceUrls ?? [],
        status: DisputeStatus.submitted,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Store locally
      await _storeDispute(dispute);

      // Update reservation with dispute info
      // TODO(Phase 15.1.6): Add dispute fields to updateReservation method
      // For now, update is handled via dispute model
      // await _reservationService.updateReservation(
      //   reservationId: reservationId,
      //   // disputeStatus: DisputeStatus.submitted,
      //   // disputeReason: reason,
      //   // disputeDescription: description,
      // );

      // Sync to cloud when online
      if (_supabaseService.isAvailable) {
        try {
          await _syncDisputeToCloud(dispute);
        } catch (e) {
          developer.log(
            'Failed to sync dispute to cloud (will retry later): $e',
            name: _logName,
          );
        }
      }

      developer.log(
        '✅ Dispute filed: ${dispute.id}',
        name: _logName,
      );

      return dispute;
    } catch (e, stackTrace) {
      developer.log(
        'Error filing dispute: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Review dispute (admin/business)
  Future<ReservationDispute> reviewDispute({
    required String disputeId,
    required DisputeDecision decision,
    String? adminNotes,
  }) async {
    developer.log(
      'Reviewing dispute: disputeId=$disputeId, decision=$decision',
      name: _logName,
    );

    try {
      // Get dispute
      final dispute = await _getDisputeById(disputeId);
      if (dispute == null) {
        throw Exception('Dispute not found: $disputeId');
      }

      // Update dispute
      final updated = dispute.copyWith(
        status: DisputeStatus.resolved,
        decision: decision,
        adminNotes: adminNotes,
        resolvedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Store updated dispute
      await _storeDispute(updated);

      // Update reservation
      // TODO(Phase 15.1.6): Add dispute fields to updateReservation method
      // For now, update is handled via dispute model
      // await _reservationService.updateReservation(
      //   reservationId: dispute.reservationId,
      //   // disputeStatus: DisputeStatus.resolved,
      //   // disputeReason: dispute.reason,
      //   // disputeDescription: dispute.description,
      // );

      // If approved, process refund
      if (decision == DisputeDecision.approved) {
        await processApprovedDispute(disputeId);
      }

      // Sync to cloud
      if (_supabaseService.isAvailable) {
        try {
          await _syncDisputeToCloud(updated);
        } catch (e) {
          developer.log(
            'Failed to sync dispute review to cloud: $e',
            name: _logName,
          );
        }
      }

      developer.log(
        '✅ Dispute reviewed: ${updated.id}, decision=$decision',
        name: _logName,
      );

      return updated;
    } catch (e, stackTrace) {
      developer.log(
        'Error reviewing dispute: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Process approved dispute (issue refund)
  Future<void> processApprovedDispute(String disputeId) async {
    developer.log(
      'Processing approved dispute: disputeId=$disputeId',
      name: _logName,
    );

    try {
      // Get dispute
      final dispute = await _getDisputeById(disputeId);
      if (dispute == null) {
        throw Exception('Dispute not found: $disputeId');
      }

      if (dispute.decision != DisputeDecision.approved) {
        throw Exception('Dispute is not approved');
      }

      // Get reservation (via getUserReservations and filter)
      final allReservations = await _reservationService.getUserReservations();
      final reservation = allReservations.firstWhere(
        (r) => r.id == dispute.reservationId,
        orElse: () =>
            throw Exception('Reservation not found: ${dispute.reservationId}'),
      );

      // Process refund via RefundService (Phase 4: Payment polish)
      if (_refundService != null && reservation.ticketPrice != null) {
        try {
          // Get payment ID from reservation metadata
          final paymentId = reservation.metadata['paymentId'] as String?;
          if (paymentId != null) {
            // Get payment record to verify it exists
            final payment = _paymentService?.getPayment(paymentId);
            if (payment != null && payment.isSuccessful) {
              // Calculate full refund amount (approved disputes get full refund)
              // Include ticket total + deposit if applicable
              final ticketTotal = reservation.ticketPrice! * reservation.ticketCount;
              final depositAmount = reservation.depositAmount ?? 0.0;
              final refundAmount = ticketTotal + depositAmount;

              developer.log(
                'Processing dispute refund: dispute=$disputeId, reservation=${reservation.id}, payment=$paymentId, amount=\$${refundAmount.toStringAsFixed(2)}',
                name: _logName,
              );

              // Process refund via RefundService
              await _refundService!.processRefund(
                paymentId: paymentId,
                amount: refundAmount,
                cancellationId: disputeId,
              );

              developer.log(
                '✅ Dispute refund processed: dispute=$disputeId, amount=\$${refundAmount.toStringAsFixed(2)}',
                name: _logName,
              );
            } else {
              developer.log(
                '⚠️ Payment not found or not successful: payment=$paymentId, dispute=$disputeId',
                name: _logName,
              );
            }
          } else {
            developer.log(
              '⚠️ No payment ID in reservation metadata (free reservation): reservation=${reservation.id}, dispute=$disputeId',
              name: _logName,
            );
          }
        } catch (e, stackTrace) {
          developer.log(
            '⚠️ Error processing dispute refund (dispute processing continues): dispute=$disputeId, error: $e',
            name: _logName,
            error: e,
            stackTrace: stackTrace,
          );
          // Continue with dispute processing even if refund fails
        }
      } else if (reservation.ticketPrice == null || reservation.ticketPrice == 0) {
        developer.log(
          'No refund needed (free reservation): reservation=${reservation.id}, dispute=$disputeId',
          name: _logName,
        );
      } else {
        developer.log(
          '⚠️ Refund service not available: dispute=$disputeId',
          name: _logName,
        );
      }

      developer.log(
        '✅ Approved dispute processed: $disputeId',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error processing approved dispute: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get user's disputes
  ///
  /// **CRITICAL:** Uses agentId (not userId) for privacy-protected tracking
  Future<List<ReservationDispute>> getUserDisputes({
    required String userId, // Will be converted to agentId internally
  }) async {
    developer.log(
      'Getting user disputes: userId=$userId',
      name: _logName,
    );

    try {
      // Get agentId (for future filtering implementation)
      // ignore: unused_local_variable
      final agentId = await _agentIdService.getUserAgentId(userId);

      // Get all disputes for agentId
      // TODO(Phase 15.1.6): Implement efficient dispute retrieval
      // For now, return empty list (will be implemented with proper storage query)
      // Note: agentId will be used for filtering in future implementation
      return [];
    } catch (e, stackTrace) {
      developer.log(
        'Error getting user disputes: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  // Private helper methods

  /// Store dispute locally
  Future<void> _storeDispute(ReservationDispute dispute) async {
    try {
      final key = '$_storageKeyPrefix${dispute.id}';
      await _storageService.setString(
        key,
        jsonEncode(dispute.toJson()),
      );
    } catch (e) {
      developer.log(
        'Error storing dispute: $e',
        name: _logName,
        error: e,
      );
    }
  }

  /// Get dispute by ID
  Future<ReservationDispute?> _getDisputeById(String disputeId) async {
    try {
      final key = '$_storageKeyPrefix$disputeId';
      final jsonStr = _storageService.getString(key);
      if (jsonStr == null) return null;
      return ReservationDispute.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );
    } catch (e) {
      developer.log(
        'Error getting dispute: $e',
        name: _logName,
        error: e,
      );
      return null;
    }
  }

  /// Sync dispute to cloud
  Future<void> _syncDisputeToCloud(ReservationDispute dispute) async {
    // TODO(Phase 15.1.6): Implement cloud sync
    developer.log(
      '⏳ Cloud sync for dispute ${dispute.id} (TODO: implement)',
      name: _logName,
    );
  }
}

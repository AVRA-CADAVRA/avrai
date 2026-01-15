// Reservation Service
//
// Phase 15: Reservation System Implementation
// Section 15.1: Foundation - Core Service
// Enhanced with Quantum Entanglement Integration
//
// Core reservation management service with quantum integration.

import 'dart:developer' as developer;
import 'dart:convert';
import 'package:avrai/core/models/reservation.dart';
// AtomicTimestamp import removed - only used in model, not directly in service
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai/core/services/reservation_quantum_service.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai/core/services/storage_service.dart';
import 'package:avrai/core/services/supabase_service.dart';
import 'package:avrai/core/services/payment_service.dart';
import 'package:avrai/core/services/refund_service.dart';
import 'package:avrai/core/services/reservation_cancellation_policy_service.dart';
import 'package:avrai/core/services/reservation_analytics_service.dart';
import 'package:avrai/core/ai/event_logger.dart';
import 'package:uuid/uuid.dart';

/// Modification check result
class ModificationCheckResult {
  /// Whether the reservation can be modified
  final bool canModify;

  /// Reason if cannot modify
  final String? reason;

  /// Current modification count
  final int? modificationCount;

  /// Remaining modifications allowed
  final int? remainingModifications;

  const ModificationCheckResult({
    required this.canModify,
    this.reason,
    this.modificationCount,
    this.remainingModifications,
  });
}

/// Reservation Service
///
/// Core reservation management with quantum integration.
/// Uses agentId (not userId) for privacy-protected internal tracking.
class ReservationService {
  static const String _logName = 'ReservationService';
  static const String _storageKeyPrefix = 'reservation_';
  static const String _supabaseTable = 'reservations';

  final AtomicClockService _atomicClock;
  final ReservationQuantumService _quantumService;
  final AgentIdService _agentIdService;
  final StorageService _storageService;
  final SupabaseService _supabaseService;
  final PaymentService? _paymentService;
  final RefundService? _refundService;
  final ReservationCancellationPolicyService? _cancellationPolicyService;
  // Phase 7.1: Analytics Integration
  final ReservationAnalyticsService? _analyticsService;
  final EventLogger? _eventLogger;
  final Uuid _uuid = const Uuid();

  ReservationService({
    required AtomicClockService atomicClock,
    required ReservationQuantumService quantumService,
    required AgentIdService agentIdService,
    required StorageService storageService,
    required SupabaseService supabaseService,
    PaymentService? paymentService,
    RefundService? refundService,
    ReservationCancellationPolicyService? cancellationPolicyService,
    // Phase 7.1: Analytics Integration
    ReservationAnalyticsService? analyticsService,
    EventLogger? eventLogger,
  })  : _atomicClock = atomicClock,
        _quantumService = quantumService,
        _agentIdService = agentIdService,
        _storageService = storageService,
        _supabaseService = supabaseService,
        _paymentService = paymentService,
        _refundService = refundService,
        _cancellationPolicyService = cancellationPolicyService,
        _analyticsService = analyticsService,
        _eventLogger = eventLogger;

  /// Create reservation (free by default, business can require fee)
  ///
  /// **CRITICAL:** Uses agentId (not userId) for privacy-protected internal tracking.
  ///
  /// **Payment Integration (Phase 4.1):**
  /// - If ticketPrice > 0 and PaymentService is available, processes payment
  /// - Payment success → Reservation confirmed
  /// - Payment failure → Reservation creation fails (throws exception)
  /// - Free reservations (ticketPrice == null or 0) → Automatically confirmed
  ///
  /// **Quantum Integration:**
  /// - Creates quantum state for reservation
  /// - Uses atomic timestamp for queue ordering
  Future<Reservation> createReservation({
    required String userId, // Will be converted to agentId internally
    required ReservationType type,
    required String targetId,
    required DateTime reservationTime,
    required int partySize,
    int? ticketCount,
    String? specialRequests,
    double? ticketPrice,
    double? depositAmount,
    String? seatId,
    CancellationPolicy? cancellationPolicy,
    Map<String, dynamic>?
        userData, // Optional user data (shared with business/host if user consents)
  }) async {
    developer.log(
      'Creating reservation: type=$type, targetId=$targetId, time=$reservationTime',
      name: _logName,
    );

    try {
      // Get agentId for privacy-protected internal tracking
      final agentId = await _agentIdService.getUserAgentId(userId);

      // Get atomic timestamp for queue ordering
      final atomicTimestamp = await _atomicClock.getTicketPurchaseTimestamp();

      // Create quantum state for reservation
      final quantumState = await _quantumService.createReservationQuantumState(
        userId: userId,
        eventId: type == ReservationType.event ? targetId : null,
        businessId: type == ReservationType.business ? targetId : null,
        spotId: type == ReservationType.spot ? targetId : null,
        reservationTime: reservationTime,
      );

      // Create reservation
      Reservation reservation = Reservation(
        id: _uuid.v4(),
        agentId: agentId, // CRITICAL: Uses agentId, not userId
        userData: userData,
        type: type,
        targetId: targetId,
        reservationTime: reservationTime,
        partySize: partySize,
        ticketCount: ticketCount ?? partySize,
        specialRequests: specialRequests,
        status: ReservationStatus.pending,
        ticketPrice: ticketPrice,
        depositAmount: depositAmount,
        seatId: seatId,
        cancellationPolicy:
            cancellationPolicy ?? CancellationPolicy.defaultPolicy(),
        atomicTimestamp: atomicTimestamp,
        quantumState: quantumState,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Process payment if reservation requires payment (ticketPrice > 0)
      final price = ticketPrice; // Local variable for null-safety
      if (price != null && price > 0 && _paymentService != null) {
        try {
          developer.log(
            'Processing payment for reservation: ${reservation.id}, type=$type, price=$price',
            name: _logName,
          );

          final paymentResult =
              await _paymentService!.processReservationPayment(
            reservationId: reservation.id,
            reservationType: type,
            userId: userId,
            ticketPrice: price,
            ticketCount: ticketCount ?? partySize,
            depositAmount: depositAmount,
          );

          if (!paymentResult.isSuccess) {
            // Payment failed - throw error with payment error message
            throw Exception(
              paymentResult.errorMessage ?? 'Payment processing failed',
            );
          }

          // Payment successful - update reservation with payment info and confirm
          final payment = paymentResult.payment;
          if (payment != null) {
            // Store payment ID in metadata
            final updatedMetadata =
                Map<String, dynamic>.from(reservation.metadata);
            updatedMetadata['paymentId'] = payment.id;
            if (payment.stripePaymentIntentId != null) {
              updatedMetadata['stripePaymentIntentId'] =
                  payment.stripePaymentIntentId!;
            }

            reservation = reservation.copyWith(
              status: ReservationStatus.confirmed,
              metadata: updatedMetadata,
              updatedAt: DateTime.now(),
            );

            developer.log(
              '✅ Payment processed successfully: payment=${payment.id}, reservation=${reservation.id}',
              name: _logName,
            );
          } else {
            // Payment result success but no payment record (shouldn't happen, but handle gracefully)
            developer.log(
              '⚠️ Payment processing succeeded but no payment record returned',
              name: _logName,
            );
            // Keep reservation as pending if payment record missing
          }
        } catch (e, stackTrace) {
          developer.log(
            '❌ Payment processing failed for reservation: ${reservation.id}, error: $e',
            name: _logName,
            error: e,
            stackTrace: stackTrace,
          );
          // Re-throw to prevent reservation creation on payment failure
          rethrow;
        }
      } else if (price == null || price == 0) {
        // Free reservation - automatically confirm
        reservation = reservation.copyWith(
          status: ReservationStatus.confirmed,
          updatedAt: DateTime.now(),
        );
      }
      // If payment service not available and price > 0, keep as pending
      // (graceful degradation - reservation created but payment processing unavailable)

      // Store locally first (offline-first)
      await _storeReservationLocally(reservation);

      // Sync to cloud when online
      if (_supabaseService.isAvailable) {
        try {
          await _syncReservationToCloud(reservation);
        } catch (e) {
          developer.log(
            'Failed to sync reservation to cloud (will retry later): $e',
            name: _logName,
          );
          // Continue - offline-first, will sync later
        }
      }

      developer.log(
        '✅ Reservation created: ${reservation.id}, status=${reservation.status}',
        name: _logName,
      );

      // Phase 7.1: Track reservation creation event
      await _trackReservationEvent(
        userId: userId,
        eventType: 'reservation_created',
        reservation: reservation,
      );

      return reservation;
    } catch (e, stackTrace) {
      developer.log(
        'Error creating reservation: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get user's reservations
  ///
  /// **CRITICAL:** Uses agentId (not userId) for privacy-protected internal tracking.
  Future<List<Reservation>> getUserReservations({
    String? userId, // Will be converted to agentId internally
    ReservationStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    developer.log(
      'Getting user reservations: userId=$userId, status=$status',
      name: _logName,
    );

    try {
      // Get agentId if userId provided (for filtering)
      final agentId =
          userId != null ? await _agentIdService.getUserAgentId(userId) : null;

      // Get from local storage first
      final localReservations = await _getReservationsFromLocal(
        agentId: agentId,
        status: status,
        startDate: startDate,
        endDate: endDate,
      );

      // If online, also get from cloud and merge
      if (_supabaseService.isAvailable) {
        try {
          final cloudReservations = await _getReservationsFromCloud(
            agentId: agentId,
            status: status,
            startDate: startDate,
            endDate: endDate,
          );

          // Merge: prefer cloud if newer, otherwise local
          return _mergeReservations(localReservations, cloudReservations);
        } catch (e) {
          developer.log(
            'Failed to get reservations from cloud: $e',
            name: _logName,
          );
          // Return local reservations if cloud fails
        }
      }

      return localReservations;
    } catch (e, stackTrace) {
      developer.log(
        'Error getting user reservations: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Check if user already has reservation for this target/time
  ///
  /// **CRITICAL:** Uses agentId (not userId) for privacy-protected internal tracking.
  Future<bool> hasExistingReservation({
    required String userId, // Will be converted to agentId internally
    required ReservationType type,
    required String targetId,
    required DateTime reservationTime,
  }) async {
    try {
      // Get reservations for user (uses agentId internally)
      final reservations = await getUserReservations(userId: userId);

      // Check for existing reservation at same target and time (within 1 hour window)
      return reservations.any((r) =>
          r.type == type &&
          r.targetId == targetId &&
          r.reservationTime.difference(reservationTime).inHours.abs() < 1 &&
          r.status != ReservationStatus.cancelled);
    } catch (e) {
      developer.log(
        'Error checking existing reservation: $e',
        name: _logName,
      );
      return false; // Default to false on error
    }
  }

  /// Update reservation (with modification limits)
  Future<Reservation> updateReservation({
    required String reservationId,
    DateTime? reservationTime,
    int? partySize,
    int? ticketCount,
    String? specialRequests,
    String? calendarEventId,
  }) async {
    developer.log(
      'Updating reservation: $reservationId',
      name: _logName,
    );

    try {
      // Get existing reservation
      final existing = await _getReservationById(reservationId);
      if (existing == null) {
        throw Exception('Reservation not found: $reservationId');
      }

      // Check if can modify
      if (!existing.canModify()) {
        throw Exception(
            'Reservation cannot be modified (max 3 modifications or too close to reservation time)');
      }

      // Update reservation
      final updated = existing.copyWith(
        reservationTime: reservationTime ?? existing.reservationTime,
        partySize: partySize ?? existing.partySize,
        ticketCount: ticketCount ?? existing.ticketCount,
        specialRequests: specialRequests ?? existing.specialRequests,
        calendarEventId: calendarEventId ?? existing.calendarEventId,
        modificationCount: existing.modificationCount + 1,
        lastModifiedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Store locally
      await _storeReservationLocally(updated);

      // Sync to cloud
      if (_supabaseService.isAvailable) {
        try {
          await _syncReservationToCloud(updated);
        } catch (e) {
          developer.log(
            'Failed to sync updated reservation to cloud: $e',
            name: _logName,
          );
        }
      }

      developer.log(
        '✅ Reservation updated: $reservationId',
        name: _logName,
      );

      // Phase 7.1: Track reservation modification event
      // Get userId from reservation metadata or use agentId lookup
      await _trackReservationEvent(
        userId: existing.metadata['userId'] as String? ?? '',
        eventType: 'reservation_modified',
        reservation: updated,
        parameters: {
          'modification_count': updated.modificationCount,
          'modification_reason': 'user_requested',
        },
      );

      return updated;
    } catch (e, stackTrace) {
      developer.log(
        'Error updating reservation: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get reservations for a spot/business/event
  ///
  /// **CRITICAL:** Returns all reservations for a specific target (spot/business/event)
  Future<List<Reservation>> getReservationsForTarget({
    required ReservationType type,
    required String targetId,
    DateTime? date,
    ReservationStatus? status,
  }) async {
    developer.log(
      'Getting reservations for target: type=$type, targetId=$targetId, date=$date, status=$status',
      name: _logName,
    );

    try {
      // Get from local storage first
      final localReservations = await _getReservationsFromLocal();

      // Filter by target
      var filtered = localReservations
          .where((r) => r.type == type && r.targetId == targetId)
          .toList();

      // Filter by date if provided
      if (date != null) {
        filtered = filtered.where((r) {
          final reservationDate = DateTime(
            r.reservationTime.year,
            r.reservationTime.month,
            r.reservationTime.day,
          );
          final filterDate = DateTime(date.year, date.month, date.day);
          return reservationDate.isAtSameMomentAs(filterDate);
        }).toList();
      }

      // Filter by status if provided
      if (status != null) {
        filtered = filtered.where((r) => r.status == status).toList();
      }

      // If online, also get from cloud and merge
      if (_supabaseService.isAvailable) {
        try {
          final cloudReservations = await _getReservationsFromCloud();
          final cloudFiltered = cloudReservations.where((r) {
            if (r.type != type || r.targetId != targetId) return false;
            if (date != null) {
              final reservationDate = DateTime(
                r.reservationTime.year,
                r.reservationTime.month,
                r.reservationTime.day,
              );
              final filterDate = DateTime(date.year, date.month, date.day);
              if (!reservationDate.isAtSameMomentAs(filterDate)) return false;
            }
            if (status != null && r.status != status) return false;
            return true;
          }).toList();

          // Merge: prefer cloud if newer, otherwise local
          return _mergeReservations(filtered, cloudFiltered);
        } catch (e) {
          developer.log(
            'Failed to get reservations from cloud: $e',
            name: _logName,
          );
          // Return local reservations if cloud fails
        }
      }

      return filtered;
    } catch (e, stackTrace) {
      developer.log(
        'Error getting reservations for target: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Get user's reservations for a spot/event (all times)
  ///
  /// **CRITICAL:** Uses agentId (not userId) for privacy-protected internal tracking
  Future<List<Reservation>> getUserReservationsForTarget({
    required String userId, // Will be converted to agentId internally
    required ReservationType type,
    required String targetId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    developer.log(
      'Getting user reservations for target: userId=$userId, type=$type, targetId=$targetId',
      name: _logName,
    );

    try {
      // Get user's reservations (uses agentId internally)
      final userReservations = await getUserReservations(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      // Filter by target
      return userReservations
          .where((r) => r.type == type && r.targetId == targetId)
          .toList();
    } catch (e, stackTrace) {
      developer.log(
        'Error getting user reservations for target: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Check if reservation can be modified
  ///
  /// **Returns:** ModificationCheckResult with canModify flag and reason if not
  Future<ModificationCheckResult> canModifyReservation({
    required String reservationId,
    required DateTime newReservationTime,
  }) async {
    developer.log(
      'Checking if reservation can be modified: reservationId=$reservationId',
      name: _logName,
    );

    try {
      final reservation = await _getReservationById(reservationId);
      if (reservation == null) {
        return ModificationCheckResult(
          canModify: false,
          reason: 'Reservation not found',
        );
      }

      // Check using model's canModify method
      if (!reservation.canModify()) {
        String reason;
        if (reservation.modificationCount >= 3) {
          reason = 'Maximum modifications (3) reached';
        } else if (reservation.reservationTime
                .difference(DateTime.now())
                .inHours <
            1) {
          reason = 'Cannot modify within 1 hour of reservation time';
        } else {
          reason = 'Reservation cannot be modified';
        }
        return ModificationCheckResult(
          canModify: false,
          reason: reason,
        );
      }

      // Check if new time is valid (must be in future)
      if (newReservationTime.isBefore(DateTime.now())) {
        return ModificationCheckResult(
          canModify: false,
          reason: 'New reservation time must be in the future',
        );
      }

      return ModificationCheckResult(
        canModify: true,
        modificationCount: reservation.modificationCount,
        remainingModifications: 3 - reservation.modificationCount,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error checking if reservation can be modified: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return ModificationCheckResult(
        canModify: false,
        reason: 'Error checking modification: $e',
      );
    }
  }

  /// Get modification count
  Future<int> getModificationCount(String reservationId) async {
    try {
      final reservation = await _getReservationById(reservationId);
      if (reservation == null) {
        throw Exception('Reservation not found: $reservationId');
      }
      return reservation.modificationCount;
    } catch (e, stackTrace) {
      developer.log(
        'Error getting modification count: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Cancel reservation (applies cancellation policy)
  ///
  /// **Refund Integration (Phase 4.1):**
  /// - If applyPolicy is true and cancellation policy service is available:
  ///   - Checks if reservation qualifies for refund
  ///   - Calculates refund amount based on policy
  ///   - Processes refund via RefundService if eligible
  ///   - Updates reservation metadata with refund status
  /// - If payment service is available, retrieves payment for refund processing
  /// - Graceful degradation: If services unavailable, cancellation proceeds without refund
  Future<Reservation> cancelReservation({
    required String reservationId,
    required String reason,
    bool applyPolicy = true,
  }) async {
    developer.log(
      'Cancelling reservation: $reservationId, reason=$reason, applyPolicy=$applyPolicy',
      name: _logName,
    );

    try {
      // Get existing reservation
      final existing = await _getReservationById(reservationId);
      if (existing == null) {
        throw Exception('Reservation not found: $reservationId');
      }

      // Check if can cancel
      if (!existing.canCancel()) {
        throw Exception('Reservation cannot be cancelled');
      }

      final cancellationTime = DateTime.now();
      var updated = existing.copyWith(
        status: ReservationStatus.cancelled,
        updatedAt: cancellationTime,
      );

      // Process refund if policy applies and services are available
      if (applyPolicy &&
          _cancellationPolicyService != null &&
          _refundService != null &&
          _paymentService != null) {
        try {
          // Get payment ID from metadata
          final paymentId = existing.metadata['paymentId'] as String?;

          if (paymentId != null) {
            // Get payment record
            final payment = _paymentService!.getPayment(paymentId);

            if (payment != null) {
              // Check if qualifies for refund
              final qualifiesForRefund =
                  await _cancellationPolicyService!.qualifiesForRefund(
                reservation: existing,
                cancellationTime: cancellationTime,
              );

              if (qualifiesForRefund) {
                // Calculate refund amount
                final refundAmount =
                    await _cancellationPolicyService!.calculateRefund(
                  reservation: existing,
                  cancellationTime: cancellationTime,
                );

                if (refundAmount > 0) {
                  developer.log(
                    'Processing refund: reservation=$reservationId, payment=$paymentId, amount=\$${refundAmount.toStringAsFixed(2)}',
                    name: _logName,
                  );

                  // Process refund
                  final refundDistributions =
                      await _refundService!.processRefund(
                    paymentId: paymentId,
                    amount: refundAmount,
                    cancellationId: reservationId,
                  );

                  // Update metadata with refund info
                  final updatedMetadata = Map<String, dynamic>.from(
                    existing.metadata,
                  );
                  updatedMetadata['refundProcessed'] = true;
                  updatedMetadata['refundAmount'] = refundAmount;
                  updatedMetadata['refundProcessedAt'] =
                      cancellationTime.toIso8601String();
                  if (refundDistributions.isNotEmpty) {
                    updatedMetadata['refundDistributionId'] =
                        refundDistributions.first.stripeRefundId;
                  }

                  updated = updated.copyWith(metadata: updatedMetadata);

                  developer.log(
                    '✅ Refund processed: reservation=$reservationId, amount=\$${refundAmount.toStringAsFixed(2)}',
                    name: _logName,
                  );
                } else {
                  developer.log(
                    'No refund amount calculated: reservation=$reservationId',
                    name: _logName,
                  );
                }
              } else {
                developer.log(
                  'Reservation does not qualify for refund: reservation=$reservationId',
                  name: _logName,
                );
              }
            } else {
              developer.log(
                'Payment not found: payment=$paymentId, reservation=$reservationId',
                name: _logName,
              );
            }
          } else {
            developer.log(
              'No payment ID in metadata (free reservation): reservation=$reservationId',
              name: _logName,
            );
          }
        } catch (e, stackTrace) {
          developer.log(
            '⚠️ Refund processing failed (cancellation continues): reservation=$reservationId, error: $e',
            name: _logName,
            error: e,
            stackTrace: stackTrace,
          );
          // Continue with cancellation even if refund fails
          // (graceful degradation - cancellation proceeds without refund)
        }
      } else if (applyPolicy) {
        developer.log(
          'Refund services not available (cancellation continues without refund): reservation=$reservationId',
          name: _logName,
        );
      }

      // Store locally
      await _storeReservationLocally(updated);

      // Sync to cloud
      if (_supabaseService.isAvailable) {
        try {
          await _syncReservationToCloud(updated);
        } catch (e) {
          developer.log(
            'Failed to sync cancelled reservation to cloud: $e',
            name: _logName,
          );
        }
      }

      developer.log(
        '✅ Reservation cancelled: $reservationId',
        name: _logName,
      );

      // Phase 7.1: Track reservation cancellation event
      // Get userId from reservation metadata or use agentId lookup
      final userId = updated.metadata['userId'] as String?;
      if (userId != null) {
        await _trackReservationEvent(
          userId: userId,
          eventType: 'reservation_cancelled',
          reservation: updated,
          parameters: {
            'reason': reason,
            'refund_processed':
                updated.metadata['refundProcessed'] as bool? ?? false,
          },
        );
      }

      return updated;
    } catch (e, stackTrace) {
      developer.log(
        'Error cancelling reservation: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// File dispute for extenuating circumstances
  ///
  /// **Note:** This method updates the reservation with dispute info.
  /// For full dispute workflow, use ReservationDisputeService.
  Future<Reservation> fileDispute({
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
      final reservation = await _getReservationById(reservationId);
      if (reservation == null) {
        throw Exception('Reservation not found: $reservationId');
      }

      // Update reservation with dispute info
      final updated = reservation.copyWith(
        disputeStatus: DisputeStatus.submitted,
        disputeReason: reason,
        disputeDescription: description,
        updatedAt: DateTime.now(),
      );

      // Store locally
      await _storeReservationLocally(updated);

      // Sync to cloud
      if (_supabaseService.isAvailable) {
        try {
          await _syncReservationToCloud(updated);
        } catch (e) {
          developer.log(
            'Failed to sync disputed reservation to cloud: $e',
            name: _logName,
          );
        }
      }

      developer.log(
        '✅ Dispute filed: $reservationId',
        name: _logName,
      );

      return updated;
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

  /// Confirm reservation (for businesses)
  Future<Reservation> confirmReservation(String reservationId) async {
    developer.log(
      'Confirming reservation: $reservationId',
      name: _logName,
    );

    try {
      final reservation = await _getReservationById(reservationId);
      if (reservation == null) {
        throw Exception('Reservation not found: $reservationId');
      }

      if (reservation.status != ReservationStatus.pending) {
        throw Exception('Reservation is not pending');
      }

      final updated = reservation.copyWith(
        status: ReservationStatus.confirmed,
        updatedAt: DateTime.now(),
      );

      await _storeReservationLocally(updated);

      if (_supabaseService.isAvailable) {
        try {
          await _syncReservationToCloud(updated);
        } catch (e) {
          developer.log(
            'Failed to sync confirmed reservation to cloud: $e',
            name: _logName,
          );
        }
      }

      developer.log(
        '✅ Reservation confirmed: $reservationId',
        name: _logName,
      );

      return updated;
    } catch (e, stackTrace) {
      developer.log(
        'Error confirming reservation: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Mark as completed
  Future<Reservation> completeReservation(String reservationId) async {
    developer.log(
      'Completing reservation: $reservationId',
      name: _logName,
    );

    try {
      final reservation = await _getReservationById(reservationId);
      if (reservation == null) {
        throw Exception('Reservation not found: $reservationId');
      }

      if (reservation.status == ReservationStatus.completed) {
        throw Exception('Reservation is already completed');
      }

      final updated = reservation.copyWith(
        status: ReservationStatus.completed,
        updatedAt: DateTime.now(),
      );

      await _storeReservationLocally(updated);

      if (_supabaseService.isAvailable) {
        try {
          await _syncReservationToCloud(updated);
        } catch (e) {
          developer.log(
            'Failed to sync completed reservation to cloud: $e',
            name: _logName,
          );
        }
      }

      developer.log(
        '✅ Reservation completed: $reservationId',
        name: _logName,
      );

      // Phase 7.1: Track reservation completion event
      // Get userId from reservation metadata or use agentId lookup
      final userId = updated.metadata['userId'] as String?;
      if (userId != null) {
        await _trackReservationEvent(
          userId: userId,
          eventType: 'reservation_completed',
          reservation: updated,
        );
      }

      return updated;
    } catch (e, stackTrace) {
      developer.log(
        'Error completing reservation: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Mark as no-show (applies fee and possible expertise impact)
  Future<Reservation> markNoShow({
    required String reservationId,
    String? reason,
  }) async {
    developer.log(
      'Marking no-show: reservationId=$reservationId, reason=$reason',
      name: _logName,
    );

    try {
      final reservation = await _getReservationById(reservationId);
      if (reservation == null) {
        throw Exception('Reservation not found: $reservationId');
      }

      if (reservation.status == ReservationStatus.noShow) {
        throw Exception('Reservation is already marked as no-show');
      }

      // Apply no-show fee via PaymentService (Phase 4: Payment polish)
      double? noShowFeeAmount;
      String? noShowFeePaymentId;
      if (_paymentService != null) {
        try {
          // Calculate no-show fee (configurable per business, default: 20% of ticket price, or $10 minimum)
          // Phase 4: No-show fee configuration - get from reservation metadata or business settings
          double? configuredNoShowFeePercentage;
          double? configuredNoShowFeeMinimum;
          
          // Check reservation metadata for business-specific no-show fee configuration
          if (reservation.metadata.containsKey('noShowFeePercentage')) {
            configuredNoShowFeePercentage = (reservation.metadata['noShowFeePercentage'] as num?)?.toDouble();
          }
          if (reservation.metadata.containsKey('noShowFeeMinimum')) {
            configuredNoShowFeeMinimum = (reservation.metadata['noShowFeeMinimum'] as num?)?.toDouble();
          }
          
          // Use configured values or defaults
          final feePercentage = configuredNoShowFeePercentage ?? 0.20; // Default: 20%
          final feeMinimum = configuredNoShowFeeMinimum ?? 10.0; // Default: $10 minimum
          
          final baseFee = reservation.ticketPrice != null && reservation.ticketPrice! > 0
              ? reservation.ticketPrice! * feePercentage
              : feeMinimum;
          noShowFeeAmount = baseFee;

          // Get userId from reservation metadata or use agentId lookup
          // TODO(Phase 4): Get userId from agentId lookup when available
          final userId = reservation.metadata['userId'] as String? ?? reservation.agentId;

          // Create payment for no-show fee
          final noShowPaymentResult = await _paymentService!.processReservationPayment(
            reservationId: reservation.id,
            reservationType: reservation.type,
            userId: userId,
            ticketPrice: noShowFeeAmount,
            ticketCount: 1,
            depositAmount: null,
          );

          if (noShowPaymentResult.isSuccess && noShowPaymentResult.payment != null) {
            noShowFeePaymentId = noShowPaymentResult.payment!.id;
            developer.log(
              '✅ No-show fee charged: reservation=$reservationId, fee=\$${noShowFeeAmount.toStringAsFixed(2)}, payment=$noShowFeePaymentId',
              name: _logName,
            );
          } else {
            developer.log(
              '⚠️ No-show fee payment failed: reservation=$reservationId, error=${noShowPaymentResult.errorMessage}',
              name: _logName,
            );
            // Continue with no-show marking even if fee payment fails
          }
        } catch (e, stackTrace) {
          developer.log(
            '⚠️ Error charging no-show fee (continuing with no-show marking): reservation=$reservationId, error: $e',
            name: _logName,
            error: e,
            stackTrace: stackTrace,
          );
          // Continue with no-show marking even if fee payment fails
        }
      }

      // Phase 4: Apply expertise impact if applicable
      // Track no-show for expertise impact (negative event)
      try {
        // Log no-show for expertise tracking
        // Note: Actual expertise penalty calculation would be handled by expertise system
        // This tracks the negative event for future expertise calculations
        if (_eventLogger != null) {
          await _eventLogger!.logEvent(
            eventType: 'reservation_no_show',
            parameters: {
              'reservationId': reservation.id,
              'reservationType': reservation.type.name,
              'targetId': reservation.targetId,
              'reason': reason,
              'ticketPrice': reservation.ticketPrice,
              'noShowFeeAmount': noShowFeeAmount,
            },
            agentId: reservation.agentId, // Use agentId for privacy
          );
        }
        
        developer.log(
          '✅ No-show expertise impact tracked: reservation=$reservationId, agentId=${reservation.agentId}',
          name: _logName,
        );
      } catch (e) {
        developer.log(
          '⚠️ Error tracking no-show expertise impact (non-critical): $e',
          name: _logName,
          error: e,
        );
        // Continue - expertise impact tracking is non-critical
      }

      final updatedMetadata = Map<String, dynamic>.from(reservation.metadata);
      updatedMetadata['noShowReason'] = reason;
      updatedMetadata['noShowAt'] = DateTime.now().toIso8601String();
      if (noShowFeeAmount != null) {
        updatedMetadata['noShowFeeAmount'] = noShowFeeAmount;
      }
      if (noShowFeePaymentId != null) {
        updatedMetadata['noShowFeePaymentId'] = noShowFeePaymentId;
      }

      final updated = reservation.copyWith(
        status: ReservationStatus.noShow,
        updatedAt: DateTime.now(),
        metadata: updatedMetadata,
      );

      await _storeReservationLocally(updated);

      if (_supabaseService.isAvailable) {
        try {
          await _syncReservationToCloud(updated);
        } catch (e) {
          developer.log(
            'Failed to sync no-show reservation to cloud: $e',
            name: _logName,
          );
        }
      }

      developer.log(
        '✅ Reservation marked as no-show: $reservationId',
        name: _logName,
      );

      return updated;
    } catch (e, stackTrace) {
      developer.log(
        'Error marking no-show: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Check-in to reservation
  ///
  /// **Note:** This is a placeholder for future check-in functionality
  Future<Reservation> checkIn(String reservationId) async {
    developer.log(
      'Checking in: reservationId=$reservationId',
      name: _logName,
    );

    try {
      final reservation = await _getReservationById(reservationId);
      if (reservation == null) {
        throw Exception('Reservation not found: $reservationId');
      }

      // Update metadata with check-in time
      final updated = reservation.copyWith(
        updatedAt: DateTime.now(),
        metadata: {
          ...reservation.metadata,
          'checkedInAt': DateTime.now().toIso8601String(),
        },
      );

      await _storeReservationLocally(updated);

      if (_supabaseService.isAvailable) {
        try {
          await _syncReservationToCloud(updated);
        } catch (e) {
          developer.log(
            'Failed to sync check-in to cloud: $e',
            name: _logName,
          );
        }
      }

      developer.log(
        '✅ Checked in: $reservationId',
        name: _logName,
      );

      return updated;
    } catch (e, stackTrace) {
      developer.log(
        'Error checking in: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Check availability (delegates to ReservationAvailabilityService)
  ///
  /// **Note:** This is a convenience method. For full availability checking,
  /// use ReservationAvailabilityService directly.
  Future<bool> checkAvailability({
    required ReservationType type,
    required String targetId,
    required DateTime reservationTime,
    required int partySize,
  }) async {
    // TODO(Phase 15.1.2): Integrate with ReservationAvailabilityService
    // For now, return true (always available)
    return true;
  }

  // --- Private Helper Methods ---

  /// Store reservation locally (offline-first)
  Future<void> _storeReservationLocally(Reservation reservation) async {
    final key = '$_storageKeyPrefix${reservation.id}';
    final jsonStr = jsonEncode(reservation.toJson());
    await _storageService.setString(key, jsonStr);
  }

  /// Get reservation by ID (public method for check-in service)
  ///
  /// **Phase 10.1:** Added public method for ReservationCheckInService
  Future<Reservation?> getReservationById(String reservationId) async {
    return await _getReservationById(reservationId);
  }

  /// Get reservation by ID (private implementation)
  Future<Reservation?> _getReservationById(String reservationId) async {
    final key = '$_storageKeyPrefix$reservationId';
    final jsonStr = _storageService.getString(key);
    if (jsonStr == null) return null;

    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return Reservation.fromJson(json);
    } catch (e) {
      developer.log(
        'Error parsing reservation JSON: $e',
        name: _logName,
      );
      return null;
    }
  }

  /// Get reservations from local storage
  Future<List<Reservation>> _getReservationsFromLocal({
    String? agentId,
    ReservationStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final allKeys = _storageService.getKeys();
      final reservationKeys =
          allKeys.where((key) => key.startsWith(_storageKeyPrefix)).toList();

      final reservations = <Reservation>[];

      for (final key in reservationKeys) {
        try {
          final jsonStr = _storageService.getString(key);
          if (jsonStr == null) continue;

          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          final reservation = Reservation.fromJson(json);

          // Filter by agentId if provided
          if (agentId != null && reservation.agentId != agentId) continue;

          // Filter by status if provided
          if (status != null && reservation.status != status) continue;

          // Filter by date range if provided
          if (startDate != null &&
              reservation.reservationTime.isBefore(startDate)) {
            continue;
          }
          if (endDate != null && reservation.reservationTime.isAfter(endDate)) {
            continue;
          }

          reservations.add(reservation);
        } catch (e) {
          developer.log(
            'Error parsing reservation from local storage: $e',
            name: _logName,
          );
          // Continue with next reservation
        }
      }

      return reservations;
    } catch (e) {
      developer.log(
        'Error getting reservations from local storage: $e',
        name: _logName,
      );
      return [];
    }
  }

  /// Get reservations from cloud
  Future<List<Reservation>> _getReservationsFromCloud({
    String? agentId,
    ReservationStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!_supabaseService.isAvailable) {
      return [];
    }

    try {
      final client = _supabaseService.client;
      var query = client.from(_supabaseTable).select();

      if (agentId != null) {
        query = query.eq('agent_id', agentId);
      }

      if (status != null) {
        query = query.eq('status', status.name);
      }

      if (startDate != null) {
        query = query.gte('reservation_time', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('reservation_time', endDate.toIso8601String());
      }

      final response = await query;

      if (response.isEmpty) return [];

      final reservations = <Reservation>[];
      for (final row in response) {
        try {
          final reservation =
              Reservation.fromJson(Map<String, dynamic>.from(row));
          reservations.add(reservation);
        } catch (e) {
          developer.log(
            'Error parsing reservation from cloud: $e',
            name: _logName,
          );
          // Continue with next reservation
        }
      }

      return reservations;
    } catch (e) {
      developer.log(
        'Error getting reservations from cloud: $e',
        name: _logName,
      );
      return [];
    }
  }

  /// Track reservation event for analytics
  ///
  /// Phase 7.1: Analytics Integration
  ///
  /// **Event Types:**
  /// - `reservation_created`
  /// - `reservation_modified`
  /// - `reservation_cancelled`
  /// - `reservation_completed`
  /// - `reservation_waitlist_joined`
  /// - `reservation_waitlist_converted`
  Future<void> _trackReservationEvent({
    required String userId,
    required String eventType,
    required Reservation reservation,
    Map<String, dynamic>? parameters,
  }) async {
    // Track via analytics service if available
    if (_analyticsService != null) {
      try {
        await _analyticsService!.trackReservationEvent(
          userId: userId,
          eventType: eventType,
          parameters: {
            'reservation_id': reservation.id,
            'reservation_type': reservation.type.name,
            'target_id': reservation.targetId,
            'status': reservation.status.name,
            'party_size': reservation.partySize,
            if (reservation.ticketPrice != null)
              'ticket_price': reservation.ticketPrice,
            if (parameters != null) ...parameters,
          },
        );
      } catch (e) {
        developer.log(
          'Error tracking reservation event via analytics service: $e',
          name: _logName,
        );
        // Don't throw - analytics tracking should not break the flow
      }
    }

    // Also track via EventLogger if available
    if (_eventLogger != null) {
      try {
        await _eventLogger!.logEvent(
          eventType: eventType,
          parameters: {
            'reservation_id': reservation.id,
            'reservation_type': reservation.type.name,
            'target_id': reservation.targetId,
            'status': reservation.status.name,
            'party_size': reservation.partySize,
            if (reservation.ticketPrice != null)
              'ticket_price': reservation.ticketPrice,
            if (parameters != null) ...parameters,
          },
        );
      } catch (e) {
        developer.log(
          'Error tracking reservation event via EventLogger: $e',
          name: _logName,
        );
        // Don't throw - analytics tracking should not break the flow
      }
    }
  }

  /// Sync reservation to cloud
  Future<void> _syncReservationToCloud(Reservation reservation) async {
    if (!_supabaseService.isAvailable) {
      return;
    }

    try {
      final client = _supabaseService.client;
      await client.from(_supabaseTable).upsert({
        'id': reservation.id,
        'agent_id': reservation.agentId,
        'user_data': reservation.userData,
        'type': reservation.type.name,
        'target_id': reservation.targetId,
        'reservation_time': reservation.reservationTime.toIso8601String(),
        'party_size': reservation.partySize,
        'ticket_count': reservation.ticketCount,
        'special_requests': reservation.specialRequests,
        'status': reservation.status.name,
        'ticket_price': reservation.ticketPrice,
        'deposit_amount': reservation.depositAmount,
        'seat_id': reservation.seatId,
        'cancellation_policy': reservation.cancellationPolicy?.toJson(),
        'modification_count': reservation.modificationCount,
        'last_modified_at': reservation.lastModifiedAt?.toIso8601String(),
        'dispute_status': reservation.disputeStatus.name,
        'dispute_reason': reservation.disputeReason?.name,
        'dispute_description': reservation.disputeDescription,
        'atomic_timestamp': reservation.atomicTimestamp?.toJson(),
        'quantum_state': reservation.quantumState?.toJson(),
        'calendar_event_id': reservation.calendarEventId,
        'metadata': reservation.metadata,
        'created_at': reservation.createdAt.toIso8601String(),
        'updated_at': reservation.updatedAt.toIso8601String(),
      });
    } catch (e) {
      developer.log(
        'Error syncing reservation to cloud: $e',
        name: _logName,
      );
      rethrow;
    }
  }

  /// Merge local and cloud reservations (prefer newer)
  List<Reservation> _mergeReservations(
    List<Reservation> local,
    List<Reservation> cloud,
  ) {
    // Create a map of reservations by ID
    final reservationMap = <String, Reservation>{};

    // Add local reservations first
    for (final reservation in local) {
      reservationMap[reservation.id] = reservation;
    }

    // Merge cloud reservations (prefer newer updatedAt)
    for (final cloudReservation in cloud) {
      final existing = reservationMap[cloudReservation.id];
      if (existing == null) {
        // New reservation from cloud
        reservationMap[cloudReservation.id] = cloudReservation;
      } else {
        // Prefer newer updatedAt
        if (cloudReservation.updatedAt.isAfter(existing.updatedAt)) {
          reservationMap[cloudReservation.id] = cloudReservation;
        }
      }
    }

    // Return merged list sorted by reservation time
    final merged = reservationMap.values.toList();
    merged.sort((a, b) => a.reservationTime.compareTo(b.reservationTime));
    return merged;
  }
}

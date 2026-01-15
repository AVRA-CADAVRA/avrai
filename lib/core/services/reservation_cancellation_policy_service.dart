// Reservation Cancellation Policy Service
//
// Phase 15: Reservation System Implementation
// Section 15.1.5: Cancellation Policy Service
//
// Purpose: Manage cancellation policies (business-specific + baseline)

import 'dart:developer' as developer;

import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/services/reservation_service.dart';
import 'package:avrai/core/services/storage_service.dart';
import 'package:avrai/core/services/supabase_service.dart';
import 'package:get_it/get_it.dart';

/// Reservation Cancellation Policy Service
///
/// **Responsibilities:**
/// - Get cancellation policy for business/event/spot
/// - Set business-specific cancellation policies
/// - Provide baseline policy (24 hours default)
/// - Check if cancellation qualifies for refund
/// - Calculate refund amount
class ReservationCancellationPolicyService {
  static const String _logName = 'ReservationCancellationPolicyService';
  static const String _storageKeyPrefix = 'cancellation_policy_';

  // ignore: unused_field - Reserved for future reservation history checking
  final ReservationService _reservationService;
  final StorageService _storageService;
  final SupabaseService _supabaseService;

  ReservationCancellationPolicyService({
    ReservationService? reservationService,
    StorageService? storageService,
    SupabaseService? supabaseService,
  })  : _reservationService =
            reservationService ?? GetIt.instance<ReservationService>(),
        _storageService =
            storageService ?? GetIt.instance<StorageService>(),
        _supabaseService =
            supabaseService ?? GetIt.instance<SupabaseService>();

  /// Get cancellation policy for business/event/spot
  ///
  /// **Priority:**
  /// 1. Business-specific policy (if set)
  /// 2. Baseline policy (24 hours default)
  Future<CancellationPolicy> getCancellationPolicy({
    required ReservationType type,
    required String targetId,
  }) async {
    developer.log(
      'Getting cancellation policy: type=$type, targetId=$targetId',
      name: _logName,
    );

    try {
      // Try to get business-specific policy
      if (type == ReservationType.business || type == ReservationType.spot) {
        final businessPolicy = await _getBusinessPolicy(targetId);
        if (businessPolicy != null) {
          return businessPolicy;
        }
      }

      // Fall back to baseline policy
      return getBaselinePolicy();
    } catch (e, stackTrace) {
      developer.log(
        'Error getting cancellation policy: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Default to baseline policy on error
      return getBaselinePolicy();
    }
  }

  /// Set business cancellation policy
  Future<CancellationPolicy> setBusinessPolicy({
    required String businessId,
    int? hoursBeforeForRefund,
    bool allowsRefund = true,
    double? refundPercentage,
    bool allowsDisputes = true,
  }) async {
    developer.log(
      'Setting business cancellation policy: businessId=$businessId, hoursBefore=$hoursBeforeForRefund',
      name: _logName,
    );

    try {
      final policy = CancellationPolicy(
        hoursBefore: hoursBeforeForRefund ?? 24,
        fullRefund: allowsRefund && refundPercentage == null,
        partialRefund: allowsRefund && refundPercentage != null,
        refundPercentage: refundPercentage,
        hasCancellationFee: false,
        cancellationFee: null,
      );

      // Store policy locally
      await _storeBusinessPolicy(businessId, policy);

      // Sync to cloud when online
      if (_supabaseService.isAvailable) {
        try {
          await _syncBusinessPolicyToCloud(businessId, policy);
        } catch (e) {
          developer.log(
            'Failed to sync policy to cloud (will retry later): $e',
            name: _logName,
          );
        }
      }

      return policy;
    } catch (e, stackTrace) {
      developer.log(
        'Error setting business policy: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get baseline policy (24 hours default)
  ///
  /// **Baseline Policy:**
  /// - 24 hours before reservation for full refund
  /// - Less than 24 hours = no refund (unless dispute)
  /// - Disputes allowed for extenuating circumstances
  CancellationPolicy getBaselinePolicy() {
    return CancellationPolicy.defaultPolicy();
  }

  /// Check if cancellation qualifies for refund
  ///
  /// **Rules:**
  /// - Must cancel within policy hours (e.g., 24 hours before)
  /// - Disputes always qualify (regardless of timing)
  Future<bool> qualifiesForRefund({
    required Reservation reservation,
    required DateTime cancellationTime,
  }) async {
    developer.log(
      'Checking refund qualification: reservationId=${reservation.id}, cancellationTime=$cancellationTime',
      name: _logName,
    );

    try {
      // If dispute is approved, always qualifies
      if (reservation.disputeStatus == DisputeStatus.resolved &&
          reservation.disputeReason != null) {
        return true;
      }

      // Get policy for reservation
      final policy = await getCancellationPolicy(
        type: reservation.type,
        targetId: reservation.targetId,
      );

      // Check if cancellation is within policy hours
      final hoursUntilReservation =
          reservation.reservationTime.difference(cancellationTime).inHours;

      if (hoursUntilReservation >= policy.hoursBefore) {
        return policy.fullRefund || policy.partialRefund;
      }

      // Too late for refund (unless dispute)
      return false;
    } catch (e, stackTrace) {
      developer.log(
        'Error checking refund qualification: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Default to false on error (conservative)
      return false;
    }
  }

  /// Calculate refund amount
  ///
  /// **Calculation:**
  /// - Full refund: Returns full ticket price
  /// - Partial refund: Returns percentage of ticket price
  /// - No refund: Returns 0.0
  Future<double> calculateRefund({
    required Reservation reservation,
    required DateTime cancellationTime,
  }) async {
    developer.log(
      'Calculating refund: reservationId=${reservation.id}, cancellationTime=$cancellationTime',
      name: _logName,
    );

    try {
      // Check if qualifies for refund
      final qualifies = await qualifiesForRefund(
        reservation: reservation,
        cancellationTime: cancellationTime,
      );

      if (!qualifies) {
        return 0.0;
      }

      // Get policy
      final policy = await getCancellationPolicy(
        type: reservation.type,
        targetId: reservation.targetId,
      );

      // If no ticket price, no refund
      if (reservation.ticketPrice == null || reservation.ticketPrice! <= 0) {
        return 0.0;
      }

      final ticketPrice = reservation.ticketPrice!;
      final ticketCount = reservation.ticketCount;
      final totalPrice = ticketPrice * ticketCount;

      // Calculate refund based on policy
      if (policy.fullRefund) {
        return totalPrice;
      } else if (policy.partialRefund && policy.refundPercentage != null) {
        return totalPrice * policy.refundPercentage!;
      }

      return 0.0;
    } catch (e, stackTrace) {
      developer.log(
        'Error calculating refund: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Default to 0.0 on error (conservative)
      return 0.0;
    }
  }

  // Private helper methods

  /// Get business-specific policy
  Future<CancellationPolicy?> _getBusinessPolicy(String businessId) async {
    try {
      final key = '$_storageKeyPrefix$businessId';
      final jsonStr = _storageService.getString(key);
      if (jsonStr == null) return null;

      // TODO(Phase 15.1.5): Parse JSON and return policy
      // For now, return null (will be implemented with proper storage)
      return null;
    } catch (e) {
      developer.log(
        'Error getting business policy: $e',
        name: _logName,
        error: e,
      );
      return null;
    }
  }

  /// Store business policy locally
  Future<void> _storeBusinessPolicy(
    String businessId,
    CancellationPolicy policy,
  ) async {
    try {
      // TODO(Phase 15.1.5): Store policy as JSON
      // final key = '$_storageKeyPrefix$businessId';
      // await _storageService.setString(key, jsonEncode(policy.toJson()));
    } catch (e) {
      developer.log(
        'Error storing business policy: $e',
        name: _logName,
        error: e,
      );
    }
  }

  /// Sync business policy to cloud
  Future<void> _syncBusinessPolicyToCloud(
    String businessId,
    CancellationPolicy policy,
  ) async {
    // TODO(Phase 15.1.5): Implement cloud sync
    developer.log(
      '⏳ Cloud sync for business policy $businessId (TODO: implement)',
      name: _logName,
    );
  }
}

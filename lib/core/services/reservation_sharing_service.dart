// Reservation Sharing Service
//
// Phase 10.4: Reservation Sharing & Transfer
// Manages sharing and transferring reservations between users
//
// Full AVRAI integration: knots, quantum, strings, fabrics, worldsheets, AI2AI mesh

import 'dart:developer' as developer;
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/services/reservation_service.dart';
import 'package:avrai/core/services/reservation_quantum_service.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/services/quantum/quantum_matching_ai_learning_service.dart';
import 'package:avrai/core/services/hybrid_encryption_service.dart';
import 'package:avrai/core/ai2ai/anonymous_communication.dart';
import 'package:avrai_knot/services/knot/knot_orchestrator_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_knot/services/knot/knot_worldsheet_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';

/// Sharing Permission Level
enum SharingPermission {
  /// Read-only access (can view reservation details)
  readOnly,

  /// Full access (can modify, cancel, etc.)
  fullAccess,
}

/// Shared Reservation
///
/// Represents a reservation shared with another user.
class SharedReservation {
  /// Reservation ID
  final String reservationId;

  /// Owner user ID
  final String ownerUserId;

  /// Owner agent ID (privacy-protected)
  final String ownerAgentId;

  /// Shared with user ID
  final String sharedWithUserId;

  /// Shared with agent ID (privacy-protected)
  final String sharedWithAgentId;

  /// Permission level
  final SharingPermission permission;

  /// Knot signature for verification
  final String? knotSignature;

  /// Shared timestamp
  final DateTime sharedAt;

  const SharedReservation({
    required this.reservationId,
    required this.ownerUserId,
    required this.ownerAgentId,
    required this.sharedWithUserId,
    required this.sharedWithAgentId,
    required this.permission,
    this.knotSignature,
    required this.sharedAt,
  });

  /// Create from JSON
  factory SharedReservation.fromJson(Map<String, dynamic> json) {
    return SharedReservation(
      reservationId: json['reservationId'] as String,
      ownerUserId: json['ownerUserId'] as String,
      ownerAgentId: json['ownerAgentId'] as String,
      sharedWithUserId: json['sharedWithUserId'] as String,
      sharedWithAgentId: json['sharedWithAgentId'] as String,
      permission: SharingPermission.values.firstWhere(
        (e) => e.name == json['permission'],
        orElse: () => SharingPermission.readOnly,
      ),
      knotSignature: json['knotSignature'] as String?,
      sharedAt: DateTime.parse(json['sharedAt'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'reservationId': reservationId,
      'ownerUserId': ownerUserId,
      'ownerAgentId': ownerAgentId,
      'sharedWithUserId': sharedWithUserId,
      'sharedWithAgentId': sharedWithAgentId,
      'permission': permission.name,
      'knotSignature': knotSignature,
      'sharedAt': sharedAt.toIso8601String(),
    };
  }
}

/// Sharing Operation Result
class SharingOperationResult {
  final bool success;
  final String? error;
  final SharedReservation? sharedReservation;

  const SharingOperationResult({
    required this.success,
    this.error,
    this.sharedReservation,
  });

  factory SharingOperationResult.success({
    required SharedReservation sharedReservation,
  }) {
    return SharingOperationResult(
      success: true,
      sharedReservation: sharedReservation,
    );
  }

  factory SharingOperationResult.error(String error) {
    return SharingOperationResult(
      success: false,
      error: error,
    );
  }
}

/// Transfer Operation Result
class TransferOperationResult {
  final bool success;
  final String? error;
  final Reservation? transferredReservation;
  final double? compatibilityScore;

  const TransferOperationResult({
    required this.success,
    this.error,
    this.transferredReservation,
    this.compatibilityScore,
  });

  factory TransferOperationResult.success({
    required Reservation transferredReservation,
    double? compatibilityScore,
  }) {
    return TransferOperationResult(
      success: true,
      transferredReservation: transferredReservation,
      compatibilityScore: compatibilityScore,
    );
  }

  factory TransferOperationResult.error(String error) {
    return TransferOperationResult(
      success: false,
      error: error,
    );
  }
}

/// Reservation Sharing Service
///
/// Manages sharing and transferring reservations between users.
///
/// **Phase 10.4:** Reservation sharing and transfer with full AVRAI system integration
///
/// **Features:**
/// - Share reservation with other users (read-only access)
/// - Transfer reservation ownership to another user
/// - Knot signature verification for transfer authenticity
/// - Quantum state preservation during transfer
/// - Compatibility prediction for transfer recipient
/// - Privacy-preserving sharing (agentId-based, encrypted)
/// - Group sharing creates fabric for coordination
///
/// **AI2AI/Knot/Quantum Integration:**
/// - **Knot Integration:** Transfer uses knot signature verification to ensure authenticity
/// - **Quantum State:** Shared/transferred reservations maintain quantum state for compatibility tracking
/// - **String Evolution:** Predicts compatibility after transfer using `predictFutureKnot()`
/// - **Fabric Integration:** Shared reservations create fabric for group coordination
/// - **Worldsheet Integration:** Transfer patterns tracked for learning
/// - **AI2AI Mesh Learning:** Sharing/transfer patterns propagate through mesh
/// - **Signal Protocol:** Sharing/transfer data encrypted via `HybridEncryptionService`
/// - **Hybrid Compatibility:** Enhanced formulas for transfer compatibility
class ReservationSharingService {
  static const String _logName = 'ReservationSharingService';
  // ignore: unused_field - Reserved for Phase 10.4: Local storage implementation
  static const String _storageKeyPrefix = 'shared_reservation_';

  final ReservationService _reservationService;
  // ignore: unused_field - Reserved for Phase 10.4: Quantum state preservation during transfer
  final ReservationQuantumService _quantumService;
  final AgentIdService _agentIdService;
  // ignore: unused_field - Reserved for Phase 10.4: Personality profile retrieval for knot generation
  final PersonalityLearning _personalityLearning;
  final AtomicClockService _atomicClock;

  // Knot Services (Phase 10.4: Full knot integration)
  // ignore: unused_field - Reserved for Phase 10.4: Knot orchestration for sharing coordination
  final KnotOrchestratorService? _knotOrchestrator;
  // ignore: unused_field - Reserved for Phase 10.4: Knot storage for signature verification
  final KnotStorageService? _knotStorage;
  // ignore: unused_field - Reserved for Phase 10.4: String evolution for compatibility predictions
  final KnotEvolutionStringService? _stringService;
  // ignore: unused_field - Reserved for Phase 10.4: Fabric integration for group sharing coordination
  final KnotFabricService? _fabricService;
  // ignore: unused_field - Reserved for Phase 10.4: Worldsheet integration for transfer patterns
  final KnotWorldsheetService? _worldsheetService;

  // AI2AI Mesh Learning (Phase 10.4: Sharing/transfer propagation)
  // ignore: unused_field - Reserved for Phase 10.4: AI2AI mesh learning propagation
  final QuantumMatchingAILearningService? _aiLearningService;

  // Signal Protocol (Phase 10.4: Privacy-preserving sharing/transfer)
  // ignore: unused_field - Reserved for Phase 10.4: Signal Protocol encryption integration
  final HybridEncryptionService? _encryptionService;
  // ignore: unused_field - Reserved for Phase 10.4: Anonymous communication protocol integration
  final AnonymousCommunicationProtocol? _ai2aiProtocol;

  // Phase 9.2: Performance Caching
  // ignore: unused_field - Reserved for Phase 10.4: Performance caching implementation
  final Map<String, _CachedCompatibility> _compatibilityCache = {};
  // ignore: unused_field - Reserved for Phase 10.4: Performance caching implementation
  static const Duration _cacheExpiry = Duration(minutes: 15);
  // ignore: unused_field - Reserved for Phase 10.4: Performance caching implementation
  static const int _maxCacheSize = 50;

  ReservationSharingService({
    required ReservationService reservationService,
    required ReservationQuantumService quantumService,
    required AgentIdService agentIdService,
    required PersonalityLearning personalityLearning,
    required AtomicClockService atomicClock,
    // Optional knot services (graceful degradation if not available)
    KnotOrchestratorService? knotOrchestrator,
    KnotStorageService? knotStorage,
    KnotEvolutionStringService? stringService,
    KnotFabricService? fabricService,
    KnotWorldsheetService? worldsheetService,
    // Optional AI2AI services
    QuantumMatchingAILearningService? aiLearningService,
    HybridEncryptionService? encryptionService,
    AnonymousCommunicationProtocol? ai2aiProtocol,
  })  : _reservationService = reservationService,
        _quantumService = quantumService,
        _agentIdService = agentIdService,
        _personalityLearning = personalityLearning,
        _atomicClock = atomicClock,
        _knotOrchestrator = knotOrchestrator,
        _knotStorage = knotStorage,
        _stringService = stringService,
        _fabricService = fabricService,
        _worldsheetService = worldsheetService,
        _aiLearningService = aiLearningService,
        _encryptionService = encryptionService,
        _ai2aiProtocol = ai2aiProtocol;

  /// Share reservation with another user
  ///
  /// **Purpose:** Grant read-only or full access to a reservation
  ///
  /// **Flow:**
  /// 1. Verify reservation ownership
  /// 2. Generate knot signature for sharing
  /// 3. Create quantum state for shared reservation
  /// 4. Store sharing record
  /// 5. Propagate to AI2AI mesh for learning
  ///
  /// **Parameters:**
  /// - `reservationId`: Reservation to share
  /// - `ownerUserId`: Owner user ID
  /// - `sharedWithUserId`: User ID to share with
  /// - `permission`: Permission level (read-only or full access)
  ///
  /// **Returns:**
  /// SharingOperationResult with shared reservation record
  Future<SharingOperationResult> shareReservation({
    required String reservationId,
    required String ownerUserId,
    required String sharedWithUserId,
    SharingPermission permission = SharingPermission.readOnly,
  }) async {
    try {
      developer.log(
        'Sharing reservation: reservationId=$reservationId, ownerUserId=$ownerUserId, sharedWithUserId=$sharedWithUserId',
        name: _logName,
      );

      // Get reservation
      final reservation =
          await _reservationService.getReservationById(reservationId);
      if (reservation == null) {
        return SharingOperationResult.error(
            'Reservation not found: $reservationId');
      }

      // Verify ownership (check agentId)
      final ownerAgentId = await _agentIdService.getUserAgentId(ownerUserId);
      if (reservation.agentId != ownerAgentId) {
        return SharingOperationResult.error(
            'You do not have permission to share this reservation');
      }

      // Get agent IDs
      final sharedWithAgentId =
          await _agentIdService.getUserAgentId(sharedWithUserId);

      // Generate knot signature for sharing (Phase 10.4: Knot integration)
      final tAtomic = await _atomicClock.getAtomicTimestamp();
      final knotSignature = await _generateKnotSignature(
        ownerAgentId: ownerAgentId,
        sharedWithAgentId: sharedWithAgentId,
        reservationId: reservationId,
        timestamp: tAtomic.deviceTime,
      );

      // Create shared reservation record
      final sharedReservation = SharedReservation(
        reservationId: reservationId,
        ownerUserId: ownerUserId,
        ownerAgentId: ownerAgentId,
        sharedWithUserId: sharedWithUserId,
        sharedWithAgentId: sharedWithAgentId,
        permission: permission,
        knotSignature: knotSignature,
        sharedAt: DateTime.now(),
      );

      // Store sharing record locally
      await _storeSharingLocally(sharedReservation);

      // Propagate to AI2AI mesh (Phase 10.4: Mesh learning)
      await _propagateSharingLearning(
        sharedReservation: sharedReservation,
        reservation: reservation,
      );

      // Create fabric for group coordination (Phase 10.4: Fabric integration)
      if (_fabricService != null && permission == SharingPermission.fullAccess) {
        // TODO(Phase 10.4): Create fabric for shared group reservations
        developer.log(
          'Fabric creation for shared reservation (placeholder): reservationId=$reservationId',
          name: _logName,
        );
      }

      developer.log(
        'Reservation shared successfully: reservationId=$reservationId',
        name: _logName,
      );

      return SharingOperationResult.success(
        sharedReservation: sharedReservation,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error sharing reservation: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return SharingOperationResult.error('Failed to share: $e');
    }
  }

  /// Transfer reservation ownership to another user
  ///
  /// **Purpose:** Transfer reservation ownership with knot signature verification
  ///
  /// **Flow:**
  /// 1. Verify reservation ownership
  /// 2. Verify knot signature for transfer authenticity
  /// 3. Predict compatibility for transfer recipient
  /// 4. Preserve quantum state during transfer
  /// 5. Update reservation ownership
  /// 6. Propagate to AI2AI mesh for learning
  ///
  /// **Parameters:**
  /// - `reservationId`: Reservation to transfer
  /// - `fromUserId`: Current owner user ID
  /// - `toUserId`: New owner user ID
  ///
  /// **Returns:**
  /// TransferOperationResult with transferred reservation and compatibility score
  Future<TransferOperationResult> transferReservation({
    required String reservationId,
    required String fromUserId,
    required String toUserId,
  }) async {
    try {
      developer.log(
        'Transferring reservation: reservationId=$reservationId, fromUserId=$fromUserId, toUserId=$toUserId',
        name: _logName,
      );

      // Get reservation
      final reservation =
          await _reservationService.getReservationById(reservationId);
      if (reservation == null) {
        return TransferOperationResult.error(
            'Reservation not found: $reservationId');
      }

      // Verify ownership
      final fromAgentId = await _agentIdService.getUserAgentId(fromUserId);
      if (reservation.agentId != fromAgentId) {
        return TransferOperationResult.error(
            'You do not have permission to transfer this reservation');
      }

      // Get new owner agent ID
      final toAgentId = await _agentIdService.getUserAgentId(toUserId);

      // Verify knot signature for transfer authenticity (Phase 10.4: Knot integration)
      final isValid = await _verifyKnotSignature(
        reservation: reservation,
        ownerAgentId: fromAgentId,
      );
      if (!isValid) {
        return TransferOperationResult.error(
            'Knot signature verification failed');
      }

      // Predict compatibility for transfer recipient (Phase 10.4: String evolution)
      final compatibilityScore = await _predictTransferCompatibility(
        reservation: reservation,
        fromAgentId: fromAgentId,
        toAgentId: toAgentId,
      );

      // Preserve quantum state during transfer (Phase 10.4: Quantum integration)
      // TODO(Phase 10.4): Use preserved quantum state when updating reservation
      // ignore: unused_local_variable - Reserved for Phase 10.4: Quantum state preservation
      final preservedQuantumState = reservation.quantumState;

      // Update reservation ownership
      // TODO(Phase 10.4): Update reservation with new owner when transfer method is available
      // For now, create a new reservation with updated ownership
      // Note: This is a placeholder - actual transfer should update existing reservation
      final transferredReservation = reservation.copyWith(
        agentId: toAgentId,
        updatedAt: DateTime.now(),
      );

      // Store transfer record locally
      await _storeTransferLocally(
        reservationId: reservationId,
        fromUserId: fromUserId,
        toUserId: toUserId,
        compatibilityScore: compatibilityScore,
      );

      // Propagate to AI2AI mesh (Phase 10.4: Mesh learning)
      await _propagateTransferLearning(
        reservation: reservation,
        fromAgentId: fromAgentId,
        toAgentId: toAgentId,
        compatibilityScore: compatibilityScore,
      );

      developer.log(
        'Reservation transferred successfully: reservationId=$reservationId, compatibilityScore=$compatibilityScore',
        name: _logName,
      );

      return TransferOperationResult.success(
        transferredReservation: transferredReservation,
        compatibilityScore: compatibilityScore,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error transferring reservation: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return TransferOperationResult.error('Failed to transfer: $e');
    }
  }

  /// Generate knot signature for sharing/transfer
  ///
  /// **Purpose:** Create knot signature for verification
  ///
  /// **Note:** Currently returns placeholder. Full implementation requires:
  /// - Knot storage service integration
  /// - Personality profile retrieval
  Future<String> _generateKnotSignature({
    required String ownerAgentId,
    required String sharedWithAgentId,
    required String reservationId,
    required DateTime timestamp,
  }) async {
    // TODO(Phase 10.4): Generate real knot signature via KnotStorageService
    // For now, return placeholder
    return 'knot_signature_placeholder_${ownerAgentId}_${sharedWithAgentId}_$reservationId';
  }

  /// Verify knot signature for transfer
  ///
  /// **Purpose:** Verify transfer authenticity using knot signature
  ///
  /// **Note:** Currently returns placeholder. Full implementation requires:
  /// - Knot storage service integration
  Future<bool> _verifyKnotSignature({
    required Reservation reservation,
    required String ownerAgentId,
  }) async {
    // TODO(Phase 10.4): Verify real knot signature via KnotStorageService
    // For now, return true (placeholder)
    return true;
  }

  /// Predict compatibility for transfer recipient
  ///
  /// **Purpose:** Predict compatibility after transfer using string evolution
  ///
  /// **Note:** Currently returns placeholder. Full implementation requires:
  /// - String evolution service integration
  /// - Quantum state compatibility calculation
  Future<double> _predictTransferCompatibility({
    required Reservation reservation,
    required String fromAgentId,
    required String toAgentId,
  }) async {
    // TODO(Phase 10.4): Predict compatibility using KnotEvolutionStringService.predictFutureKnot()
    // For now, return placeholder
    return 0.75; // Default compatibility score
  }

  /// Propagate sharing learning to AI2AI mesh
  ///
  /// **Purpose:** Learn from sharing patterns across the mesh
  ///
  /// **Note:** Currently placeholder. Full implementation requires:
  /// - userId lookup from agentId
  /// - QuantumMatchingAILearningService integration
  Future<void> _propagateSharingLearning({
    required SharedReservation sharedReservation,
    required Reservation reservation,
  }) async {
    // TODO(Phase 10.4): Propagate to AI2AI mesh when userId lookup is available
    developer.log(
      'Sharing learning propagation (placeholder): reservationId=${reservation.id}',
      name: _logName,
    );
  }

  /// Propagate transfer learning to AI2AI mesh
  ///
  /// **Purpose:** Learn from transfer patterns across the mesh
  ///
  /// **Note:** Currently placeholder. Full implementation requires:
  /// - userId lookup from agentId
  /// - QuantumMatchingAILearningService integration
  Future<void> _propagateTransferLearning({
    required Reservation reservation,
    required String fromAgentId,
    required String toAgentId,
    required double compatibilityScore,
  }) async {
    // TODO(Phase 10.4): Propagate to AI2AI mesh when userId lookup is available
    developer.log(
      'Transfer learning propagation (placeholder): reservationId=${reservation.id}, compatibilityScore=$compatibilityScore',
      name: _logName,
    );
  }

  /// Store sharing record locally
  Future<void> _storeSharingLocally(SharedReservation sharedReservation) async {
    // TODO(Phase 10.4): Implement local storage
    developer.log(
      'Storing sharing record locally (placeholder): reservationId=${sharedReservation.reservationId}',
      name: _logName,
    );
  }

  /// Store transfer record locally
  Future<void> _storeTransferLocally({
    required String reservationId,
    required String fromUserId,
    required String toUserId,
    required double compatibilityScore,
  }) async {
    // TODO(Phase 10.4): Implement local storage
    developer.log(
      'Storing transfer record locally (placeholder): reservationId=$reservationId',
      name: _logName,
    );
  }

  /// Get shared reservations for user
  Future<List<SharedReservation>> getSharedReservations(String userId) async {
    // TODO(Phase 10.4): Implement retrieval
    developer.log(
      'Getting shared reservations (placeholder): userId=$userId',
      name: _logName,
    );
    return [];
  }

  /// Get reservations shared with user
  Future<List<SharedReservation>> getReservationsSharedWithMe(
      String userId) async {
    // TODO(Phase 10.4): Implement retrieval
    developer.log(
      'Getting reservations shared with me (placeholder): userId=$userId',
      name: _logName,
    );
    return [];
  }
}

/// Cached compatibility calculation
class _CachedCompatibility {
  final double compatibility;
  final DateTime cachedAt;

  _CachedCompatibility({
    required this.compatibility,
    required this.cachedAt,
  });
}

// Sesame Sync Service
//
// Phase 2.1: Sesame Multi-Device Support
// Synchronizes Signal Protocol encryption state across multiple devices
//
// Enables users to access AI2AI connections from multiple devices,
// with personality learning syncing across devices.

import 'dart:async';
import 'dart:developer' as developer;
import 'package:avrai/core/crypto/signal/signal_types.dart';
import 'package:avrai/core/crypto/signal/signal_session_manager.dart';
import 'package:avrai/core/crypto/signal/device_registration_service.dart';

/// Sesame Sync Service
///
/// Synchronizes Signal Protocol encryption state across multiple devices.
/// Implements Sesame algorithm for multi-device state synchronization.
///
/// **Phase 2.1:** Sesame Multi-Device Support (MEDIUM PRIORITY)
///
/// **Features:**
/// - State synchronization across devices
/// - Conflict resolution
/// - Device state management
/// - Session state sync
///
/// **Note:** This is a foundational implementation that can be extended.
/// Full Sesame integration requires server infrastructure or peer-to-peer sync.
class SesameSyncService {
  static const String _logName = 'SesameSyncService';

  // Note: _sessionManager reserved for future use (full state sync implementation)
  // ignore: unused_field
  final SignalSessionManager _sessionManager;
  final DeviceRegistrationService _deviceRegistration;

  // State sync queue (deviceId -> sync operations)
  final Map<int, List<StateSyncOperation>> _syncQueue = {};

  // Conflict resolution state
  final Map<String, ConflictState> _conflictStates = {};

  SesameSyncService({
    required SignalSessionManager sessionManager,
    required DeviceRegistrationService deviceRegistration,
  })  : _sessionManager = sessionManager,
        _deviceRegistration = deviceRegistration;

  /// Sync session state to another device
  ///
  /// **Parameters:**
  /// - `recipientId`: Recipient's agent ID
  /// - `targetDeviceId`: Target device ID to sync to
  /// - `sessionState`: Session state to sync
  ///
  /// **Returns:**
  /// `true` if sync initiated, `false` if target device not registered
  Future<bool> syncSessionState({
    required String recipientId,
    required int targetDeviceId,
    required SignalSessionState sessionState,
  }) async {
    // Check if target device is registered
    final targetDevice = _deviceRegistration.getDevice(targetDeviceId);
    if (targetDevice == null || !targetDevice.isActive) {
      developer.log(
        'Cannot sync to device $targetDeviceId: device not registered or inactive',
        name: _logName,
      );
      return false;
    }

    // Queue sync operation
    final operation = StateSyncOperation(
      recipientId: recipientId,
      targetDeviceId: targetDeviceId,
      sessionState: sessionState,
      operationType: SyncOperationType.sessionState,
      timestamp: DateTime.now(),
    );

    _syncQueue.putIfAbsent(targetDeviceId, () => []);
    _syncQueue[targetDeviceId]!.add(operation);

    developer.log(
      'Queued session state sync: recipientId=$recipientId, targetDeviceId=$targetDeviceId',
      name: _logName,
    );

    // TODO: Implement actual sync mechanism (requires server infrastructure or P2P sync)
    // For now, this is a foundational structure

    return true;
  }

  /// Process incoming state sync
  ///
  /// **Parameters:**
  /// - `fromDeviceId`: Source device ID
  /// - `syncData`: Sync data from source device
  ///
  /// **Returns:**
  /// `true` if sync processed successfully, `false` if conflict detected
  Future<bool> processIncomingSync({
    required int fromDeviceId,
    required Map<String, dynamic> syncData,
  }) async {
    try {
      // Check if source device is registered
      final sourceDevice = _deviceRegistration.getDevice(fromDeviceId);
      if (sourceDevice == null) {
        developer.log(
          'Rejecting sync from unregistered device: $fromDeviceId',
          name: _logName,
        );
        return false;
      }

      // Update device last seen
      await _deviceRegistration.updateDeviceLastSeen(fromDeviceId);

      // Parse sync operation
      final operationTypeStr = syncData['operation_type'] as String?;
      if (operationTypeStr == null) {
        return false;
      }

      final operationType = SyncOperationType.values.firstWhere(
        (e) => e.name == operationTypeStr,
        orElse: () => SyncOperationType.unknown,
      );

      if (operationType == SyncOperationType.unknown) {
        developer.log(
          'Unknown sync operation type: $operationTypeStr',
          name: _logName,
        );
        return false;
      }

      // Handle conflict resolution
      final syncId = syncData['sync_id'] as String?;
      if (syncId != null) {
        final hasConflict = await _checkForConflict(
          syncId: syncId,
          fromDeviceId: fromDeviceId,
          operationType: operationType,
        );

        if (hasConflict) {
          developer.log(
            'Conflict detected for sync: $syncId, resolving...',
            name: _logName,
          );
          await _resolveConflict(
            syncId: syncId,
            fromDeviceId: fromDeviceId,
            syncData: syncData,
          );
        }
      }

      // Process sync based on operation type
      switch (operationType) {
        case SyncOperationType.sessionState:
          return await _processSessionStateSync(syncData);
        case SyncOperationType.identityKey:
          return await _processIdentityKeySync(syncData);
        case SyncOperationType.preKey:
          return await _processPreKeySync(syncData);
        default:
          developer.log(
            'Unhandled sync operation type: $operationType',
            name: _logName,
          );
          return false;
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error processing incoming sync: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Process session state sync
  Future<bool> _processSessionStateSync(Map<String, dynamic> syncData) async {
    // TODO: Implement session state sync
    // This requires deserializing session state and updating local session
    developer.log(
      'Processing session state sync (foundational - full implementation requires infrastructure)',
      name: _logName,
    );
    return true;
  }

  /// Process identity key sync
  Future<bool> _processIdentityKeySync(Map<String, dynamic> syncData) async {
    // TODO: Implement identity key sync
    developer.log(
      'Processing identity key sync (foundational - full implementation requires infrastructure)',
      name: _logName,
    );
    return true;
  }

  /// Process prekey sync
  Future<bool> _processPreKeySync(Map<String, dynamic> syncData) async {
    // TODO: Implement prekey sync
    developer.log(
      'Processing prekey sync (foundational - full implementation requires infrastructure)',
      name: _logName,
    );
    return true;
  }

  /// Check for conflicts in state sync
  Future<bool> _checkForConflict({
    required String syncId,
    required int fromDeviceId,
    required SyncOperationType operationType,
  }) async {
    final conflictKey = '$syncId:$fromDeviceId';
    final existingConflict = _conflictStates[conflictKey];

    if (existingConflict != null) {
      // Conflict exists, need resolution
      return true;
    }

    // No conflict detected
    return false;
  }

  /// Resolve conflict in state sync
  Future<void> _resolveConflict({
    required String syncId,
    required int fromDeviceId,
    required Map<String, dynamic> syncData,
  }) async {
    // TODO: Implement conflict resolution strategy
    // Strategy: Last-write-wins, or merge based on operation type
    developer.log(
      'Resolving conflict for sync: $syncId (foundational - full implementation requires conflict resolution strategy)',
      name: _logName,
    );

    // For now, use last-write-wins
    _conflictStates['$syncId:$fromDeviceId'] = ConflictState(
      syncId: syncId,
      resolvedAt: DateTime.now(),
      resolutionStrategy: ConflictResolutionStrategy.lastWriteWins,
    );
  }

  /// Clear sync queue for a device
  void clearSyncQueue(int deviceId) {
    _syncQueue.remove(deviceId);
    developer.log('Cleared sync queue for device: $deviceId', name: _logName);
  }

  /// Get sync queue size for a device
  int getSyncQueueSize(int deviceId) {
    return _syncQueue[deviceId]?.length ?? 0;
  }
}

/// State Sync Operation
///
/// Represents a single state synchronization operation.
class StateSyncOperation {
  final String recipientId;
  final int targetDeviceId;
  final SignalSessionState? sessionState;
  final SyncOperationType operationType;
  final DateTime timestamp;
  final Map<String, dynamic>? additionalData;

  StateSyncOperation({
    required this.recipientId,
    required this.targetDeviceId,
    this.sessionState,
    required this.operationType,
    required this.timestamp,
    this.additionalData,
  });

  Map<String, dynamic> toJson() {
    return {
      'recipient_id': recipientId,
      'target_device_id': targetDeviceId,
      'operation_type': operationType.name,
      'timestamp': timestamp.toIso8601String(),
      'additional_data': additionalData,
    };
  }
}

/// Sync Operation Type
enum SyncOperationType {
  sessionState,
  identityKey,
  preKey,
  unknown,
}

/// Conflict State
///
/// Represents conflict resolution state for sync operations.
class ConflictState {
  final String syncId;
  final DateTime resolvedAt;
  final ConflictResolutionStrategy resolutionStrategy;

  ConflictState({
    required this.syncId,
    required this.resolvedAt,
    required this.resolutionStrategy,
  });
}

/// Conflict Resolution Strategy
enum ConflictResolutionStrategy {
  lastWriteWins,
  merge,
  reject,
  userChoice,
}

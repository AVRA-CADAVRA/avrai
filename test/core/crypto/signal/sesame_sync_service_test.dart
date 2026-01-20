// Unit tests for Sesame Sync Service
//
// Tests state synchronization, conflict resolution, and sync operations

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/crypto/signal/sesame_sync_service.dart';
import 'package:avrai/core/crypto/signal/device_registration_service.dart';
import 'package:avrai/core/crypto/signal/signal_session_manager.dart';
import 'package:avrai/core/crypto/signal/signal_types.dart';
import 'package:avrai/core/crypto/signal/signal_key_manager.dart';
import 'package:avrai/core/crypto/signal/signal_ffi_bindings.dart';
import 'package:sembast/sembast_memory.dart';
import '../../../mocks/in_memory_flutter_secure_storage.dart';

void main() {
  group('SesameSyncService', () {
    late SesameSyncService service;
    late DeviceRegistrationService deviceRegistration;
    late SignalSessionManager sessionManager;
    late SignalKeyManager keyManager;

    setUp(() async {
      // Create test dependencies
      // Use in-memory storage to avoid platform-specific issues
      final secureStorage = InMemoryFlutterSecureStorage();
      final database = await databaseFactoryMemory.openDatabase('test.db');
      final ffiBindings = SignalFFIBindings();

      keyManager = SignalKeyManager(
        secureStorage: secureStorage,
        ffiBindings: ffiBindings,
      );

      sessionManager = SignalSessionManager(
        database: database,
        ffiBindings: ffiBindings,
        keyManager: keyManager,
      );

      deviceRegistration = DeviceRegistrationService(keyManager: keyManager);

      service = SesameSyncService(
        sessionManager: sessionManager,
        deviceRegistration: deviceRegistration,
      );
    });

    test('should sync session state to registered device', () async {
      // Register target device
      await deviceRegistration.registerDevice(deviceId: 2, deviceName: 'Target Device');

      final sessionState = SignalSessionState(
        recipientId: 'test_recipient',
        createdAt: DateTime.now(),
      );

      final result = await service.syncSessionState(
        recipientId: 'test_recipient',
        targetDeviceId: 2,
        sessionState: sessionState,
      );

      expect(result, isTrue);
      expect(service.getSyncQueueSize(2), 1);
    });

    test('should fail to sync to unregistered device', () async {
      final sessionState = SignalSessionState(
        recipientId: 'test_recipient',
        createdAt: DateTime.now(),
      );

      final result = await service.syncSessionState(
        recipientId: 'test_recipient',
        targetDeviceId: 999, // Non-existent device
        sessionState: sessionState,
      );

      expect(result, isFalse);
      expect(service.getSyncQueueSize(999), 0);
    });

    test('should fail to sync to inactive device', () async {
      await deviceRegistration.registerDevice(deviceId: 2, deviceName: 'Device 2');
      await deviceRegistration.deactivateDevice(2);

      final sessionState = SignalSessionState(
        recipientId: 'test_recipient',
        createdAt: DateTime.now(),
      );

      final result = await service.syncSessionState(
        recipientId: 'test_recipient',
        targetDeviceId: 2,
        sessionState: sessionState,
      );

      expect(result, isFalse);
    });

    test('should queue multiple sync operations', () async {
      await deviceRegistration.registerDevice(deviceId: 2, deviceName: 'Target Device');

      final sessionState1 = SignalSessionState(
        recipientId: 'recipient1',
        createdAt: DateTime.now(),
      );
      final sessionState2 = SignalSessionState(
        recipientId: 'recipient2',
        createdAt: DateTime.now(),
      );

      await service.syncSessionState(
        recipientId: 'recipient1',
        targetDeviceId: 2,
        sessionState: sessionState1,
      );
      await service.syncSessionState(
        recipientId: 'recipient2',
        targetDeviceId: 2,
        sessionState: sessionState2,
      );

      expect(service.getSyncQueueSize(2), 2);
    });

    test('should process incoming sync from registered device', () async {
      await deviceRegistration.registerDevice(deviceId: 1, deviceName: 'Source Device');

      final syncData = {
        'operation_type': 'sessionState',
        'sync_id': 'test_sync_123',
        'recipient_id': 'test_recipient',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final result = await service.processIncomingSync(
        fromDeviceId: 1,
        syncData: syncData,
      );

      // Should process successfully (foundational implementation)
      expect(result, isTrue);
    });

    test('should reject incoming sync from unregistered device', () async {
      final syncData = {
        'operation_type': 'sessionState',
        'sync_id': 'test_sync_123',
      };

      final result = await service.processIncomingSync(
        fromDeviceId: 999, // Non-existent device
        syncData: syncData,
      );

      expect(result, isFalse);
    });

    test('should update device last seen on incoming sync', () async {
      final device = await deviceRegistration.registerDevice(
        deviceId: 1,
        deviceName: 'Source Device',
      );
      final originalLastSeen = device.lastSeenAt;

      await Future.delayed(const Duration(milliseconds: 10));

      final syncData = {
        'operation_type': 'sessionState',
        'sync_id': 'test_sync_123',
      };

      await service.processIncomingSync(fromDeviceId: 1, syncData: syncData);

      final updatedDevice = deviceRegistration.getDevice(1);
      expect(updatedDevice, isNotNull);
      expect(updatedDevice!.lastSeenAt.isAfter(originalLastSeen), isTrue);
    });

    test('should clear sync queue for device', () async {
      await deviceRegistration.registerDevice(deviceId: 2, deviceName: 'Target Device');

      final sessionState = SignalSessionState(
        recipientId: 'test_recipient',
        createdAt: DateTime.now(),
      );

      await service.syncSessionState(
        recipientId: 'test_recipient',
        targetDeviceId: 2,
        sessionState: sessionState,
      );

      expect(service.getSyncQueueSize(2), 1);

      service.clearSyncQueue(2);

      expect(service.getSyncQueueSize(2), 0);
    });

    test('should handle unknown operation type gracefully', () async {
      await deviceRegistration.registerDevice(deviceId: 1, deviceName: 'Source Device');

      final syncData = {
        'operation_type': 'unknown_operation',
        'sync_id': 'test_sync_123',
      };

      final result = await service.processIncomingSync(
        fromDeviceId: 1,
        syncData: syncData,
      );

      expect(result, isFalse);
    });

    test('should handle missing operation type gracefully', () async {
      await deviceRegistration.registerDevice(deviceId: 1, deviceName: 'Source Device');

      final syncData = {
        'sync_id': 'test_sync_123',
        // Missing operation_type
      };

      final result = await service.processIncomingSync(
        fromDeviceId: 1,
        syncData: syncData,
      );

      expect(result, isFalse);
    });
  });

  group('StateSyncOperation', () {
    test('should create sync operation with all fields', () {
      final sessionState = SignalSessionState(
        recipientId: 'test_recipient',
        createdAt: DateTime.now(),
      );
      final operation = StateSyncOperation(
        recipientId: 'test_recipient',
        targetDeviceId: 2,
        sessionState: sessionState,
        operationType: SyncOperationType.sessionState,
        timestamp: DateTime.now(),
      );

      expect(operation.recipientId, 'test_recipient');
      expect(operation.targetDeviceId, 2);
      expect(operation.sessionState, sessionState);
      expect(operation.operationType, SyncOperationType.sessionState);
    });

    test('should serialize to JSON correctly', () {
      final operation = StateSyncOperation(
        recipientId: 'test_recipient',
        targetDeviceId: 2,
        operationType: SyncOperationType.sessionState,
        timestamp: DateTime(2020, 1, 1, 12, 0, 0),
        additionalData: {'key': 'value'},
      );

      final json = operation.toJson();

      expect(json['recipient_id'], 'test_recipient');
      expect(json['target_device_id'], 2);
      expect(json['operation_type'], 'sessionState');
      expect(json['timestamp'], isA<String>());
      expect(json['additional_data'], {'key': 'value'});
    });
  });
}

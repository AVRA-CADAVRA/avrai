// Unit tests for Device Registration Service
//
// Tests device registration, management, and lifecycle

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/crypto/signal/device_registration_service.dart';
import 'package:avrai/core/crypto/signal/signal_key_manager.dart';
import 'package:avrai/core/crypto/signal/signal_ffi_bindings.dart';
import '../../../mocks/in_memory_flutter_secure_storage.dart';

void main() {
  group('DeviceRegistrationService', () {
    late DeviceRegistrationService service;
    late SignalKeyManager keyManager;

    setUp(() async {
      // Create test dependencies
      // Use in-memory storage to avoid platform-specific issues
      final secureStorage = InMemoryFlutterSecureStorage();
      final ffiBindings = SignalFFIBindings();
      
      keyManager = SignalKeyManager(
        secureStorage: secureStorage,
        ffiBindings: ffiBindings,
      );

      service = DeviceRegistrationService(keyManager: keyManager);
    });

    test('should register a new device', () async {
      final device = await service.registerDevice(
        deviceId: 1,
        deviceName: 'Test Device',
      );

      expect(device.deviceId, 1);
      expect(device.deviceName, 'Test Device');
      expect(device.isActive, isTrue);
      expect(device.registeredAt, isA<DateTime>());
    });

    test('should throw exception when registering duplicate device', () async {
      await service.registerDevice(deviceId: 1, deviceName: 'Device 1');

      expect(
        () => service.registerDevice(deviceId: 1, deviceName: 'Device 1'),
        throwsException,
      );
    });

    test('should get registered device by ID', () async {
      final registeredDevice = await service.registerDevice(
        deviceId: 2,
        deviceName: 'Device 2',
      );

      final retrievedDevice = service.getDevice(2);

      expect(retrievedDevice, isNotNull);
      expect(retrievedDevice!.deviceId, 2);
      expect(retrievedDevice.deviceName, 'Device 2');
    });

    test('should return null for non-existent device', () {
      expect(service.getDevice(999), isNull);
    });

    test('should get all registered devices', () async {
      await service.registerDevice(deviceId: 1, deviceName: 'Device 1');
      await service.registerDevice(deviceId: 2, deviceName: 'Device 2');
      await service.registerDevice(deviceId: 3, deviceName: 'Device 3');

      final allDevices = service.getAllDevices();

      expect(allDevices.length, 3);
      expect(allDevices.map((d) => d.deviceId).toSet(), {1, 2, 3});
    });

    test('should get only active devices', () async {
      await service.registerDevice(deviceId: 1, deviceName: 'Device 1');
      await service.registerDevice(deviceId: 2, deviceName: 'Device 2');
      await service.deactivateDevice(2);

      final activeDevices = service.getActiveDevices();

      expect(activeDevices.length, 1);
      expect(activeDevices.first.deviceId, 1);
    });

    test('should update device last seen timestamp', () async {
      final device = await service.registerDevice(deviceId: 1, deviceName: 'Device 1');
      final originalLastSeen = device.lastSeenAt;

      // Wait a moment to ensure timestamp difference
      await Future.delayed(const Duration(milliseconds: 10));

      await service.updateDeviceLastSeen(1);

      final updatedDevice = service.getDevice(1);
      expect(updatedDevice, isNotNull);
      expect(updatedDevice!.lastSeenAt.isAfter(originalLastSeen), isTrue);
    });

    test('should remove device', () async {
      await service.registerDevice(deviceId: 1, deviceName: 'Device 1');

      expect(service.getDevice(1), isNotNull);

      await service.removeDevice(1);

      expect(service.getDevice(1), isNull);
    });

    test('should deactivate device without removing it', () async {
      await service.registerDevice(deviceId: 1, deviceName: 'Device 1');

      await service.deactivateDevice(1);

      final device = service.getDevice(1);
      expect(device, isNotNull);
      expect(device!.isActive, isFalse);
    });

    test('should handle removing non-existent device gracefully', () async {
      // Should not throw
      await service.removeDevice(999);
    });

    test('should handle deactivating non-existent device gracefully', () async {
      // Should not throw
      await service.deactivateDevice(999);
    });
  });

  group('RegisteredDevice', () {
    test('should create device with all fields', () {
      final now = DateTime.now();
      final device = RegisteredDevice(
        deviceId: 1,
        deviceName: 'Test Device',
        registeredAt: now,
        lastSeenAt: now,
        isActive: true,
      );

      expect(device.deviceId, 1);
      expect(device.deviceName, 'Test Device');
      expect(device.registeredAt, now);
      expect(device.lastSeenAt, now);
      expect(device.isActive, isTrue);
    });

    test('should create copy with updated fields', () {
      final original = RegisteredDevice(
        deviceId: 1,
        deviceName: 'Original',
        registeredAt: DateTime(2020, 1, 1),
        lastSeenAt: DateTime(2020, 1, 1),
        isActive: true,
      );

      final updated = original.copyWith(
        deviceName: 'Updated',
        isActive: false,
      );

      expect(updated.deviceId, original.deviceId);
      expect(updated.deviceName, 'Updated');
      expect(updated.isActive, isFalse);
      expect(updated.registeredAt, original.registeredAt);
    });

    test('should serialize and deserialize to JSON correctly', () {
      final device = RegisteredDevice(
        deviceId: 1,
        deviceName: 'Test Device',
        registeredAt: DateTime(2020, 1, 1, 12, 0, 0),
        lastSeenAt: DateTime(2020, 1, 2, 12, 0, 0),
        isActive: true,
      );

      final json = device.toJson();
      final restored = RegisteredDevice.fromJson(json);

      expect(restored.deviceId, device.deviceId);
      expect(restored.deviceName, device.deviceName);
      expect(restored.registeredAt, device.registeredAt);
      expect(restored.lastSeenAt, device.lastSeenAt);
      expect(restored.isActive, device.isActive);
    });
  });
}

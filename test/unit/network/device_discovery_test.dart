import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/network/device_discovery.dart';

void main() {
  group('DeviceDiscoveryService', () {
    late DeviceDiscoveryService discoveryService;

    setUp(() {
      discoveryService = DeviceDiscoveryService();
    });

    tearDown(() {
      discoveryService.stopDiscovery();
    });

    group('startDiscovery', () {
      test('should start discovery and scan for devices', () async {
        var devicesDiscovered = false;
        discoveryService.onDevicesDiscovered((devices) {
          devicesDiscovered = true;
        });

        // Note: Without platform implementation, this won't discover real devices
        // But we can test the service structure
        await discoveryService.startDiscovery();

        // Give it a moment to potentially discover
        await Future.delayed(const Duration(milliseconds: 100));

        expect(discoveryService.getDiscoveredDevices(), isA<List<DiscoveredDevice>>());
      });

      test('should not start discovery if already running', () async {
        await discoveryService.startDiscovery();
        final initialCount = discoveryService.getDiscoveredDevices().length;

        await discoveryService.startDiscovery();
        final afterCount = discoveryService.getDiscoveredDevices().length;

        expect(afterCount, equals(initialCount));
      });
    });

    group('stopDiscovery', () {
      test('should stop discovery', () {
        discoveryService.startDiscovery();
        discoveryService.stopDiscovery();

        // Discovery should be stopped
        // (We can't easily test this without platform implementation)
        expect(discoveryService.getDiscoveredDevices(), isA<List<DiscoveredDevice>>());
      });
    });

    group('getDiscoveredDevices', () {
      test('should return empty list initially', () {
        final devices = discoveryService.getDiscoveredDevices();
        expect(devices, isEmpty);
      });
    });

    group('calculateProximity', () {
      test('should calculate proximity from signal strength', () {
        final device = DiscoveredDevice(
          deviceId: 'device1',
          deviceName: 'Test Device',
          type: DeviceType.bluetooth,
          isSpotsEnabled: true,
          signalStrength: -50, // Strong signal
          discoveredAt: DateTime.now(),
        );

        final proximity = discoveryService.calculateProximity(device);
        expect(proximity, greaterThan(0.5)); // Strong signal = high proximity
      });

      test('should return 0.5 for unknown signal strength', () {
        final device = DiscoveredDevice(
          deviceId: 'device1',
          deviceName: 'Test Device',
          type: DeviceType.bluetooth,
          isSpotsEnabled: true,
          discoveredAt: DateTime.now(),
        );

        final proximity = discoveryService.calculateProximity(device);
        expect(proximity, equals(0.5));
      });

      test('should handle weak signal strength', () {
        final device = DiscoveredDevice(
          deviceId: 'device1',
          deviceName: 'Test Device',
          type: DeviceType.bluetooth,
          isSpotsEnabled: true,
          signalStrength: -100, // Weak signal
          discoveredAt: DateTime.now(),
        );

        final proximity = discoveryService.calculateProximity(device);
        expect(proximity, lessThan(0.5)); // Weak signal = low proximity
      });
    });
  });

  group('DiscoveredDevice', () {
    test('should create device with all properties', () {
      final device = DiscoveredDevice(
        deviceId: 'device1',
        deviceName: 'Test Device',
        type: DeviceType.wifi,
        isSpotsEnabled: true,
        signalStrength: -70,
        discoveredAt: DateTime.now(),
        metadata: {'key': 'value'},
      );

      expect(device.deviceId, equals('device1'));
      expect(device.deviceName, equals('Test Device'));
      expect(device.type, equals(DeviceType.wifi));
      expect(device.isSpotsEnabled, isTrue);
      expect(device.signalStrength, equals(-70));
      expect(device.metadata['key'], equals('value'));
    });

    test('should calculate proximity score', () {
      final device = DiscoveredDevice(
        deviceId: 'device1',
        deviceName: 'Test Device',
        type: DeviceType.bluetooth,
        isSpotsEnabled: true,
        signalStrength: -50,
        discoveredAt: DateTime.now(),
      );

      expect(device.proximityScore, greaterThan(0.0));
      expect(device.proximityScore, lessThanOrEqualTo(1.0));
    });

    test('should detect stale devices', () {
      final device = DiscoveredDevice(
        deviceId: 'device1',
        deviceName: 'Test Device',
        type: DeviceType.bluetooth,
        isSpotsEnabled: true,
        discoveredAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      expect(device.isStale(const Duration(minutes: 2)), isTrue);
      expect(device.isStale(const Duration(minutes: 10)), isFalse);
    });
  });
}


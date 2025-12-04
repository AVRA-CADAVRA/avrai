/// Tests for Device Discovery Status Page
/// 
/// Part of Feature Matrix Phase 1: Critical UI/UX
/// Section 1.2: Device Discovery UI

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:spots/core/network/device_discovery.dart';
import 'package:spots/presentation/pages/network/device_discovery_page.dart';

void main() {
  setUpAll(() {
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  group('DeviceDiscoveryPage', () {
    test('data models instantiate correctly', () {
      final device = DiscoveredDevice(
        deviceId: 'test-device',
        deviceName: 'Test Device',
        type: DeviceType.wifi,
        isSpotsEnabled: true,
        discoveredAt: DateTime.now(),
      );
      
      expect(device.deviceId, equals('test-device'));
      expect(device.deviceName, equals('Test Device'));
      expect(device.type, equals(DeviceType.wifi));
      expect(device.isSpotsEnabled, isTrue);
    });

    testWidgets('page renders with discovery inactive state', (tester) async {
      // Setup mock discovery service
      final mockService = MockDeviceDiscoveryService();
      GetIt.instance.registerSingleton<DeviceDiscoveryService>(mockService);

      await tester.pumpWidget(
        MaterialApp(
          home: const DeviceDiscoveryPage(),
        ),
      );

      // Wait for initialization
      await tester.pumpAndSettle();

      // Should show title
      expect(find.text('Device Discovery'), findsOneWidget);
      
      // Should show inactive status
      expect(find.text('Discovery Inactive'), findsOneWidget);
      expect(find.text('Start Discovery'), findsOneWidget);
    });

    testWidgets('displays discovered devices when scanning', (tester) async {
      final mockService = MockDeviceDiscoveryService();
      mockService.setDevices([
        DiscoveredDevice(
          deviceId: 'device-1',
          deviceName: 'Test Device 1',
          type: DeviceType.wifi,
          isSpotsEnabled: true,
          signalStrength: -50,
          discoveredAt: DateTime.now(),
        ),
      ]);
      
      GetIt.instance.registerSingleton<DeviceDiscoveryService>(mockService);

      await tester.pumpWidget(
        MaterialApp(
          home: const DeviceDiscoveryPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Start discovery
      await tester.tap(find.text('Start Discovery'));
      await tester.pumpAndSettle();

      // Should show active status
      expect(find.text('Discovery Active'), findsOneWidget);
      
      // Should show device count
      expect(find.textContaining('1 device found'), findsOneWidget);
    });

    testWidgets('shows info dialog when info button tapped', (tester) async {
      final mockService = MockDeviceDiscoveryService();
      GetIt.instance.registerSingleton<DeviceDiscoveryService>(mockService);

      await tester.pumpWidget(
        MaterialApp(
          home: const DeviceDiscoveryPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap info button
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();

      // Should show dialog
      expect(find.text('About Device Discovery'), findsOneWidget);
      expect(find.textContaining('Privacy:'), findsOneWidget);
    });
  });
}

/// Mock implementation of DeviceDiscoveryService for testing
class MockDeviceDiscoveryService extends DeviceDiscoveryService {
  List<DiscoveredDevice> _devices = [];
  bool _isScanning = false;

  MockDeviceDiscoveryService() : super(platform: null);

  void setDevices(List<DiscoveredDevice> devices) {
    _devices = devices;
  }

  @override
  Future<void> startDiscovery({
    Duration scanInterval = const Duration(seconds: 5),
    Duration deviceTimeout = const Duration(minutes: 2),
  }) async {
    _isScanning = true;
  }

  @override
  void stopDiscovery() {
    _isScanning = false;
  }

  @override
  List<DiscoveredDevice> getDiscoveredDevices() {
    return _devices;
  }

  @override
  DiscoveredDevice? getDevice(String deviceId) {
    return _devices.where((d) => d.deviceId == deviceId).firstOrNull;
  }
}

/// Tests for Discovered Devices Widget
/// 
/// Part of Feature Matrix Phase 1: Critical UI/UX
/// Section 1.2: Device Discovery UI

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:spots/core/network/device_discovery.dart';
import 'package:spots/core/ai2ai/connection_orchestrator.dart';
import 'package:spots/presentation/widgets/network/discovered_devices_widget.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  setUpAll(() {
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  group('DiscoveredDevicesWidget', () {
    testWidgets('displays empty state when no devices', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiscoveredDevicesWidget(
              devices: const [],
            ),
          ),
        ),
      );

      expect(find.text('No devices discovered'), findsOneWidget);
      expect(find.byIcon(Icons.devices_other), findsOneWidget);
    });

    testWidgets('displays device list when devices provided', (tester) async {
      final devices = [
        DiscoveredDevice(
          deviceId: 'device-1',
          deviceName: 'Test Device',
          type: DeviceType.wifi,
          isSpotsEnabled: true,
          signalStrength: -50,
          discoveredAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiscoveredDevicesWidget(
              devices: devices,
            ),
          ),
        ),
      );

      expect(find.text('Test Device'), findsOneWidget);
      expect(find.text('WiFi'), findsOneWidget);
    });

    testWidgets('displays personality badge for AI-enabled devices', (tester) async {
      final devices = [
        DiscoveredDevice(
          deviceId: 'device-1',
          deviceName: 'AI Device',
          type: DeviceType.bluetooth,
          isSpotsEnabled: true,
          personalityData: const AnonymizedVibeData(
            personalityId: 'test-id',
            vibeSignature: 'signature',
            timestamp: '2025-01-01T00:00:00Z',
          ),
          discoveredAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiscoveredDevicesWidget(
              devices: devices,
            ),
          ),
        ),
      );

      expect(find.text('AI Enabled'), findsOneWidget);
      expect(find.byIcon(Icons.psychology), findsOneWidget);
    });

    testWidgets('shows proximity indicators correctly', (tester) async {
      final devices = [
        DiscoveredDevice(
          deviceId: 'close-device',
          deviceName: 'Close Device',
          type: DeviceType.wifi,
          isSpotsEnabled: true,
          signalStrength: -30, // Strong signal = close
          discoveredAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiscoveredDevicesWidget(
              devices: devices,
            ),
          ),
        ),
      );

      expect(find.textContaining('Very Close'), findsOneWidget);
      expect(find.textContaining('-30 dBm'), findsOneWidget);
    });

    testWidgets('connection button triggers callback', (tester) async {
      final devices = [
        DiscoveredDevice(
          deviceId: 'device-1',
          deviceName: 'Test Device',
          type: DeviceType.wifi,
          isSpotsEnabled: true,
          discoveredAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiscoveredDevicesWidget(
              devices: devices,
              showConnectionButton: true,
            ),
          ),
        ),
      );

      // Should have connect button
      expect(find.text('Connect'), findsOneWidget);

      // Tap connect button
      await tester.tap(find.text('Connect'));
      await tester.pump();

      // Should show connecting state
      expect(find.text('Connecting...'), findsOneWidget);
    });

    testWidgets('hides connection button when showConnectionButton is false', (tester) async {
      final devices = [
        DiscoveredDevice(
          deviceId: 'device-1',
          deviceName: 'Test Device',
          type: DeviceType.wifi,
          isSpotsEnabled: true,
          discoveredAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiscoveredDevicesWidget(
              devices: devices,
              showConnectionButton: false,
            ),
          ),
        ),
      );

      // Should not have connect button
      expect(find.text('Connect'), findsNothing);
    });

    testWidgets('calls onDeviceTap when device card is tapped', (tester) async {
      DiscoveredDevice? tappedDevice;
      
      final devices = [
        DiscoveredDevice(
          deviceId: 'device-1',
          deviceName: 'Tappable Device',
          type: DeviceType.wifi,
          isSpotsEnabled: true,
          discoveredAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiscoveredDevicesWidget(
              devices: devices,
              onDeviceTap: (device) {
                tappedDevice = device;
              },
            ),
          ),
        ),
      );

      // Tap on device card
      await tester.tap(find.text('Tappable Device'));
      await tester.pumpAndSettle();

      expect(tappedDevice, isNotNull);
      expect(tappedDevice?.deviceName, equals('Tappable Device'));
    });
  });
}

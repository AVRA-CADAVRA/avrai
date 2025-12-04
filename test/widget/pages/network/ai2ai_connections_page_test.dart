/// Tests for AI2AI Connections Page
/// 
/// Part of Feature Matrix Phase 1: Critical UI/UX
/// Section 1.2: Device Discovery UI - Integration Tests

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:spots/core/network/device_discovery.dart';
import 'package:spots/core/ai2ai/connection_orchestrator.dart';
import 'package:spots/core/models/connection_metrics.dart';
import 'package:spots/presentation/pages/network/ai2ai_connections_page.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  setUpAll(() {
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  group('AI2AIConnectionsPage Integration', () {
    testWidgets('page renders with all tabs', (tester) async {
      _setupMockServices();

      await tester.pumpWidget(
        MaterialApp(
          home: const AI2AIConnectionsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Should show title
      expect(find.text('AI2AI Network'), findsOneWidget);
      
      // Should show all tabs
      expect(find.text('Discovery'), findsOneWidget);
      expect(find.text('Devices'), findsOneWidget);
      expect(find.text('AI Connections'), findsOneWidget);
    });

    testWidgets('discovery tab shows status and actions', (tester) async {
      _setupMockServices();

      await tester.pumpWidget(
        MaterialApp(
          home: const AI2AIConnectionsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Should show discovery status
      expect(find.text('Discovery Inactive'), findsOneWidget);
      expect(find.text('Start Discovery'), findsOneWidget);
      
      // Should show network statistics
      expect(find.text('Network Statistics'), findsOneWidget);
    });

    testWidgets('can navigate between tabs', (tester) async {
      _setupMockServices();

      await tester.pumpWidget(
        MaterialApp(
          home: const AI2AIConnectionsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on Devices tab
      await tester.tap(find.text('Devices'));
      await tester.pumpAndSettle();

      // Should show devices content
      expect(find.text('Discovery is off'), findsOneWidget);

      // Tap on AI Connections tab
      await tester.tap(find.text('AI Connections'));
      await tester.pumpAndSettle();

      // Should show connections content
      expect(find.text('No Active AI Connections'), findsOneWidget);
    });

    testWidgets('discovery toggle works', (tester) async {
      _setupMockServices();

      await tester.pumpWidget(
        MaterialApp(
          home: const AI2AIConnectionsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Start discovery
      await tester.tap(find.text('Start Discovery'));
      await tester.pumpAndSettle();

      // Should show active status
      expect(find.text('Discovery Active'), findsOneWidget);
      expect(find.text('Stop Discovery'), findsOneWidget);
    });

    testWidgets('settings navigation works', (tester) async {
      _setupMockServices();

      await tester.pumpWidget(
        MaterialApp(
          home: const AI2AIConnectionsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap settings button
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Should navigate to settings page
      expect(find.text('Discovery Settings'), findsWidgets);
    });

    testWidgets('shows network statistics correctly', (tester) async {
      final mockDiscovery = MockDeviceDiscoveryService();
      mockDiscovery.setDevices([
        DiscoveredDevice(
          deviceId: 'device-1',
          deviceName: 'Test Device',
          type: DeviceType.wifi,
          isSpotsEnabled: true,
          personalityData: const AnonymizedVibeData(
            personalityId: 'test-id',
            vibeSignature: 'signature',
            timestamp: '2025-01-01T00:00:00Z',
          ),
          discoveredAt: DateTime.now(),
        ),
      ]);

      final mockOrchestrator = MockVibeConnectionOrchestrator();
      
      GetIt.instance.registerSingleton<DeviceDiscoveryService>(mockDiscovery);
      GetIt.instance.registerSingleton<VibeConnectionOrchestrator>(mockOrchestrator);

      await tester.pumpWidget(
        MaterialApp(
          home: const AI2AIConnectionsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Should show statistics
      expect(find.text('1'), findsWidgets); // Discovered count
      expect(find.text('Discovered'), findsOneWidget);
      expect(find.text('AI Enabled'), findsOneWidget);
    });

    testWidgets('info dialog can be opened', (tester) async {
      _setupMockServices();

      await tester.pumpWidget(
        MaterialApp(
          home: const AI2AIConnectionsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on "How Discovery Works"
      await tester.tap(find.text('How Discovery Works'));
      await tester.pumpAndSettle();

      // Should show dialog
      expect(find.text('AI2AI Discovery'), findsOneWidget);
      expect(find.textContaining('Your AI broadcasts'), findsOneWidget);
    });
  });
}

/// Helper to setup mock services
void _setupMockServices() {
  final mockDiscovery = MockDeviceDiscoveryService();
  final mockOrchestrator = MockVibeConnectionOrchestrator();
  
  GetIt.instance.registerSingleton<DeviceDiscoveryService>(mockDiscovery);
  GetIt.instance.registerSingleton<VibeConnectionOrchestrator>(mockOrchestrator);
}

/// Mock DeviceDiscoveryService
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

/// Mock VibeConnectionOrchestrator
class MockVibeConnectionOrchestrator extends VibeConnectionOrchestrator {
  List<ConnectionMetrics> _connections = [];

  MockVibeConnectionOrchestrator() : super(
    vibeAnalyzer: _createMockAnalyzer(),
    connectivity: _createMockConnectivity(),
  );

  void setConnections(List<ConnectionMetrics> connections) {
    _connections = connections;
  }

  @override
  List<ConnectionMetrics> getActiveConnections() {
    return _connections;
  }

  static _createMockAnalyzer() {
    throw UnimplementedError('Mock simplified for testing');
  }

  static _createMockConnectivity() {
    throw UnimplementedError('Mock simplified for testing');
  }
}


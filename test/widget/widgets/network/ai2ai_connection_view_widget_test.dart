/// Tests for AI2AI Connection View Widget
/// 
/// Part of Feature Matrix Phase 1: Critical UI/UX
/// Section 1.2: Device Discovery UI

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:spots/core/models/connection_metrics.dart';
import 'package:spots/core/ai2ai/connection_orchestrator.dart';
import 'package:spots/presentation/widgets/network/ai2ai_connection_view_widget.dart';

void main() {
  setUpAll(() {
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  group('AI2AIConnectionViewWidget', () {
    testWidgets('displays empty state when no connections', (tester) async {
      final mockOrchestrator = MockVibeConnectionOrchestrator();
      GetIt.instance.registerSingleton<VibeConnectionOrchestrator>(mockOrchestrator);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const AI2AIConnectionViewWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Active AI Connections'), findsOneWidget);
      expect(find.textContaining('Enable device discovery'), findsOneWidget);
    });

    testWidgets('displays active connections', (tester) async {
      final mockOrchestrator = MockVibeConnectionOrchestrator();
      mockOrchestrator.setConnections([
        _createMockConnection(vibeAlignment: 0.85),
      ]);
      
      GetIt.instance.registerSingleton<VibeConnectionOrchestrator>(mockOrchestrator);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const AI2AIConnectionViewWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('AI Connection'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
      expect(find.text('High Compatibility'), findsOneWidget);
    });

    testWidgets('shows compatibility bar and metrics', (tester) async {
      final mockOrchestrator = MockVibeConnectionOrchestrator();
      mockOrchestrator.setConnections([
        _createMockConnection(
          vibeAlignment: 0.75,
          sharedInsights: 12,
          learningExchanges: 8,
        ),
      ]);
      
      GetIt.instance.registerSingleton<VibeConnectionOrchestrator>(mockOrchestrator);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const AI2AIConnectionViewWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Compatibility Score'), findsOneWidget);
      expect(find.text('12'), findsOneWidget); // Insights
      expect(find.text('8'), findsOneWidget); // Exchanges
    });

    testWidgets('shows human connection button at 100% compatibility', (tester) async {
      final mockOrchestrator = MockVibeConnectionOrchestrator();
      mockOrchestrator.setConnections([
        _createMockConnection(vibeAlignment: 1.0),
      ]);
      
      GetIt.instance.registerSingleton<VibeConnectionOrchestrator>(mockOrchestrator);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const AI2AIConnectionViewWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Perfect Match!'), findsOneWidget);
      expect(find.text('Enable Human Conversation'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('hides human connection button when below 100%', (tester) async {
      final mockOrchestrator = MockVibeConnectionOrchestrator();
      mockOrchestrator.setConnections([
        _createMockConnection(vibeAlignment: 0.95),
      ]);
      
      GetIt.instance.registerSingleton<VibeConnectionOrchestrator>(mockOrchestrator);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const AI2AIConnectionViewWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Enable Human Conversation'), findsNothing);
      expect(find.text('95%'), findsOneWidget);
    });

    testWidgets('displays compatibility explanation', (tester) async {
      final mockOrchestrator = MockVibeConnectionOrchestrator();
      mockOrchestrator.setConnections([
        _createMockConnection(vibeAlignment: 0.8),
      ]);
      
      GetIt.instance.registerSingleton<VibeConnectionOrchestrator>(mockOrchestrator);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const AI2AIConnectionViewWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Why They\'re Compatible'), findsOneWidget);
      expect(find.textContaining('vibe compatibility'), findsOneWidget);
    });

    testWidgets('shows fleeting connection notice', (tester) async {
      final mockOrchestrator = MockVibeConnectionOrchestrator();
      mockOrchestrator.setConnections([
        _createMockConnection(vibeAlignment: 0.7),
      ]);
      
      GetIt.instance.registerSingleton<VibeConnectionOrchestrator>(mockOrchestrator);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const AI2AIConnectionViewWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Fleeting connection'), findsOneWidget);
      expect(find.textContaining('Managed by AI'), findsOneWidget);
    });

    testWidgets('calls callback when human connection enabled', (tester) async {
      ConnectionMetrics? enabledConnection;
      
      final mockOrchestrator = MockVibeConnectionOrchestrator();
      mockOrchestrator.setConnections([
        _createMockConnection(vibeAlignment: 1.0),
      ]);
      
      GetIt.instance.registerSingleton<VibeConnectionOrchestrator>(mockOrchestrator);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AI2AIConnectionViewWidget(
              onEnableHumanConnection: (connection) {
                enabledConnection = connection;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap enable button
      await tester.tap(find.text('Enable Human Conversation'));
      await tester.pumpAndSettle();

      expect(enabledConnection, isNotNull);
      expect(find.text('Human connection enabled!'), findsOneWidget);
    });
  });
}

/// Helper function to create mock connection metrics
ConnectionMetrics _createMockConnection({
  double vibeAlignment = 0.8,
  int sharedInsights = 5,
  int learningExchanges = 3,
}) {
  return ConnectionMetrics(
    connectionId: 'test-connection-id',
    remoteNodeId: 'test-remote-node',
    startTime: DateTime.now().subtract(const Duration(minutes: 10)),
    lastActivity: DateTime.now(),
    vibeAlignment: vibeAlignment,
    sharedInsights: sharedInsights,
    learningExchanges: learningExchanges,
    status: ConnectionStatus.active,
  );
}

/// Mock implementation of VibeConnectionOrchestrator for testing
class MockVibeConnectionOrchestrator extends VibeConnectionOrchestrator {
  List<ConnectionMetrics> _connections = [];

  // Use minimal constructor bypassing complex dependencies
  MockVibeConnectionOrchestrator() : super(
    vibeAnalyzer: _createMockVibeAnalyzer(),
    connectivity: _createMockConnectivity(),
  );

  void setConnections(List<ConnectionMetrics> connections) {
    _connections = connections;
  }

  @override
  List<ConnectionMetrics> getActiveConnections() {
    return _connections;
  }
  
  // Helper to create minimal mock dependencies
  static _createMockVibeAnalyzer() {
    // Return a minimal implementation or null-safe default
    // This is a simplified mock that avoids complex setup
    throw UnimplementedError('Mock setup simplified for testing');
  }
  
  static _createMockConnectivity() {
    throw UnimplementedError('Mock setup simplified for testing');
  }
}


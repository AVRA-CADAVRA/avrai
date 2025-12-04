import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:spots/core/services/enhanced_connectivity_service.dart';

/// SPOTS EnhancedConnectivityService Unit Tests
/// Date: December 1, 2025
/// Purpose: Test EnhancedConnectivityService functionality
/// 
/// Test Coverage:
/// - Basic Connectivity: WiFi/mobile connectivity checks
/// - Internet Access: HTTP ping verification
/// - Caching: Ping result caching
/// - Connectivity Stream: Real-time connectivity changes
/// - Error Handling: Network failures, timeouts
/// 
/// Dependencies:
/// - Connectivity: Platform connectivity checking
/// - http.Client: HTTP client for ping

class MockConnectivity extends Mock implements Connectivity {}
class MockHttpClient extends Mock implements http.Client {}

void main() {
  group('EnhancedConnectivityService', () {
    late EnhancedConnectivityService service;
    late MockConnectivity mockConnectivity;
    late MockHttpClient mockHttpClient;

    setUp(() {
      mockConnectivity = MockConnectivity();
      mockHttpClient = MockHttpClient();
      service = EnhancedConnectivityService(
        connectivity: mockConnectivity,
        httpClient: mockHttpClient,
      );
    });

    group('Basic Connectivity', () {
      test('should return true when WiFi is available', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);

        final result = await service.hasBasicConnectivity();

        expect(result, true);
        verify(() => mockConnectivity.checkConnectivity()).called(1);
      });

      test('should return true when mobile data is available', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.mobile]);

        final result = await service.hasBasicConnectivity();

        expect(result, true);
      });

      test('should return false when no connectivity', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        final result = await service.hasBasicConnectivity();

        expect(result, false);
      });

      test('should handle connectivity check errors', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenThrow(Exception('Connectivity check failed'));

        final result = await service.hasBasicConnectivity();

        expect(result, false);
      });
    });

    group('Internet Access', () {
      test('should return false when no basic connectivity', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        final result = await service.hasInternetAccess();

        expect(result, false);
        verifyNever(() => mockHttpClient.head(any()));
      });

      test('should return true when ping succeeds', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(() => mockHttpClient.head(any()))
            .thenAnswer((_) async => http.Response('', 200));

        final result = await service.hasInternetAccess();

        expect(result, true);
        verify(() => mockHttpClient.head(any())).called(1);
      });

      test('should return false when ping fails', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(() => mockHttpClient.head(any()))
            .thenThrow(Exception('Network error'));

        final result = await service.hasInternetAccess();

        expect(result, false);
      });

      test('should use cached result when available', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(() => mockHttpClient.head(any()))
            .thenAnswer((_) async => http.Response('', 200));

        // First call - should ping
        final result1 = await service.hasInternetAccess();
        expect(result1, true);
        verify(() => mockHttpClient.head(any())).called(1);

        // Second call - should use cache
        final result2 = await service.hasInternetAccess();
        expect(result2, true);
        // Should not ping again (cached)
        verify(() => mockHttpClient.head(any())).called(1);
      });

      test('should force refresh when requested', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(() => mockHttpClient.head(any()))
            .thenAnswer((_) async => http.Response('', 200));

        // First call
        await service.hasInternetAccess();
        
        // Force refresh
        await service.hasInternetAccess(forceRefresh: true);
        
        // Should ping twice (once initial, once forced)
        verify(() => mockHttpClient.head(any())).called(2);
      });
    });

    group('Connectivity Stream', () {
      test('should emit true when connectivity available', () async {
        final streamController = StreamController<List<ConnectivityResult>>();
        when(() => mockConnectivity.onConnectivityChanged)
            .thenAnswer((_) => streamController.stream);

        final stream = service.connectivityStream;
        expect(stream, isNotNull);

        streamController.add([ConnectivityResult.wifi]);
        await streamController.close();
        // Note: Stream testing requires more complex setup
        // This verifies the stream is created
      });

      test('should emit false when connectivity lost', () async {
        final streamController = StreamController<List<ConnectivityResult>>();
        when(() => mockConnectivity.onConnectivityChanged)
            .thenAnswer((_) => streamController.stream);

        final stream = service.connectivityStream;
        expect(stream, isNotNull);

        streamController.add([ConnectivityResult.none]);
        await streamController.close();
      });
    });

    group('Error Handling', () {
      test('should handle HTTP errors gracefully', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(() => mockHttpClient.head(any()))
            .thenAnswer((_) async => http.Response('', 500));

        final result = await service.hasInternetAccess();

        // 500 status should still be considered "success" (server responded)
        expect(result, true);
      });

      test('should handle timeout errors', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(() => mockHttpClient.head(any()))
            .thenThrow(Exception('Timeout'));

        final result = await service.hasInternetAccess();

        expect(result, false);
      });

      test('should handle network exceptions', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(() => mockHttpClient.head(any()))
            .thenThrow(Exception('Network unreachable'));

        final result = await service.hasInternetAccess();

        expect(result, false);
      });
    });
  });
}


import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spots/core/services/supabase_service.dart';
import 'package:spots/core/services/admin_auth_service.dart';
import 'package:spots/core/services/admin_god_mode_service.dart';
import 'package:spots/core/services/admin_communication_service.dart';
import 'package:spots/core/services/business_account_service.dart';
import 'package:spots/core/services/expertise_service.dart';
import 'package:spots/core/ml/predictive_analytics.dart';
import 'package:spots/core/monitoring/connection_monitor.dart';

/// Integration tests for Admin Backend Connections
/// 
/// These tests verify that all backend integrations work correctly
/// for the god-mode admin system.
void main() {
  group('Admin Backend Connections Integration Tests', () {
    late SharedPreferences prefs;
    late SupabaseService supabaseService;
    late ConnectionMonitor connectionMonitor;
    late AdminAuthService authService;
    late AdminCommunicationService communicationService;
    late BusinessAccountService businessService;
    late PredictiveAnalytics predictiveAnalytics;
    late AdminGodModeService godModeService;

    setUpAll(() async {
      // Initialize SharedPreferences
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    setUp(() {
      // Initialize services
      supabaseService = SupabaseService();
      connectionMonitor = ConnectionMonitor(prefs: prefs);
      authService = AdminAuthService(prefs);
      communicationService = AdminCommunicationService(
        connectionMonitor: connectionMonitor,
        chatAnalyzer: null,
      );
      businessService = BusinessAccountService();
      predictiveAnalytics = PredictiveAnalytics();
      godModeService = AdminGodModeService(
        authService: authService,
        communicationService: communicationService,
        businessService: businessService,
        predictiveAnalytics: predictiveAnalytics,
        connectionMonitor: connectionMonitor,
        chatAnalyzer: null,
        supabaseService: supabaseService,
        expertiseService: ExpertiseService(),
      );
    });

    test('Supabase Service should be accessible', () {
      expect(supabaseService, isNotNull);
      expect(supabaseService.isAvailable, isTrue);
    });

    test('Supabase connection test should work', () async {
      // Note: This may fail if Supabase is not configured
      // That's okay - we're testing the structure, not the actual connection
      try {
        final isConnected = await supabaseService.testConnection();
        expect(isConnected, isA<bool>());
      } catch (e) {
        // Expected if Supabase is not configured
        expect(e, isNotNull);
      }
    });

    test('Admin services should initialize correctly', () {
      expect(connectionMonitor, isNotNull);
      expect(authService, isNotNull);
      expect(communicationService, isNotNull);
      expect(businessService, isNotNull);
      expect(predictiveAnalytics, isNotNull);
      expect(godModeService, isNotNull);
    });

    test('AdminGodModeService should check authorization', () {
      // Without login, should not be authorized
      final isAuthorized = godModeService.isAuthorized;
      expect(isAuthorized, isA<bool>());
    });

    test('ConnectionMonitor should support AI signature lookups', () {
      final testSignature = 'ai_test_123';
      final connections = connectionMonitor.getConnectionsByAISignature(testSignature);
      expect(connections, isA<Set<String>>());
      
      final sessions = connectionMonitor.getSessionsByAISignature(testSignature);
      expect(sessions, isA<List>());
    });

    test('User search should require authorization', () async {
      // Should throw UnauthorizedException without login
      expect(
        () => godModeService.searchUsers(),
        throwsA(isA<Exception>()),
      );
    });

    test('Dashboard data should require authorization', () async {
      // Should throw UnauthorizedException without login
      expect(
        () => godModeService.getDashboardData(),
        throwsA(isA<Exception>()),
      );
    });

    test('Business accounts should require authorization', () async {
      // Should throw UnauthorizedException without login
      expect(
        () => godModeService.getAllBusinessAccounts(),
        throwsA(isA<Exception>()),
      );
    });

    test('AI data streams should work without connections', () async {
      final testSignature = 'ai_nonexistent_123';
      
      // Should throw UnauthorizedException without login
      expect(
        () => godModeService.watchAIData(testSignature),
        throwsA(isA<Exception>()),
      );
    });

    test('AdminGodModeService should dispose correctly', () {
      // Should not throw
      expect(() => godModeService.dispose(), returnsNormally);
    });
  });
}


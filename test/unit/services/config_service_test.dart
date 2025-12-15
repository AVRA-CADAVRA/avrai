import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/config_service.dart';
import '../../helpers/platform_channel_helper.dart';

/// Config Service Tests
/// Tests configuration service for app settings
void main() {
  setUpAll(() async {
    await setupTestStorage();
  });

  tearDownAll(() async {
    await cleanupTestStorage();
  });

  group('ConfigService', () {
    // Removed: Constructor group
    // These tests only verified Dart constructor behavior and property assignment, not business logic
    // Constructor property assignment is tested by the language itself

    group('Environment Checks', () {
      test(
          'should correctly identify production, development, and staging environments with case-insensitive matching',
          () {
        // Test business logic: environment detection with case handling
        const prodConfig = ConfigService(
          environment: 'production',
          supabaseUrl: 'https://prod.supabase.co',
          supabaseAnonKey: 'prod_key',
        );
        const prodConfigUpper = ConfigService(
          environment: 'PRODUCTION',
          supabaseUrl: 'https://prod.supabase.co',
          supabaseAnonKey: 'prod_key',
        );
        const devConfig = ConfigService(
          environment: 'development',
          supabaseUrl: 'https://dev.supabase.co',
          supabaseAnonKey: 'dev_key',
        );
        const devConfigUpper = ConfigService(
          environment: 'DEVELOPMENT',
          supabaseUrl: 'https://dev.supabase.co',
          supabaseAnonKey: 'dev_key',
        );
        const stagingConfig = ConfigService(
          environment: 'staging',
          supabaseUrl: 'https://staging.supabase.co',
          supabaseAnonKey: 'staging_key',
        );

        expect(prodConfig.isProd, isTrue);
        expect(prodConfig.isDev, isFalse);
        expect(prodConfigUpper.isProd, isTrue); // Case insensitive
        expect(devConfig.isDev, isTrue);
        expect(devConfig.isProd, isFalse);
        expect(devConfigUpper.isDev, isTrue); // Case insensitive
        expect(stagingConfig.isProd, isFalse);
        expect(stagingConfig.isDev, isFalse);
      });
    });

    group('Configuration Scenarios', () {
      test(
          'should correctly configure production, development, and different inference backends',
          () {
        // Test business logic: configuration scenarios for different environments and backends
        const prodConfig = ConfigService(
          environment: 'production',
          supabaseUrl: 'https://prod.supabase.co',
          supabaseAnonKey: 'prod_anon_key',
          debug: false,
        );
        const devConfig = ConfigService(
          environment: 'development',
          supabaseUrl: 'https://dev.supabase.co',
          supabaseAnonKey: 'dev_anon_key',
          debug: true,
        );
        const onnxConfig = ConfigService(
          environment: 'development',
          supabaseUrl: 'https://test.supabase.co',
          supabaseAnonKey: 'test_key',
          inferenceBackend: 'onnx',
        );
        const tfliteConfig = ConfigService(
          environment: 'development',
          supabaseUrl: 'https://test.supabase.co',
          supabaseAnonKey: 'test_key',
          inferenceBackend: 'tflite',
        );
        const coremlConfig = ConfigService(
          environment: 'development',
          supabaseUrl: 'https://test.supabase.co',
          supabaseAnonKey: 'test_key',
          inferenceBackend: 'coreml',
        );

        expect(prodConfig.isProd, isTrue);
        expect(prodConfig.debug, isFalse);
        expect(devConfig.isDev, isTrue);
        expect(devConfig.debug, isTrue);
        expect(onnxConfig.inferenceBackend, equals('onnx'));
        expect(tfliteConfig.inferenceBackend, equals('tflite'));
        expect(coremlConfig.inferenceBackend, equals('coreml'));
      });
    });
  });
}

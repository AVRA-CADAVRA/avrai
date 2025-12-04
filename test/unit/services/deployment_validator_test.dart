import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:spots/core/services/deployment_validator.dart';
import 'package:spots/core/services/performance_monitor.dart';
import 'package:spots/core/services/security_validator.dart';
import 'package:shared_preferences/shared_preferences.dart' as real_prefs;
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks/mock_dependencies.mocks.dart';
import '../../helpers/platform_channel_helper.dart';

void main() {
  group('DeploymentValidator Tests', () {
    late DeploymentValidator validator;
    late PerformanceMonitor performanceMonitor;
    late SecurityValidator securityValidator;
    late MockStorageService mockStorageService;
    late SharedPreferences prefs;

    setUpAll(() async {
      await setupTestStorage();
      real_prefs.SharedPreferences.setMockInitialValues({});
    });

    setUp(() async {
      mockStorageService = MockStorageService();
      prefs = await real_prefs.SharedPreferences.getInstance();

      performanceMonitor = PerformanceMonitor(
        storageService: mockStorageService,
        prefs: prefs,
      );
      securityValidator = SecurityValidator();

      validator = DeploymentValidator(
        performanceMonitor: performanceMonitor,
        securityValidator: securityValidator,
      );
    });

    tearDown(() async {
      await performanceMonitor.stopMonitoring();
      await prefs.clear();
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });

    group('validateDeployment', () {
      test('validates deployment readiness', () async {
        // Arrange
        when(mockStorageService.setObject(
          any,
          any,
          box: anyNamed('box'),
        )).thenAnswer((_) async => true);

        // Act
        final result = await validator.validateDeployment();

        // Assert
        expect(result, isNotNull);
        expect(result.isValid, isA<bool>());
        expect(result.score, greaterThanOrEqualTo(0.0));
        expect(result.score, lessThanOrEqualTo(1.0));
      });
    });

    group('checkPrivacyCompliance', () {
      test('checks privacy compliance', () async {
        // Act
        final isCompliant = await validator.checkPrivacyCompliance();

        // Assert
        expect(isCompliant, isA<bool>());
      });
    });

    group('checkPerformanceMetrics', () {
      test('checks performance metrics', () async {
        // Arrange
        when(mockStorageService.setObject(
          any,
          any,
          box: anyNamed('box'),
        )).thenAnswer((_) async => true);

        // Act
        final meetsThreshold = await validator.checkPerformanceMetrics();

        // Assert
        expect(meetsThreshold, isA<bool>());
      });
    });
  });
}

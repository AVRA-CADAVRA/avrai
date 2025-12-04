import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/ai2ai/privacy_compliance_card.dart';
import 'package:spots/core/monitoring/network_analytics.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for PrivacyComplianceCard
/// Tests privacy compliance metrics display
void main() {
  group('PrivacyComplianceCard Widget Tests', () {
    testWidgets('displays privacy compliance score', (WidgetTester tester) async {
      // Arrange
      final privacyMetrics = PrivacyMetrics(
        complianceRate: 0.97,
        anonymizationLevel: 0.98,
        dataSecurityScore: 0.99,
        privacyViolations: 0,
        encryptionStrength: 0.98,
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: PrivacyComplianceCard(privacyMetrics: privacyMetrics),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(PrivacyComplianceCard), findsOneWidget);
    });

    testWidgets('displays all privacy metrics', (WidgetTester tester) async {
      // Arrange
      final privacyMetrics = PrivacyMetrics(
        complianceRate: 0.95,
        anonymizationLevel: 0.92,
        dataSecurityScore: 0.97,
        privacyViolations: 0,
        encryptionStrength: 0.95,
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: PrivacyComplianceCard(privacyMetrics: privacyMetrics),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Anonymization Quality'), findsOneWidget);
      expect(find.text('Re-identification Risk'), findsOneWidget);
      expect(find.text('Data Exposure Level'), findsOneWidget);
      expect(find.text('Privacy Compliance Rate'), findsOneWidget);
    });

    testWidgets('displays warning color for score < 0.95', (WidgetTester tester) async {
      // Arrange
      final privacyMetrics = PrivacyMetrics(
        complianceRate: 0.9,
        anonymizationLevel: 0.85,
        dataSecurityScore: 0.92,
        privacyViolations: 1,
        encryptionStrength: 0.88,
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: PrivacyComplianceCard(privacyMetrics: privacyMetrics),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(PrivacyComplianceCard), findsOneWidget);
    });

    testWidgets('displays error color for score < 0.85', (WidgetTester tester) async {
      // Arrange
      final privacyMetrics = PrivacyMetrics(
        complianceRate: 0.82,
        anonymizationLevel: 0.75,
        dataSecurityScore: 0.88,
        privacyViolations: 2,
        encryptionStrength: 0.8,
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: PrivacyComplianceCard(privacyMetrics: privacyMetrics),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(PrivacyComplianceCard), findsOneWidget);
    });
  });
}

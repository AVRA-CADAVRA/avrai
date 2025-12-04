import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/expertise/expertise_recognition_widget.dart';
import 'package:spots/core/models/unified_user.dart';
import "../../helpers/widget_test_helpers.dart';

/// Widget tests for ExpertiseRecognitionWidget
/// Tests expertise recognition display
void main() {
  group('ExpertiseRecognitionWidget Widget Tests', () {
    testWidgets('displays loading state initially', (WidgetTester tester) async {
      // Arrange
      final expert = WidgetTestHelpers.createTestUser();

      final widget = WidgetTestHelpers.createTestableWidget(
        child: ExpertiseRecognitionWidget(expert: expert),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump(); // Don't settle, check loading state

      // Assert - Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays recognition header', (WidgetTester tester) async {
      // Arrange
      final expert = WidgetTestHelpers.createTestUser();

      final widget = WidgetTestHelpers.createTestableWidget(
        child: ExpertiseRecognitionWidget(expert: expert),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Community Recognition'), findsOneWidget);
    });

    testWidgets('displays recognize button when callback provided', (WidgetTester tester) async {
      // Arrange
      final expert = WidgetTestHelpers.createTestUser();

      final widget = WidgetTestHelpers.createTestableWidget(
        child: ExpertiseRecognitionWidget(
          expert: expert,
          onRecognize: (_) {},
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Recognize Expert'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('displays featured expert widget', (WidgetTester tester) async {
      // Arrange
      final expert = WidgetTestHelpers.createTestUser();
      final featuredExpert = FeaturedExpert(
        expert: expert,
        recognitionCount: 10,
        recognitionScore: 0.9,
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: FeaturedExpertWidget(featuredExpert: featuredExpert),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(FeaturedExpertWidget), findsOneWidget);
      expect(find.text('Featured Expert'), findsOneWidget);
      expect(find.text('10 recognitions'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });
}


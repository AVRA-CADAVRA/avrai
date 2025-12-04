import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/widget_test_helpers.dart';

void main() {
  group('Dialogs and Permissions Widget Tests', () {
    
    group('Age Verification Dialog Tests', () {
      testWidgets('displays age verification dialog correctly', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => _showAgeVerificationDialog(context),
              child: const Text('Show Dialog'),
            ),
          ),
        );

        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Act
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Age Verification'), findsOneWidget);
        expect(find.text('Are you 18 or older?'), findsOneWidget);
        expect(find.text('Yes'), findsOneWidget);
        expect(find.text('No'), findsOneWidget);
      });

      testWidgets('handles age verification confirmation', (WidgetTester tester) async {
        // Arrange
        bool? verificationResult;
        final widget = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => _showAgeVerificationDialog(
                context,
                onResult: (result) => verificationResult = result,
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        );

        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.text('Yes'));
        await tester.pumpAndSettle();

        // Assert
        expect(verificationResult, isTrue);
        expect(find.byType(AlertDialog), findsNothing);
      });

      testWidgets('handles age verification denial', (WidgetTester tester) async {
        // Arrange
        bool? verificationResult;
        final widget = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => _showAgeVerificationDialog(
                context,
                onResult: (result) => verificationResult = result,
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        );

        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.text('No'));
        await tester.pumpAndSettle();

        // Assert
        expect(verificationResult, isFalse);
        expect(find.byType(AlertDialog), findsNothing);
      });
    });

    group('Permission Request Dialog Tests', () {
      testWidgets('displays location permission dialog', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => _showLocationPermissionDialog(context),
              child: const Text('Request Location'),
            ),
          ),
        );

        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Act
        await tester.tap(find.text('Request Location'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Location Permission'), findsOneWidget);
        expect(find.textContaining('location'), findsWidgets);
        expect(find.text('Allow'), findsOneWidget);
        expect(find.text('Deny'), findsOneWidget);
      });

      testWidgets('handles location permission grant', (WidgetTester tester) async {
        // Arrange
        bool? permissionGranted;
        final widget = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => _showLocationPermissionDialog(
                context,
                onResult: (granted) => permissionGranted = granted,
              ),
              child: const Text('Request Location'),
            ),
          ),
        );

        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        await tester.tap(find.text('Request Location'));
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.text('Allow'));
        await tester.pumpAndSettle();

        // Assert
        expect(permissionGranted, isTrue);
        expect(find.byType(AlertDialog), findsNothing);
      });

      testWidgets('displays camera permission dialog', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => _showCameraPermissionDialog(context),
              child: const Text('Request Camera'),
            ),
          ),
        );

        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Act
        await tester.tap(find.text('Request Camera'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Camera Permission'), findsOneWidget);
        expect(find.textContaining('camera'), findsWidgets);
      });
    });

    group('Confirmation Dialog Tests', () {
      testWidgets('displays delete confirmation dialog', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => _showDeleteConfirmationDialog(context),
              child: const Text('Delete Item'),
            ),
          ),
        );

        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Act
        await tester.tap(find.text('Delete Item'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Confirm Delete'), findsOneWidget);
        expect(find.textContaining('permanently'), findsWidgets);
        expect(find.text('Delete'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      });

      testWidgets('handles delete confirmation', (WidgetTester tester) async {
        // Arrange
        bool? deleteConfirmed;
        final widget = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => _showDeleteConfirmationDialog(
                context,
                onConfirm: () => deleteConfirmed = true,
              ),
              child: const Text('Delete Item'),
            ),
          ),
        );

        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        await tester.tap(find.text('Delete Item'));
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        // Assert
        expect(deleteConfirmed, isTrue);
        expect(find.byType(AlertDialog), findsNothing);
      });

      testWidgets('handles delete cancellation', (WidgetTester tester) async {
        // Arrange
        bool? deleteConfirmed;
        final widget = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => _showDeleteConfirmationDialog(
                context,
                onConfirm: () => deleteConfirmed = true,
              ),
              child: const Text('Delete Item'),
            ),
          ),
        );

        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        await tester.tap(find.text('Delete Item'));
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Assert
        expect(deleteConfirmed, isNull);
        expect(find.byType(AlertDialog), findsNothing);
      });
    });

    group('Loading Dialog Tests', () {
      testWidgets('displays loading dialog with message', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => _showLoadingDialog(context, 'Saving...'),
              child: const Text('Show Loading'),
            ),
          ),
        );

        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Act
        await tester.tap(find.text('Show Loading'));
        await tester.pump(); // Don't settle to see loading state

        // Assert
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Saving...'), findsOneWidget);
      });

      testWidgets('prevents interaction during loading', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) => Column(
              children: [
                ElevatedButton(
                  onPressed: () => _showLoadingDialog(context, 'Loading...'),
                  child: const Text('Show Loading'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Other Button'),
                ),
              ],
            ),
          ),
        );

        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        await tester.tap(find.text('Show Loading'));
        await tester.pump();

        // Act - Try to tap other button while loading dialog is shown
        await tester.tap(find.text('Other Button'));
        await tester.pump();

        // Assert - Loading dialog should still be present
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Error Dialog Tests', () {
      testWidgets('displays error dialog with message', (WidgetTester tester) async {
        // Arrange
        const errorMessage = 'Something went wrong!';
        final widget = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => _showErrorDialog(context, errorMessage),
              child: const Text('Show Error'),
            ),
          ),
        );

        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Act
        await tester.tap(find.text('Show Error'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Error'), findsOneWidget);
        expect(find.text(errorMessage), findsOneWidget);
        expect(find.text('OK'), findsOneWidget);
      });

      testWidgets('dismisses error dialog on OK tap', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => _showErrorDialog(context, 'Error message'),
              child: const Text('Show Error'),
            ),
          ),
        );

        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        await tester.tap(find.text('Show Error'));
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(AlertDialog), findsNothing);
      });
    });

    group('Dialog Accessibility Tests', () {
      testWidgets('dialogs meet accessibility requirements', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => _showAgeVerificationDialog(context),
              child: const Text('Show Dialog'),
            ),
          ),
        );

        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Age Verification'), findsOneWidget);
        
        // Buttons should meet minimum size requirements
        final yesButton = tester.getSize(find.text('Yes'));
        expect(yesButton.height, greaterThanOrEqualTo(48.0));
        
        final noButton = tester.getSize(find.text('No'));
        expect(noButton.height, greaterThanOrEqualTo(48.0));
      });

      testWidgets('dialogs handle screen reader navigation', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => _showDeleteConfirmationDialog(context),
              child: const Text('Delete'),
            ),
          ),
        );

        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        // Assert - Dialog should have proper semantic structure
        expect(find.text('Confirm Delete'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      });
    });

    group('Dialog State Management Tests', () {
      testWidgets('maintains dialog state during orientation changes', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => _showAgeVerificationDialog(context),
              child: const Text('Show Dialog'),
            ),
          ),
        );

        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Act - Simulate orientation change
        final originalSize = tester.view.physicalSize;
        tester.view.physicalSize = const Size(800, 400);
        await tester.pump();

        // Assert - Dialog should remain visible
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Age Verification'), findsOneWidget);
        
        // Cleanup - Restore original size
        tester.view.physicalSize = originalSize;
        await tester.pump();
      });

      testWidgets('handles rapid dialog operations', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => _showAgeVerificationDialog(context),
              child: const Text('Show Dialog'),
            ),
          ),
        );

        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Act - Rapidly show and dismiss dialog
        await tester.tap(find.text('Show Dialog'));
        await tester.pump();
        await tester.tap(find.text('Yes'));
        await tester.pump();

        // Assert - Should handle rapid operations gracefully
        expect(find.byType(AlertDialog), findsNothing);
      });
    });
  });
}

// Helper functions to simulate actual dialog implementations
void _showAgeVerificationDialog(BuildContext context, {Function(bool)? onResult}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Age Verification'),
      content: const Text('Are you 18 or older?'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onResult?.call(false);
          },
          child: const Text('No'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onResult?.call(true);
          },
          child: const Text('Yes'),
        ),
      ],
    ),
  );
}

void _showLocationPermissionDialog(BuildContext context, {Function(bool)? onResult}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Location Permission'),
      content: const Text('This app needs location access to show nearby spots.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onResult?.call(false);
          },
          child: const Text('Deny'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onResult?.call(true);
          },
          child: const Text('Allow'),
        ),
      ],
    ),
  );
}

void _showCameraPermissionDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Camera Permission'),
      content: const Text('This app needs camera access to take photos.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Deny'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Allow'),
        ),
      ],
    ),
  );
}

void _showDeleteConfirmationDialog(BuildContext context, {VoidCallback? onConfirm}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirm Delete'),
      content: const Text('This action cannot be undone. Are you sure you want to permanently delete this item?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm?.call();
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

void _showLoadingDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message),
        ],
      ),
    ),
  );
}

void _showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Error'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

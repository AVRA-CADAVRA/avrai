// Scan Friend QR Page Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/presentation/pages/social/scan_friend_qr_page.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import '../../../widget/mocks/mock_blocs.dart';

void main() {
  group('ScanFriendQRPage', () {
    testWidgets('should display scanner view initially', (tester) async {
      final mockAuthBloc = MockBlocFactory.createAuthenticatedAuthBloc();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: const ScanFriendQRPage(),
          ),
        ),
      );

      // Should show scanner (MobileScanner widget)
      // Note: MobileScanner may not render in test environment
      expect(find.text('Scan Friend QR Code'), findsOneWidget);
    });

    // Note: Full widget tests would require mocking MobileScanner
    // and testing QR code parsing, but basic structure test is provided
  });
}

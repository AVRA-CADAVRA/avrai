// Add Friend QR Page Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/presentation/pages/social/add_friend_qr_page.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import '../../../widget/mocks/mock_blocs.dart';

void main() {
  group('AddFriendQRPage', () {
    testWidgets('should display loading indicator initially', (tester) async {
      final mockAuthBloc = MockBlocFactory.createAuthenticatedAuthBloc();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: const AddFriendQRPage(),
          ),
        ),
      );

      // Should show loading initially while fetching agentId
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // Note: Full widget tests would require mocking AgentIdService
    // and testing QR code display, but basic structure test is provided
  });
}

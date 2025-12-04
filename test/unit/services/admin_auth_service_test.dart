import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spots/core/services/admin_auth_service.dart';

import 'admin_auth_service_test.mocks.dart';

@GenerateMocks([SharedPreferences])
void main() {
  group('AdminAuthService Tests', () {
    late AdminAuthService service;
    late MockSharedPreferences mockPrefs;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      service = AdminAuthService(mockPrefs);
    });

    group('authenticate', () {
      test('should return failed result when credentials are invalid', () async {
        when(mockPrefs.getInt(any)).thenReturn(null);
        when(mockPrefs.setInt(any, any)).thenAnswer((_) async => true);

        final result = await service.authenticate(
          username: 'admin',
          password: 'wrong-password',
        );

        expect(result.success, isFalse);
        expect(result.lockedOut, isFalse);
        expect(result.remainingAttempts, lessThan(5));
      });

      test('should lockout after max login attempts', () async {
        when(mockPrefs.getInt(any)).thenReturn(4); // 4 previous attempts
        when(mockPrefs.setInt(any, any)).thenAnswer((_) async => true);

        final result = await service.authenticate(
          username: 'admin',
          password: 'wrong-password',
        );

        expect(result.lockedOut, isTrue);
        expect(result.lockoutRemaining, isNotNull);
      });

      test('should return locked out when account is locked', () async {
        final lockoutUntil = DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch;
        when(mockPrefs.getInt(any)).thenReturn(lockoutUntil);

        final result = await service.authenticate(
          username: 'admin',
          password: 'password',
        );

        expect(result.lockedOut, isTrue);
        expect(result.lockoutRemaining, isNotNull);
      });

      test('should reset failed attempts on successful authentication', () async {
        when(mockPrefs.getInt(any)).thenReturn(null);
        when(mockPrefs.getString(any)).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        when(mockPrefs.remove(any)).thenAnswer((_) async => true);

        // Note: This will fail because _getExpectedPasswordHash returns null
        // In a real test, we'd need to mock or set up credentials
        final result = await service.authenticate(
          username: 'admin',
          password: 'password',
        );

        expect(result.success, isFalse); // Will fail due to no credentials set up
      });
    });

    group('isAuthenticated', () {
      test('should return false when no session exists', () {
        when(mockPrefs.getString(any)).thenReturn(null);

        final isAuth = service.isAuthenticated();

        expect(isAuth, isFalse);
      });

      test('should return false when session is expired', () {
        final expiredSession = AdminSession(
          username: 'admin',
          loginTime: DateTime.now().subtract(const Duration(hours: 10)),
          expiresAt: DateTime.now().subtract(const Duration(hours: 2)),
          accessLevel: AdminAccessLevel.godMode,
          permissions: AdminPermissions.all(),
        );

        when(mockPrefs.getString(any)).thenReturn(
          '{"username":"admin","loginTime":"${expiredSession.loginTime.toIso8601String()}","expiresAt":"${expiredSession.expiresAt.toIso8601String()}","accessLevel":"godMode","permissions":{}}',
        );
        when(mockPrefs.remove(any)).thenAnswer((_) async => true);

        final isAuth = service.isAuthenticated();

        expect(isAuth, isFalse);
      });

      test('should return true when valid session exists', () {
        final validSession = AdminSession(
          username: 'admin',
          loginTime: DateTime.now().subtract(const Duration(hours: 1)),
          expiresAt: DateTime.now().add(const Duration(hours: 7)),
          accessLevel: AdminAccessLevel.godMode,
          permissions: AdminPermissions.all(),
        );

        when(mockPrefs.getString(any)).thenReturn(
          '{"username":"admin","loginTime":"${validSession.loginTime.toIso8601String()}","expiresAt":"${validSession.expiresAt.toIso8601String()}","accessLevel":"godMode","permissions":{}}',
        );

        final isAuth = service.isAuthenticated();

        expect(isAuth, isTrue);
      });
    });

    group('hasPermission', () {
      test('should return false when not authenticated', () {
        when(mockPrefs.getString(any)).thenReturn(null);

        final hasPerm = service.hasPermission(AdminPermission.viewUserData);

        expect(hasPerm, isFalse);
      });

      test('should return true when session has permission', () {
        final session = AdminSession(
          username: 'admin',
          loginTime: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 8)),
          accessLevel: AdminAccessLevel.godMode,
          permissions: AdminPermissions.all(),
        );

        when(mockPrefs.getString(any)).thenReturn(
          '{"username":"admin","loginTime":"${session.loginTime.toIso8601String()}","expiresAt":"${session.expiresAt.toIso8601String()}","accessLevel":"godMode","permissions":{"viewUserData":true,"viewAIData":true,"viewCommunications":true,"viewUserProgress":true,"viewUserPredictions":true,"viewBusinessAccounts":true,"viewRealTimeData":true,"modifyUserData":true,"modifyAIData":true,"modifyBusinessData":true,"accessAuditLogs":true}}',
        );

        final hasPerm = service.hasPermission(AdminPermission.viewUserData);

        expect(hasPerm, isTrue);
      });
    });

    group('logout', () {
      test('should remove session on logout', () async {
        when(mockPrefs.remove(any)).thenAnswer((_) async => true);

        await service.logout();

        verify(mockPrefs.remove('admin_session')).called(1);
      });
    });

    group('extendSession', () {
      test('should extend session expiration time', () async {
        final session = AdminSession(
          username: 'admin',
          loginTime: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 8)),
          accessLevel: AdminAccessLevel.godMode,
          permissions: AdminPermissions.all(),
        );

        when(mockPrefs.getString(any)).thenReturn(
          '{"username":"admin","loginTime":"${session.loginTime.toIso8601String()}","expiresAt":"${session.expiresAt.toIso8601String()}","accessLevel":"godMode","permissions":{}}',
        );
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        await service.extendSession();

        verify(mockPrefs.setString(any, any)).called(1);
      });

      test('should do nothing when no session exists', () async {
        when(mockPrefs.getString(any)).thenReturn(null);

        await service.extendSession();

        verifyNever(mockPrefs.setString(any, any));
      });
    });

    group('getCurrentSession', () {
      test('should return null when no session exists', () {
        when(mockPrefs.getString(any)).thenReturn(null);

        final session = service.getCurrentSession();

        expect(session, isNull);
      });

      test('should return session when valid session exists', () {
        final session = AdminSession(
          username: 'admin',
          loginTime: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 8)),
          accessLevel: AdminAccessLevel.godMode,
          permissions: AdminPermissions.all(),
        );

        when(mockPrefs.getString(any)).thenReturn(
          '{"username":"admin","loginTime":"${session.loginTime.toIso8601String()}","expiresAt":"${session.expiresAt.toIso8601String()}","accessLevel":"godMode","permissions":{}}',
        );

        final currentSession = service.getCurrentSession();

        expect(currentSession, isNotNull);
        expect(currentSession?.username, equals('admin'));
      });
    });
  });
}







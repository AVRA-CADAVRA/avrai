import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:spots/core/services/role_management_service.dart';
import 'package:spots/core/models/user_role.dart';
import 'package:shared_preferences/shared_preferences.dart' as real_prefs;
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks/mock_dependencies.mocks.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/platform_channel_helper.dart';

void main() {
  group('RoleManagementService Tests', () {
    late RoleManagementServiceImpl service;
    late MockStorageService mockStorageService;
    late SharedPreferences prefs;

    setUpAll(() async {
      await setupTestStorage();
      real_prefs.SharedPreferences.setMockInitialValues({});
    });

    setUp(() async {
      mockStorageService = MockStorageService();
      prefs = await real_prefs.SharedPreferences.getInstance();

      service = RoleManagementServiceImpl(
        storageService: mockStorageService,
        prefs: prefs,
      );
    });

    tearDown(() async {
      await prefs.clear();
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });

    group('assignRole', () {
      test('assigns role successfully when grantor has permission', () async {
        // Arrange: Grantor is curator
        when(mockStorageService.getObject<List<dynamic>>(
          any,
          box: anyNamed('box'),
        )).thenReturn([]);
        when(mockStorageService.setObject(
          any,
          any,
          box: anyNamed('box'),
        )).thenAnswer((_) async => true);

        // First assign curator role to grantor
        final grantorAssignment = UserRoleAssignment(
          id: 'grantor_role',
          userId: 'grantor_id',
          listId: 'test_list',
          role: UserRole.curator,
          grantedAt: DateTime.now(),
          grantedBy: 'system',
        );

        when(mockStorageService.getObject<List<dynamic>>(
          any,
          box: anyNamed('box'),
        )).thenReturn([grantorAssignment.toJson()]);

        // Act
        final assignment = await service.assignRole(
          userId: 'user_id',
          listId: 'test_list',
          role: UserRole.collaborator,
          grantedBy: 'grantor_id',
        );

        // Assert
        expect(assignment.userId, equals('user_id'));
        expect(assignment.listId, equals('test_list'));
        expect(assignment.role, equals(UserRole.collaborator));
        expect(assignment.isActive, isTrue);
      });

      test('throws exception when grantor lacks permission', () async {
        // Arrange: Grantor is follower (no permission)
        when(mockStorageService.getObject<List<dynamic>>(
          any,
          box: anyNamed('box'),
        )).thenReturn([]);

        // Act & Assert
        expect(
          () => service.assignRole(
            userId: 'user_id',
            listId: 'test_list',
            role: UserRole.collaborator,
            grantedBy: 'grantor_id',
          ),
          throwsA(isA<RoleManagementException>()),
        );
      });
    });

    group('getUserRoleForList', () {
      test('returns role when user has active assignment', () async {
        // Arrange
        final assignment = UserRoleAssignment(
          id: 'test_assignment',
          userId: 'user_id',
          listId: 'test_list',
          role: UserRole.collaborator,
          grantedAt: DateTime.now(),
          grantedBy: 'curator_id',
        );

        when(mockStorageService.getObject<List<dynamic>>(
          any,
          box: anyNamed('box'),
        )).thenReturn([assignment.toJson()]);

        // Act
        final role = await service.getUserRoleForList('user_id', 'test_list');

        // Assert
        expect(role, equals(UserRole.collaborator));
      });

      test('returns null when user has no role', () async {
        // Arrange
        when(mockStorageService.getObject<List<dynamic>>(
          any,
          box: anyNamed('box'),
        )).thenReturn([]);

        // Act
        final role = await service.getUserRoleForList('user_id', 'test_list');

        // Assert
        expect(role, isNull);
      });
    });

    group('hasPermission', () {
      test('returns true for curator managing roles', () async {
        // Arrange
        final assignment = UserRoleAssignment(
          id: 'test_assignment',
          userId: 'user_id',
          listId: 'test_list',
          role: UserRole.curator,
          grantedAt: DateTime.now(),
          grantedBy: 'system',
        );

        when(mockStorageService.getObject<List<dynamic>>(
          any,
          box: anyNamed('box'),
        )).thenReturn([assignment.toJson()]);

        // Act
        final hasPermission = await service.hasPermission(
          userId: 'user_id',
          listId: 'test_list',
          permission: UserPermission.manageRoles,
        );

        // Assert
        expect(hasPermission, isTrue);
      });

      test('returns false for follower managing roles', () async {
        // Arrange
        final assignment = UserRoleAssignment(
          id: 'test_assignment',
          userId: 'user_id',
          listId: 'test_list',
          role: UserRole.follower,
          grantedAt: DateTime.now(),
          grantedBy: 'curator_id',
        );

        when(mockStorageService.getObject<List<dynamic>>(
          any,
          box: anyNamed('box'),
        )).thenReturn([assignment.toJson()]);

        // Act
        final hasPermission = await service.hasPermission(
          userId: 'user_id',
          listId: 'test_list',
          permission: UserPermission.manageRoles,
        );

        // Assert
        expect(hasPermission, isFalse);
      });
    });
  });
}

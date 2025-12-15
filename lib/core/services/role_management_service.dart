import 'dart:developer' as developer;
import 'package:spots/core/models/user_role.dart';
import 'package:spots/core/services/storage_service.dart' show SharedPreferencesCompat, StorageService;

/// OUR_GUTS.md: "Community, Not Just Places" - Role-based community management
/// Concrete implementation of RoleManagementService for managing user roles in lists
class RoleManagementServiceImpl implements RoleManagementService {
  static const String _logName = 'RoleManagementService';
  
  // Storage keys
  static const String _roleAssignmentsKey = 'user_role_assignments';
  
  final StorageService _storageService;
  final SharedPreferencesCompat _prefs;
  
  // In-memory cache for role assignments
  final Map<String, List<UserRoleAssignment>> _roleCache = {};
  
  RoleManagementServiceImpl({
    required StorageService storageService,
    required SharedPreferencesCompat prefs,
  }) : _storageService = storageService,
       _prefs = prefs;
  
  /// Assign a role to a user for a specific list
  @override
  Future<UserRoleAssignment> assignRole({
    required String userId,
    required String listId,
    required UserRole role,
    required String grantedBy,
    String? reason,
  }) async {
    try {
      developer.log('Assigning role ${role.name} to user $userId for list $listId', name: _logName);
      
      // Check if grantor has permission to assign this role
      final grantorRole = await getUserRoleForList(grantedBy, listId);
      if (grantorRole == null || !grantorRole.canManageRoles) {
        throw RoleManagementException(
          'User $grantedBy does not have permission to assign roles for list $listId',
        );
      }
      
      // Revoke any existing active role for this user/list combination
      final existingRole = await getUserRoleForList(userId, listId);
      if (existingRole != null) {
        await revokeRole(
          userId: userId,
          listId: listId,
          revokedBy: grantedBy,
          reason: 'Replaced with ${role.name} role',
        );
      }
      
      // Create new role assignment
      final assignment = UserRoleAssignment(
        id: 'role_${DateTime.now().millisecondsSinceEpoch}_${userId}_$listId',
        userId: userId,
        listId: listId,
        role: role,
        grantedAt: DateTime.now(),
        grantedBy: grantedBy,
        reason: reason,
      );
      
      // Save to storage
      await _saveRoleAssignment(assignment);
      
      // Update cache
      _updateCache(assignment);
      
      developer.log('Role ${role.name} assigned successfully', name: _logName);
      return assignment;
    } catch (e) {
      developer.log('Error assigning role: $e', name: _logName);
      rethrow;
    }
  }
  
  /// Revoke a role from a user
  @override
  Future<UserRoleAssignment> revokeRole({
    required String userId,
    required String listId,
    required String revokedBy,
    String? reason,
  }) async {
    try {
      developer.log('Revoking role for user $userId from list $listId', name: _logName);
      
      // Get current role assignment
      final assignments = await getListRoles(listId);
      final activeAssignment = assignments
          .where((a) => a.userId == userId && a.isActive)
          .firstOrNull;
      
      if (activeAssignment == null) {
        throw RoleManagementException(
          'No active role found for user $userId in list $listId',
        );
      }
      
      // Check if revoker has permission
      final revokerRole = await getUserRoleForList(revokedBy, listId);
      if (revokerRole == null || !revokerRole.canManageRoles) {
        throw RoleManagementException(
          'User $revokedBy does not have permission to revoke roles for list $listId',
        );
      }
      
      // Create revoked assignment
      final revokedAssignment = activeAssignment.copyWith(
        revokedAt: DateTime.now(),
        revokedBy: revokedBy,
        reason: reason,
      );
      
      // Save to storage
      await _saveRoleAssignment(revokedAssignment);
      
      // Update cache
      _updateCache(revokedAssignment);
      
      developer.log('Role revoked successfully', name: _logName);
      return revokedAssignment;
    } catch (e) {
      developer.log('Error revoking role: $e', name: _logName);
      rethrow;
    }
  }
  
  /// Get all role assignments for a user
  @override
  Future<List<UserRoleAssignment>> getUserRoles(String userId) async {
    try {
      // Check cache first
      final cacheKey = 'user_$userId';
      if (_roleCache.containsKey(cacheKey)) {
        return _roleCache[cacheKey]!.where((a) => a.isActive).toList();
      }
      
      // Load from storage
      final allAssignments = await _loadAllRoleAssignments();
      final userAssignments = allAssignments
          .where((a) => a.userId == userId && a.isActive)
          .toList();
      
      // Update cache
      _roleCache[cacheKey] = userAssignments;
      
      return userAssignments;
    } catch (e) {
      developer.log('Error getting user roles: $e', name: _logName);
      return [];
    }
  }
  
  /// Get all role assignments for a list
  @override
  Future<List<UserRoleAssignment>> getListRoles(String listId) async {
    try {
      // Check cache first
      final cacheKey = 'list_$listId';
      if (_roleCache.containsKey(cacheKey)) {
        return _roleCache[cacheKey]!.where((a) => a.isActive).toList();
      }
      
      // Load from storage
      final allAssignments = await _loadAllRoleAssignments();
      final listAssignments = allAssignments
          .where((a) => a.listId == listId && a.isActive)
          .toList();
      
      // Update cache
      _roleCache[cacheKey] = listAssignments;
      
      return listAssignments;
    } catch (e) {
      developer.log('Error getting list roles: $e', name: _logName);
      return [];
    }
  }
  
  /// Get the current role of a user for a specific list
  @override
  Future<UserRole?> getUserRoleForList(String userId, String listId) async {
    try {
      final assignments = await getListRoles(listId);
      final userAssignment = assignments
          .where((a) => a.userId == userId && a.isActive)
          .firstOrNull;
      
      return userAssignment?.role;
    } catch (e) {
      developer.log('Error getting user role for list: $e', name: _logName);
      return null;
    }
  }
  
  /// Check if a user has a specific permission for a list
  @override
  Future<bool> hasPermission({
    required String userId,
    required String listId,
    required UserPermission permission,
  }) async {
    try {
      final role = await getUserRoleForList(userId, listId);
      if (role == null) {
        // Default follower permissions
        return permission == UserPermission.viewList || 
               permission == UserPermission.respectList ||
               permission == UserPermission.reportList;
      }
      
      // Check permission based on role
      switch (permission) {
        case UserPermission.viewList:
          return true; // All roles can view
        
        case UserPermission.editListContent:
          return role.canEditContent;
        
        case UserPermission.deleteList:
          return role.canDeleteLists;
        
        case UserPermission.manageRoles:
          return role.canManageRoles;
        
        case UserPermission.createAgeRestrictedContent:
          return role.canCreateAgeRestrictedContent;
        
        case UserPermission.reportList:
          return true; // All roles can report
        
        case UserPermission.respectList:
          return true; // All roles can respect
      }
    } catch (e) {
      developer.log('Error checking permission: $e', name: _logName);
      return false;
    }
  }
  
  /// Get all users with a specific role for a list
  @override
  Future<List<String>> getUsersWithRole(String listId, UserRole role) async {
    try {
      final assignments = await getListRoles(listId);
      return assignments
          .where((a) => a.role == role && a.isActive)
          .map((a) => a.userId)
          .toList();
    } catch (e) {
      developer.log('Error getting users with role: $e', name: _logName);
      return [];
    }
  }
  
  /// Transfer list ownership to another user
  @override
  Future<void> transferOwnership({
    required String listId,
    required String newCuratorId,
    required String transferredBy,
  }) async {
    try {
      developer.log('Transferring ownership of list $listId to $newCuratorId', name: _logName);
      
      // Check if transferrer has permission (must be current curator)
      final transferrerRole = await getUserRoleForList(transferredBy, listId);
      if (transferrerRole != UserRole.curator) {
        throw RoleManagementException(
          'Only the current curator can transfer ownership',
        );
      }
      
      // Revoke curator role from transferrer
      await revokeRole(
        userId: transferredBy,
        listId: listId,
        revokedBy: transferredBy,
        reason: 'Ownership transferred to $newCuratorId',
      );
      
      // Assign curator role to new owner
      await assignRole(
        userId: newCuratorId,
        listId: listId,
        role: UserRole.curator,
        grantedBy: transferredBy,
        reason: 'Ownership transferred from $transferredBy',
      );
      
      developer.log('Ownership transferred successfully', name: _logName);
    } catch (e) {
      developer.log('Error transferring ownership: $e', name: _logName);
      rethrow;
    }
  }
  
  // Private helper methods
  
  /// Save role assignment to storage
  Future<void> _saveRoleAssignment(UserRoleAssignment assignment) async {
    try {
      final allAssignments = await _loadAllRoleAssignments();
      
      // Remove existing assignment with same ID if exists
      allAssignments.removeWhere((a) => a.id == assignment.id);
      
      // Add new assignment
      allAssignments.add(assignment);
      
      // Save to storage using setObject
      final assignmentsJson = allAssignments.map((a) => a.toJson()).toList();
      await _storageService.setObject(
        _roleAssignmentsKey,
        assignmentsJson,
        box: 'spots_user',
      );
      
      // Clear relevant caches
      _roleCache.remove('user_${assignment.userId}');
      _roleCache.remove('list_${assignment.listId}');
    } catch (e) {
      developer.log('Error saving role assignment: $e', name: _logName);
      rethrow;
    }
  }
  
  /// Load all role assignments from storage
  Future<List<UserRoleAssignment>> _loadAllRoleAssignments() async {
    try {
      final data = _storageService.getObject<List<dynamic>>(
        _roleAssignmentsKey,
        box: 'spots_user',
      );
      
      if (data == null || data.isEmpty) {
        return [];
      }
      
      return data
          .map((json) => UserRoleAssignment.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      developer.log('Error loading role assignments: $e', name: _logName);
      return [];
    }
  }
  
  /// Update in-memory cache
  void _updateCache(UserRoleAssignment assignment) {
    // Update user cache
    final userKey = 'user_${assignment.userId}';
    final userAssignments = _roleCache[userKey] ?? <UserRoleAssignment>[];
    userAssignments.removeWhere((a) => a.id == assignment.id);
    if (assignment.isActive) {
      userAssignments.add(assignment);
    }
    _roleCache[userKey] = userAssignments;
    
    // Update list cache
    final listKey = 'list_${assignment.listId}';
    final listAssignments = _roleCache[listKey] ?? <UserRoleAssignment>[];
    listAssignments.removeWhere((a) => a.id == assignment.id);
    if (assignment.isActive) {
      listAssignments.add(assignment);
    }
    _roleCache[listKey] = listAssignments;
  }
}

/// Exception for role management errors
class RoleManagementException implements Exception {
  final String message;
  
  RoleManagementException(this.message);
  
  @override
  String toString() => 'RoleManagementException: $message';
}

/// Extension to get first element or null
extension FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}


import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'dart:async';
import '../../interfaces/backend_interface.dart';
import '../../interfaces/auth_backend.dart';
import '../../interfaces/data_backend.dart';
import '../../interfaces/realtime_backend.dart';
import 'package:spots_core/spots_core.dart';
import '../../models/api_response.dart';

/// Simplified Supabase backend implementation
/// Focuses on core functionality that works with the current interfaces
class SupabaseBackendSimple implements BackendInterface {
  late final SupabaseAuthBackendSimple _authBackend;
  late final SupabaseDataBackendSimple _dataBackend;
  late final SupabaseRealtimeBackendSimple _realtimeBackend;
  
  supa.SupabaseClient? _client;
  Map<String, dynamic> _config = {};
  bool _isInitialized = false;
  
  @override
  AuthBackend get auth => _authBackend;
  
  @override
  DataBackend get data => _dataBackend;
  
  @override
  RealtimeBackend get realtime => _realtimeBackend;
  
  @override
  bool get isInitialized => _isInitialized;
  
  @override
  String get backendType => 'supabase';
  
  @override
  Map<String, dynamic> get config => Map.unmodifiable(_config);
  
  @override
  BackendCapabilities get capabilities => BackendCapabilities.supabase;
  
  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    try {
      _config = Map.unmodifiable(config);
      
      // Initialize Supabase client
      final url = config['url'] as String?;
      final anonKey = config['anonKey'] as String?;
      
      if (url == null || anonKey == null) {
        throw ArgumentError('Supabase URL and anon key are required');
      }
      
      // Initialize Supabase Flutter
      await supa.Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: false,
      );
      
      _client = supa.Supabase.instance.client;
      
      // Initialize component backends
      _authBackend = SupabaseAuthBackendSimple(_client!);
      _dataBackend = SupabaseDataBackendSimple(_client!);
      _realtimeBackend = SupabaseRealtimeBackendSimple(_client!);
      
      // Initialize component backends
      await _authBackend.initialize(config);
      await _dataBackend.initialize(config);
      await _realtimeBackend.initialize(config);
      
      _isInitialized = true;
      
    } catch (e) {
      _isInitialized = false;
      throw BackendInitializationException(
        'Failed to initialize Supabase backend: $e',
      );
    }
  }
  
  @override
  Future<void> dispose() async {
    try {
      // Dispose component backends
      await _authBackend.dispose();
      await _dataBackend.dispose();
      await _realtimeBackend.dispose();
      
      _isInitialized = false;
      _client = null;
      
    } catch (e) {
      print('Warning: Error during Supabase backend disposal: $e');
    }
  }
  
  @override
  Future<bool> healthCheck() async {
    try {
      if (!_isInitialized || _client == null) {
        return false;
      }
      
      // Simple health check - try to get current user
      final user = _client!.auth.currentUser;
      
      return true;
      
    } catch (e) {
      return false;
    }
  }
}

/// Simplified Supabase authentication backend
class SupabaseAuthBackendSimple implements AuthBackend {
  final supa.SupabaseClient _client;
  Map<String, dynamic> _config = {};
  bool _isInitialized = false;
  
  SupabaseAuthBackendSimple(this._client);
  
  @override
  bool get isInitialized => _isInitialized;
  
  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    _config = Map.unmodifiable(config);
    _isInitialized = true;
  }
  
  @override
  Future<void> dispose() async {
    _isInitialized = false;
  }
  
  @override
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        return _convertSupabaseUser(response.user!);
      }
      return null;
      
    } catch (e) {
      print('Sign in failed: $e');
      return null;
    }
  }
  
  @override
  Future<User?> registerWithEmailPassword(
    String email, 
    String password, 
    String name,
  ) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      
      if (response.user != null) {
        return _convertSupabaseUser(response.user!);
      }
      return null;
      
    } catch (e) {
      print('Sign up failed: $e');
      return null;
    }
  }
  
  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      print('Sign out failed: $e');
    }
  }
  
  @override
  Future<User?> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        return _convertSupabaseUser(user);
      }
      return null;
    } catch (e) {
      print('Get current user failed: $e');
      return null;
    }
  }
  
  @override
  Stream<User?> authStateChanges() {
    return _client.auth.onAuthStateChange.map((event) {
      final user = event.session?.user;
      return user != null ? _convertSupabaseUser(user) : null;
    });
  }
  
  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      print('Send password reset failed: $e');
    }
  }
  
  @override
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    try {
      await _client.auth.updateUser(
        supa.UserAttributes(password: newPassword),
      );
    } catch (e) {
      print('Update password failed: $e');
    }
  }
  
  @override
  Future<void> updateEmail(String newEmail) async {
    try {
      await _client.auth.updateUser(
        supa.UserAttributes(email: newEmail),
      );
    } catch (e) {
      print('Update email failed: $e');
    }
  }
  
  @override
  Future<void> deleteAccount() async {
    try {
      // Note: Supabase doesn't have a direct delete account method
      // This would need to be implemented via RPC or edge function
      print('Delete account not implemented yet');
    } catch (e) {
      print('Delete account failed: $e');
    }
  }
  
  @override
  Future<bool> isSignedIn() async {
    try {
      final user = _client.auth.currentUser;
      return user != null;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<void> refreshToken() async {
    try {
      // Supabase handles token refresh automatically
      print('Token refresh handled automatically by Supabase');
    } catch (e) {
      print('Refresh token failed: $e');
    }
  }
  
  @override
  Future<String?> getAuthToken() async {
    try {
      final session = _client.auth.currentSession;
      return session?.accessToken;
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<User?> updateUserProfile(User user) async {
    try {
      final response = await _client.auth.updateUser(
        supa.UserAttributes(
          data: {
            'name': user.name,
            'updated_at': DateTime.now().toIso8601String(),
          },
        ),
      );
      
      if (response.user != null) {
        return _convertSupabaseUser(response.user!);
      }
      return null;
      
    } catch (e) {
      print('Update user profile failed: $e');
      return null;
    }
  }
  
  @override
  Future<void> verifyEmail() async {
    try {
      // Email verification is handled automatically by Supabase
      print('Email verification handled automatically by Supabase');
    } catch (e) {
      print('Verify email failed: $e');
    }
  }
  
  @override
  Future<bool> isEmailVerified() async {
    try {
      final user = _client.auth.currentUser;
      return user?.emailConfirmedAt != null;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<User?> signInWithGoogle() async {
    try {
      // OAuth implementation would go here
      print('Google sign in not implemented yet');
      return null;
    } catch (e) {
      print('Google sign in failed: $e');
      return null;
    }
  }
  
  @override
  Future<User?> signInWithApple() async {
    try {
      // OAuth implementation would go here
      print('Apple sign in not implemented yet');
      return null;
    } catch (e) {
      print('Apple sign in failed: $e');
      return null;
    }
  }
  
  @override
  Future<User?> signInWithFacebook() async {
    try {
      // OAuth implementation would go here
      print('Facebook sign in not implemented yet');
      return null;
    } catch (e) {
      print('Facebook sign in failed: $e');
      return null;
    }
  }
  
  @override
  Future<User?> signInAnonymously() async {
    try {
      final response = await _client.auth.signInAnonymously();
      if (response.user != null) {
        return _convertSupabaseUser(response.user!);
      }
      return null;
    } catch (e) {
      print('Anonymous sign in failed: $e');
      return null;
    }
  }
  
  @override
  Future<void> enableMFA() async {
    try {
      // MFA implementation would go here
      print('MFA not implemented yet');
    } catch (e) {
      print('Enable MFA failed: $e');
    }
  }
  
  @override
  Future<void> disableMFA() async {
    try {
      // MFA implementation would go here
      print('MFA not implemented yet');
    } catch (e) {
      print('Disable MFA failed: $e');
    }
  }
  
  @override
  Future<bool> isMFAEnabled() async {
    try {
      // MFA implementation would go here
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Convert Supabase User to our User model
  User _convertSupabaseUser(supa.User supabaseUser) {
    return User(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
      name: (supabaseUser.userMetadata?['name'] as String?) ?? '',
      displayName: supabaseUser.userMetadata?['displayName'] as String?,
      role: UserRole.follower,
      createdAt: _toDateTime(supabaseUser.createdAt),
      updatedAt: _toDateTime(supabaseUser.updatedAt),
      isOnline: true,
    );
  }

  DateTime _toDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      try { return DateTime.parse(value); } catch (_) {}
    }
    return DateTime.now();
  }
}

/// Simplified Supabase data backend
class SupabaseDataBackendSimple implements DataBackend {
  final supa.SupabaseClient _client;
  Map<String, dynamic> _config = {};
  bool _isInitialized = false;
  
  SupabaseDataBackendSimple(this._client);
  
  @override
  bool get isInitialized => _isInitialized;
  
  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    _config = Map.unmodifiable(config);
    _isInitialized = true;
  }
  
  @override
  Future<void> dispose() async {
    _isInitialized = false;
  }
  
  // Implement basic CRUD operations
  @override
  Future<ApiResponse<User>> createUser(User user) async {
    try {
      final response = await _client
        .from('users')
        .insert(user.toJson())
        .select()
        .single();
      
      return ApiResponse.success(User.fromJson(response));
    } catch (e) {
      return ApiResponse.error('Create user failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<User?>> getUser(String userId) async {
    try {
      final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .single();
      
      return ApiResponse.success(User.fromJson(response));
    } catch (e) {
      return ApiResponse.error('Get user failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<List<User>>> getUsers({int? limit, String? cursor, Map<String, dynamic>? filters}) async {
    try {
      dynamic query = _client.from('users').select();
      
      if (filters != null) {
        for (final entry in filters.entries) {
          query = query.eq(entry.key, entry.value);
        }
      }
      
      final response = await query;
      final users = (response as List).map((json) => User.fromJson(json)).toList();
      
      return ApiResponse.success(users);
    } catch (e) {
      return ApiResponse.error('Get users failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<User>> updateUser(User user) async {
    try {
      final response = await _client
        .from('users')
        .update(user.toJson())
        .eq('id', user.id)
        .select()
        .single();
      
      return ApiResponse.success(User.fromJson(response));
    } catch (e) {
      return ApiResponse.error('Update user failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<void>> deleteUser(String userId) async {
    try {
      await _client
        .from('users')
        .delete()
        .eq('id', userId);
      
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error('Delete user failed: $e');
    }
  }
  
  // Implement other required methods with basic implementations
  @override
  Future<ApiResponse<Spot>> createSpot(Spot spot) async {
    try {
      final row = {
        'id': spot.id,
        'name': spot.name,
        'description': spot.description,
        'latitude': spot.latitude,
        'longitude': spot.longitude,
        'address': spot.address,
        'category': spot.category,
        'tags': spot.tags,
        'created_by': spot.createdBy,
        'created_at': spot.createdAt.toIso8601String(),
        'updated_at': spot.updatedAt.toIso8601String(),
        'view_count': spot.viewCount,
        'respect_count': spot.respectCount,
        'share_count': spot.shareCount,
      };
      // Let DB generate id if invalid/empty
      if ((row['id'] as String?) == null || (row['id'] as String).isEmpty || !_looksLikeUuid(row['id'] as String)) {
        row.remove('id');
      }
      final response = await _client
          .from('spots')
          .insert(row)
          .select()
          .single();
      return ApiResponse.success(_mapRowToSpot(response));
    } catch (e) {
      return ApiResponse.error('Create spot failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<Spot?>> getSpot(String spotId) async {
    try {
      final response = await _client
          .from('spots')
          .select()
          .eq('id', spotId)
          .single();
      return ApiResponse.success(_mapRowToSpot(response));
    } catch (e) {
      return ApiResponse.error('Get spot failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<List<Spot>>> getSpots({int? limit, String? cursor, Map<String, dynamic>? filters}) async {
    try {
      dynamic query = _client.from('spots').select();
      if (filters != null) {
        for (final entry in filters.entries) {
          query = query.eq(entry.key, entry.value);
        }
      }
      if (limit != null) {
        query = query.limit(limit);
      }
      final response = await query;
      final rows = (response as List).cast<Map<String, dynamic>>();
      final spots = rows.map(_mapRowToSpot).toList();
      return ApiResponse.success(spots);
    } catch (e) {
      return ApiResponse.error('Get spots failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<Spot>> updateSpot(Spot spot) async {
    try {
      final row = {
        'name': spot.name,
        'description': spot.description,
        'latitude': spot.latitude,
        'longitude': spot.longitude,
        'address': spot.address,
        'category': spot.category,
        'tags': spot.tags,
        'updated_at': spot.updatedAt.toIso8601String(),
      };
      final response = await _client
          .from('spots')
          .update(row)
          .eq('id', spot.id)
          .select()
          .single();
      return ApiResponse.success(_mapRowToSpot(response));
    } catch (e) {
      return ApiResponse.error('Update spot failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<void>> deleteSpot(String spotId) async {
    try {
      await _client.from('spots').delete().eq('id', spotId);
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error('Delete spot failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<List<Spot>>> searchSpots(String query, {int? limit, Map<String, dynamic>? filters}) async {
    return ApiResponse.error('Not implemented yet');
  }
  
  @override
  Future<ApiResponse<List<Spot>>> getNearbySpots(double latitude, double longitude, double radiusKm, {int? limit}) async {
    return ApiResponse.error('Not implemented yet');
  }
  
  @override
  Future<ApiResponse<SpotList>> createSpotList(SpotList spotList) async {
    try {
      final row = {
        'id': spotList.id,
        'name': spotList.title,
        'description': spotList.description,
        'is_public': spotList.isPublic,
        'created_by': spotList.curatorId,
        'created_at': spotList.createdAt.toIso8601String(),
        'updated_at': spotList.updatedAt.toIso8601String(),
        'view_count': spotList.viewCount,
        'respect_count': spotList.respectCount,
        'share_count': spotList.shareCount,
      };
      // Let DB generate id if invalid/empty
      if ((row['id'] as String?) == null || (row['id'] as String).isEmpty || !_looksLikeUuid(row['id'] as String)) {
        row.remove('id');
      }
      final response = await _client
          .from('spot_lists')
          .insert(row)
          .select()
          .single();
      return ApiResponse.success(_mapRowToSpotList(response));
    } catch (e) {
      return ApiResponse.error('Create spot list failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<SpotList?>> getSpotList(String listId) async {
    try {
      final response = await _client
          .from('spot_lists')
          .select()
          .eq('id', listId)
          .single();
      return ApiResponse.success(_mapRowToSpotList(response));
    } catch (e) {
      return ApiResponse.error('Get spot list failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<List<SpotList>>> getSpotLists({int? limit, String? cursor, Map<String, dynamic>? filters}) async {
    try {
      dynamic query = _client.from('spot_lists').select();
      if (filters != null) {
        for (final entry in filters.entries) {
          query = query.eq(entry.key, entry.value);
        }
      }
      if (limit != null) {
        query = query.limit(limit);
      }
      final response = await query;
      final rows = (response as List).cast<Map<String, dynamic>>();
      final lists = rows.map(_mapRowToSpotList).toList();
      return ApiResponse.success(lists);
    } catch (e) {
      return ApiResponse.error('Get spot lists failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<SpotList>> updateSpotList(SpotList spotList) async {
    return ApiResponse.error('Not implemented yet');
  }
  
  @override
  Future<ApiResponse<void>> deleteSpotList(String listId) async {
    return ApiResponse.error('Not implemented yet');
  }
  
  @override
  Future<ApiResponse<List<SpotList>>> searchSpotLists(String query, {int? limit, Map<String, dynamic>? filters}) async {
    return ApiResponse.error('Not implemented yet');
  }
  
  @override
  Future<ApiResponse<void>> addSpotToList(String spotId, String listId) async {
    return ApiResponse.error('Not implemented yet');
  }
  
  @override
  Future<ApiResponse<void>> removeSpotFromList(String spotId, String listId) async {
    return ApiResponse.error('Not implemented yet');
  }
  
  @override
  Future<ApiResponse<List<Spot>>> getSpotsInList(String listId) async {
    return ApiResponse.error('Not implemented yet');
  }
  
  @override
  Future<ApiResponse<void>> respectSpot(String spotId, String userId) async {
    return ApiResponse.error('Not implemented yet');
  }
  
  @override
  Future<ApiResponse<void>> unrespectSpot(String spotId, String userId) async {
    return ApiResponse.error('Not implemented yet');
  }
  
  @override
  Future<ApiResponse<void>> respectList(String listId, String userId) async {
    return ApiResponse.error('Not implemented yet');
  }
  
  @override
  Future<ApiResponse<void>> unrespectList(String listId, String userId) async {
    return ApiResponse.error('Not implemented yet');
  }
  
  @override
  Future<ApiResponse<void>> followList(String listId, String userId) async {
    return ApiResponse.error('Not implemented yet');
  }
  
  @override
  Future<ApiResponse<void>> unfollowList(String listId, String userId) async {
    return ApiResponse.error('Not implemented yet');
  }
  
  @override
  Future<ApiResponse<void>> incrementViewCount(String entityId, String entityType) async {
    return ApiResponse.error('Not implemented yet');
  }
  
  @override
  Future<ApiResponse<void>> incrementShareCount(String entityId, String entityType) async {
    return ApiResponse.error('Not implemented yet');
  }
  
  @override
  Future<ApiResponse<Map<String, int>>> getEntityMetrics(String entityId) async {
    return ApiResponse.error('Not implemented yet');
  }
  
  @override
  Future<ApiResponse<List<T>>> batchGet<T>(List<String> ids, T Function(Map<String, dynamic>) fromJson) async {
    return ApiResponse.error('Not implemented yet');
  }
  
  @override
  Future<ApiResponse<void>> batchWrite(List<BatchOperation> operations) async {
    return ApiResponse.error('Not implemented yet');
  }
  
  @override
  Future<ApiResponse<String>> uploadFile(String filePath, List<int> fileBytes, {Map<String, String>? metadata}) async {
    return ApiResponse.error('Not implemented yet');
  }
  
  @override
  Future<ApiResponse<List<int>>> downloadFile(String path) async {
    return ApiResponse.error('Not implemented yet');
  }
  
  @override
  Future<ApiResponse<String>> getFileUrl(String path) async {
    return ApiResponse.error('Not implemented yet');
  }
  
  @override
  Future<ApiResponse<void>> deleteFile(String path) async {
    return ApiResponse.error('Not implemented yet');
  }
  
  @override
  Future<ApiResponse<T>> executeQuery<T>(String query, Map<String, dynamic> parameters, T Function(Map<String, dynamic>) fromJson) async {
    return ApiResponse.error('Not implemented yet');
  }
  
  @override
  Future<ApiResponse<T>> executeTransaction<T>(Future<T> Function(TransactionContext) operation) async {
    return ApiResponse.error('Not implemented yet');
  }

  Spot _mapRowToSpot(Map<String, dynamic> row) {
    double _numToDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0.0;
    DateTime _toDate(dynamic v) {
      if (v is DateTime) return v;
      if (v is String) {
        try { return DateTime.parse(v); } catch (_) {}
      }
      return DateTime.now();
    }
    return Spot(
      id: row['id'] as String,
      name: (row['name'] as String?) ?? '',
      description: (row['description'] as String?) ?? '',
      latitude: _numToDouble(row['latitude']),
      longitude: _numToDouble(row['longitude']),
      category: (row['category'] as String?) ?? 'general',
      createdBy: (row['created_by'] as String?) ?? '',
      createdAt: _toDate(row['created_at']),
      updatedAt: _toDate(row['updated_at']),
      address: row['address'] as String?,
      tags: (row['tags'] as List?)?.cast<String>() ?? const [],
      viewCount: (row['view_count'] as int?) ?? 0,
      respectCount: (row['respect_count'] as int?) ?? 0,
      shareCount: (row['share_count'] as int?) ?? 0,
    );
  }

  SpotList _mapRowToSpotList(Map<String, dynamic> row) {
    DateTime _toDate(dynamic v) {
      if (v is DateTime) return v;
      if (v is String) {
        try { return DateTime.parse(v); } catch (_) {}
      }
      return DateTime.now();
    }
    return SpotList(
      id: row['id'] as String,
      title: (row['name'] as String?) ?? '',
      description: (row['description'] as String?) ?? '',
      category: ListCategory.general,
      type: ListType.public,
      curatorId: (row['created_by'] as String?) ?? '',
      createdAt: _toDate(row['created_at']),
      updatedAt: _toDate(row['updated_at']),
      isPublic: (row['is_public'] as bool?) ?? true,
      tags: (row['tags'] as List?)?.cast<String>() ?? const [],
      respectCount: (row['respect_count'] as int?) ?? 0,
      viewCount: (row['view_count'] as int?) ?? 0,
      shareCount: (row['share_count'] as int?) ?? 0,
    );
  }

  bool _looksLikeUuid(String s) {
    final re = RegExp(r'^[0-9a-fA-F-]{36}$');
    return re.hasMatch(s);
  }
}

/// Simplified Supabase realtime backend
class SupabaseRealtimeBackendSimple implements RealtimeBackend {
  final supa.SupabaseClient _client;
  Map<String, dynamic> _config = {};
  bool _isInitialized = false;
  final Map<String, supa.RealtimeChannel> _channels = {};
  
  SupabaseRealtimeBackendSimple(this._client);
  
  @override
  bool get isInitialized => _isInitialized;
  
  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    _config = Map.unmodifiable(config);
    _isInitialized = true;
  }
  
  @override
  Future<void> dispose() async {
    _isInitialized = false;
  }
  
  // Implement basic realtime methods
  @override
  Stream<User?> subscribeToUser(String userId) {
    return _client
      .from('users')
      .stream(primaryKey: ['id'])
      .eq('id', userId)
      .map((event) {
        if (event.isNotEmpty) {
          return User.fromJson(event.first);
        }
        return null;
      });
  }
  
  @override
  Stream<Spot?> subscribeToSpot(String spotId) {
    return _client
      .from('spots')
      .stream(primaryKey: ['id'])
      .eq('id', spotId)
      .map((event) {
        if (event.isNotEmpty) {
          return Spot.fromJson(event.first);
        }
        return null;
      });
  }
  
  @override
  Stream<SpotList?> subscribeToSpotList(String listId) {
    return _client
      .from('spot_lists')
      .stream(primaryKey: ['id'])
      .eq('id', listId)
      .map((event) {
        if (event.isNotEmpty) {
          return SpotList.fromJson(event.first);
        }
        return null;
      });
  }
  
  @override
  Stream<List<Spot>> subscribeToSpotsInList(String listId) {
    return _client
      .from('spots')
      .stream(primaryKey: ['id'])
      .eq('list_id', listId)
      .map((event) {
        return event.map((json) => Spot.fromJson(json)).toList();
      });
  }
  
  @override
  Stream<List<Spot>> subscribeToNearbySpots(double latitude, double longitude, double radius) {
    return _client
      .from('spots')
      .stream(primaryKey: ['id'])
      .map((event) {
        return event.map((json) => Spot.fromJson(json)).toList();
      });
  }
  
  @override
  Stream<List<SpotList>> subscribeToUserLists(String userId) {
    return _client
      .from('spot_lists')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .map((event) {
        return event.map((json) => SpotList.fromJson(json)).toList();
      });
  }
  
  @override
  Stream<List<Spot>> subscribeToUserRespectedSpots(String userId) {
    return _client
      .from('spots')
      .stream(primaryKey: ['id'])
      .map((event) {
        return event.map((json) => Spot.fromJson(json)).toList();
      });
  }
  
  @override
  Stream<List<T>> subscribeToCollection<T>(String collection, T Function(Map<String, dynamic>) fromJson, {Map<String, dynamic>? filters, String? orderBy, bool? descending, int? limit}) {
    return _client
      .from(collection)
      .stream(primaryKey: ['id'])
      .map((event) {
        return event.map((json) => fromJson(json)).toList();
      });
  }
  
  @override
  Stream<T?> subscribeToDocument<T>(String collection, String documentId, T Function(Map<String, dynamic>) fromJson) {
    return _client
      .from(collection)
      .stream(primaryKey: ['id'])
      .eq('id', documentId)
      .map((event) => event.isNotEmpty ? fromJson(event.first) : null);
  }
  
  @override
  Stream<RealtimeMessage> subscribeToMessages(String channelId) {
    final channel = _ensureChannel(channelId);
    final controller = StreamController<RealtimeMessage>.broadcast();
    channel.onBroadcast(event: '*', callback: (payload, {String? event, String? type, String? timestamp}) {
      try {
        final Map<String, dynamic> p = (payload as Map<String, dynamic>? ) ?? <String, dynamic>{};
        final ev = event ?? p['type'] as String? ?? '';
        controller.add(RealtimeMessage(
          id: (p['id'] as String?) ?? DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: (p['senderId'] as String?) ?? 'unknown',
          content: (p['content'] as String?) ?? ev,
          type: (p['type'] as String?) ?? ev,
          timestamp: DateTime.tryParse(timestamp ?? '') ?? DateTime.now(),
          metadata: p,
        ));
      } catch (_) {}
    });
    return controller.stream;
  }
  
  @override
  Stream<List<UserPresence>> subscribeToPresence(String channelId) {
    final channel = _ensureChannel(channelId);
    final controller = StreamController<List<UserPresence>>.broadcast();
    channel.onPresenceSync((_) {
      try {
        // presenceState is Map<String, List<Map<String,dynamic>>>
        final raw = channel.presenceState();
        final flattened = <Map<String, dynamic>>[];
        (raw as Map).forEach((_, entries) {
          for (final e in (entries as List)) {
            flattened.add((e as Map).cast<String, dynamic>());
          }
        });
        controller.add(flattened.map((m) => _mapPresence(m)).toList());
      } catch (_) {}
    });
    return controller.stream;
  }
  
  @override
  Stream<List<LiveCursor>> subscribeToLiveCursors(String documentId) {
    return Stream.empty(); // Not implemented yet
  }
  
  @override
  Future<void> updatePresence(String channelId, UserPresence presence) async {
    final channel = _ensureChannel(channelId);
    await channel.track(presence.toJson());
  }
  
  @override
  Future<void> removePresence(String channelId) async {
    final channel = _ensureChannel(channelId);
    try { await channel.untrack(); } catch (_) {}
  }
  
  @override
  Future<void> sendMessage(String channelId, RealtimeMessage message) async {
    final channel = _ensureChannel(channelId);
    await channel.sendBroadcastMessage(
      event: message.type,
      payload: {
        'id': message.id,
        'senderId': message.senderId,
        'content': message.content,
        'type': message.type,
        'timestamp': message.timestamp.toIso8601String(),
        'metadata': message.metadata,
      },
    );
  }
  
  @override
  Future<void> updateLiveCursor(String documentId, LiveCursor cursor) async {
    // Not implemented yet
  }
  
  @override
  Future<void> unsubscribe(String subscriptionId) async {
    final channel = _channels.remove(subscriptionId);
    if (channel != null) {
      await channel.unsubscribe();
    }
  }
  
  @override
  Future<void> unsubscribeAll() async {
    for (final channel in _channels.values) {
      try { await channel.unsubscribe(); } catch (_) {}
    }
    _channels.clear();
  }
  
  @override
  Future<void> connect() async {
    // Supabase maintains websocket connection automatically after initialize
  }
  
  @override
  Stream<RealtimeConnectionStatus> get connectionStatus {
    return Stream.value(RealtimeConnectionStatus.connected);
  }
  
  @override
  Future<void> disconnect() async {
    await unsubscribeAll();
  }
  
  @override
  Future<void> joinChannel(String channelId) async {
    _ensureChannel(channelId);
  }
  
  @override
  Future<void> leaveChannel(String channelId) async {
    await unsubscribe(channelId);
  }
  
  @override
  Future<void> trackRealtimeEvent(String eventName, Map<String, dynamic> data) async {
    // Optional: could broadcast on a diagnostics channel
  }

  supa.RealtimeChannel _ensureChannel(String channelId) {
    final existing = _channels[channelId];
    if (existing != null) return existing;
    final channel = _client.channel(channelId);
    _channels[channelId] = channel;
    // Fire-and-forget subscribe
    channel.subscribe();
    return channel;
  }

  UserPresence _mapPresence(Map<String, dynamic> json) {
    // Normalize common keys; fallback defaults
    final data = json;
    return UserPresence(
      userId: (data['userId'] as String?) ?? (data['user_id'] as String?) ?? 'unknown',
      userName: (data['userName'] as String?) ?? (data['user_name'] as String?) ?? 'anon',
      avatarUrl: data['avatarUrl'] as String?,
      lastSeen: () {
        final v = data['lastSeen'] ?? data['last_seen'];
        if (v is String) { try { return DateTime.parse(v); } catch (_) {} }
        return DateTime.now();
      }(),
      isOnline: (data['isOnline'] as bool?) ?? true,
      metadata: (data['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }
}

/// Exception thrown when Supabase backend initialization fails
class BackendInitializationException implements Exception {
  final String message;
  const BackendInitializationException(this.message);
  
  @override
  String toString() => 'BackendInitializationException: $message';
}

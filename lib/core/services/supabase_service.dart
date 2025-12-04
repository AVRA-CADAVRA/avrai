import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spots/core/services/logger.dart';

/// Supabase service for SPOTS app
/// Provides a clean interface to Supabase backend
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();
  static const String _logName = 'SupabaseService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);

  SupabaseClient get _client => Supabase.instance.client;

  /// Expose client for internal service consumers (not UI)
  SupabaseClient get client => _client;

  /// Check if Supabase is available
  bool get isAvailable => true;

  /// Test connection to Supabase
  Future<bool> testConnection() async {
    try {
      await _client.from('users').select('count').limit(1);
      _logger.info('Supabase connection test successful', tag: _logName);
      return true;
    } catch (e) {
      _logger.error('Supabase connection test failed', error: e, tag: _logName);
      return false;
    }
  }

  /// Get current user
  User? get currentUser => _client.auth.currentUser;

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _logger.info('User signed in: ${response.user?.email}', tag: _logName);
      return response;
    } catch (e) {
      _logger.error('Sign in failed', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      _logger.info('User signed up: ${response.user?.email}', tag: _logName);
      return response;
    } catch (e) {
      _logger.error('Sign up failed', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      _logger.info('User signed out', tag: _logName);
    } catch (e) {
      _logger.error('Sign out failed', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Create a new spot
  Future<Map<String, dynamic>> createSpot({
    required String name,
    required double latitude,
    required double longitude,
    String? description,
    List<String>? tags,
  }) async {
    try {
      final spotData = {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
        'tags': tags,
        'created_at': DateTime.now().toIso8601String(),
        'user_id': currentUser?.id,
      };

      final response = await _client.from('spots').insert(spotData).select().single();
      _logger.info('Spot created: $name', tag: _logName);
      return response;
    } catch (e) {
      _logger.error('Failed to create spot', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Get all spots
  Future<List<Map<String, dynamic>>> getSpots() async {
    try {
      final response = await _client.from('spots').select('*').order('created_at', ascending: false);
      final spots = List<Map<String, dynamic>>.from(response);
      _logger.info('Retrieved ${spots.length} spots', tag: _logName);
      return spots;
    } catch (e) {
      _logger.error('Failed to get spots', error: e, tag: _logName);
      return [];
    }
  }

  /// Get spots by user
  Future<List<Map<String, dynamic>>> getSpotsByUser(String userId) async {
    try {
      final response = await _client
          .from('spots')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      final spots = List<Map<String, dynamic>>.from(response);
      _logger.info('Retrieved ${spots.length} spots for user $userId', tag: _logName);
      return spots;
    } catch (e) {
      _logger.error('Failed to get spots by user', error: e, tag: _logName);
      return [];
    }
  }

  /// Create a new spot list
  Future<Map<String, dynamic>> createSpotList({
    required String name,
    String? description,
    List<String>? tags,
  }) async {
    try {
      final listData = {
        'name': name,
        'description': description,
        'tags': tags,
        'created_at': DateTime.now().toIso8601String(),
        'user_id': currentUser?.id,
      };

      final response = await _client.from('spot_lists').insert(listData).select().single();
      _logger.info('Spot list created: $name', tag: _logName);
      return response;
    } catch (e) {
      _logger.error('Failed to create spot list', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Get all spot lists
  Future<List<Map<String, dynamic>>> getSpotLists() async {
    try {
      final response = await _client.from('spot_lists').select('*').order('created_at', ascending: false);
      final lists = List<Map<String, dynamic>>.from(response);
      _logger.info('Retrieved ${lists.length} spot lists', tag: _logName);
      return lists;
    } catch (e) {
      _logger.error('Failed to get spot lists', error: e, tag: _logName);
      return [];
    }
  }

  /// Add spot to list
  Future<Map<String, dynamic>> addSpotToList({
    required String listId,
    required String spotId,
    String? note,
  }) async {
    try {
      final itemData = {
        'list_id': listId,
        'spot_id': spotId,
        'note': note,
        'created_at': DateTime.now().toIso8601String(),
        'user_id': currentUser?.id,
      };

      final response = await _client.from('spot_list_items').insert(itemData).select().single();
      _logger.info('Spot added to list: $spotId -> $listId', tag: _logName);
      return response;
    } catch (e) {
      _logger.error('Failed to add spot to list', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Get real-time updates for spots
  Stream<List<Map<String, dynamic>>> getSpotsStream() {
    return _client
        .from('spots')
        .stream(primaryKey: ['id'])
        .map((event) => List<Map<String, dynamic>>.from(event));
  }

  /// Get real-time updates for spot lists
  Stream<List<Map<String, dynamic>>> getSpotListsStream() {
    return _client
        .from('spot_lists')
        .stream(primaryKey: ['id'])
        .map((event) => List<Map<String, dynamic>>.from(event));
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateUserProfile({
    String? name,
    String? bio,
    String? location,
    String? avatarUrl,
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('No authenticated user');

      final profileData = {
        if (name != null) 'name': name,
        if (bio != null) 'bio': bio,
        if (location != null) 'location': location,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('users')
          .update(profileData)
          .eq('id', userId)
          .select()
          .single();
      
      _logger.info('User profile updated', tag: _logName);
      return response;
    } catch (e) {
      _logger.error('Failed to update user profile', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();
      
      _logger.info('Retrieved user profile for $userId', tag: _logName);
      return response;
    } catch (e) {
      _logger.error('Failed to get user profile', error: e, tag: _logName);
      return null;
    }
  }
}

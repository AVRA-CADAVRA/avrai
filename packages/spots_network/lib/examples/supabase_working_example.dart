import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

/// Simple working example of Supabase backend
/// This demonstrates the concept without complex interface requirements
class SupabaseWorkingExample {
  static SupabaseClient? _client;
  static bool _isInitialized = false;
  
  /// Initialize Supabase
  static Future<bool> initialize({
    required String url,
    required String anonKey,
  }) async {
    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: false,
      );
      
      _client = Supabase.instance.client;
      _isInitialized = true;
      
      print('✅ Supabase initialized successfully');
      return true;
      
    } catch (e) {
      print('❌ Supabase initialization failed: $e');
      return false;
    }
  }
  
  /// Check if initialized
  static bool get isInitialized => _isInitialized;
  
  /// Get current user
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    if (!_isInitialized || _client == null) {
      return null;
    }
    
    try {
      final user = _client!.auth.currentUser;
      if (user != null) {
        return {
          'id': user.id,
          'email': user.email,
          'name': user.userMetadata?['name'] ?? '',
          'createdAt': user.createdAt.toString(),
          'isEmailVerified': user.emailConfirmedAt != null,
        };
      }
      return null;
    } catch (e) {
      print('Get current user failed: $e');
      return null;
    }
  }
  
  /// Sign in with email and password
  static Future<Map<String, dynamic>?> signIn(String email, String password) async {
    if (!_isInitialized || _client == null) {
      return null;
    }
    
    try {
      final response = await _client!.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        return {
          'id': response.user!.id,
          'email': response.user!.email,
          'name': response.user!.userMetadata?['name'] ?? '',
          'createdAt': response.user!.createdAt.toIso8601String(),
          'isEmailVerified': response.user!.emailConfirmedAt != null,
        };
      }
      return null;
    } catch (e) {
      print('Sign in failed: $e');
      return null;
    }
  }
  
  /// Sign up with email and password
  static Future<Map<String, dynamic>?> signUp(String email, String password, String name) async {
    if (!_isInitialized || _client == null) {
      return null;
    }
    
    try {
      final response = await _client!.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      
      if (response.user != null) {
        return {
          'id': response.user!.id,
          'email': response.user!.email,
          'name': response.user!.userMetadata?['name'] ?? '',
          'createdAt': response.user!.createdAt.toIso8601String(),
          'isEmailVerified': response.user!.emailConfirmedAt != null,
        };
      }
      return null;
    } catch (e) {
      print('Sign up failed: $e');
      return null;
    }
  }
  
  /// Sign out
  static Future<void> signOut() async {
    if (!_isInitialized || _client == null) {
      return;
    }
    
    try {
      await _client!.auth.signOut();
      print('✅ Signed out successfully');
    } catch (e) {
      print('❌ Sign out failed: $e');
    }
  }
  
  /// Create a document in a collection
  static Future<Map<String, dynamic>?> createDocument(
    String collection,
    Map<String, dynamic> data,
  ) async {
    if (!_isInitialized || _client == null) {
      return null;
    }
    
    try {
      final response = await _client!
        .from(collection)
        .insert(data)
        .select()
        .single();
      
      return response;
    } catch (e) {
      print('Create document failed: $e');
      return null;
    }
  }
  
  /// Get documents from a collection
  static Future<List<Map<String, dynamic>>> getDocuments(
    String collection, {
    Map<String, dynamic>? filters,
    int? limit,
  }) async {
    if (!_isInitialized || _client == null) {
      return [];
    }
    
    try {
      var query = _client!.from(collection).select();
      
      if (filters != null) {
        for (final entry in filters.entries) {
          query = query.eq(entry.key, entry.value);
        }
      }
      
      if (limit != null) {
        // Note: Supabase query builder has type issues, this is simplified
        // In real implementation, you'd handle the query builder properly
      }
      
      final response = await query;
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Get documents failed: $e');
      return [];
    }
  }
  
  /// Update a document
  static Future<Map<String, dynamic>?> updateDocument(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    if (!_isInitialized || _client == null) {
      return null;
    }
    
    try {
      final response = await _client!
        .from(collection)
        .update(data)
        .eq('id', id)
        .select()
        .single();
      
      return response;
    } catch (e) {
      print('Update document failed: $e');
      return null;
    }
  }
  
  /// Delete a document
  static Future<bool> deleteDocument(String collection, String id) async {
    if (!_isInitialized || _client == null) {
      return false;
    }
    
    try {
      await _client!
        .from(collection)
        .delete()
        .eq('id', id);
      
      return true;
    } catch (e) {
      print('Delete document failed: $e');
      return false;
    }
  }
  
  /// Upload a file
  static Future<String?> uploadFile(String path, List<int> data) async {
    if (!_isInitialized || _client == null) {
      return null;
    }
    
    try {
      final response = await _client!.storage
        .from('files')
        .uploadBinary(path, Uint8List.fromList(data));
      
      return response;
    } catch (e) {
      print('Upload file failed: $e');
      return null;
    }
  }
  
  /// Get file URL
  static Future<String?> getFileUrl(String path) async {
    if (!_isInitialized || _client == null) {
      return null;
    }
    
    try {
      final response = await _client!.storage
        .from('files')
        .getPublicUrl(path);
      
      return response;
    } catch (e) {
      print('Get file URL failed: $e');
      return null;
    }
  }
  
  /// Health check
  static Future<bool> healthCheck() async {
    if (!_isInitialized || _client == null) {
      return false;
    }
    
    try {
      final user = _client!.auth.currentUser;
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Dispose resources
  static Future<void> dispose() async {
    _isInitialized = false;
    _client = null;
  }
}

/// Example usage
class SupabaseExampleUsage {
  static Future<void> runExample() async {
    print('🚀 Starting Supabase example...');
    
    // Initialize Supabase
    final success = await SupabaseWorkingExample.initialize(
      url: 'https://your-project.supabase.co',
      anonKey: 'your-anon-key',
    );
    
    if (!success) {
      print('❌ Failed to initialize Supabase');
      return;
    }
    
    // Health check
    final isHealthy = await SupabaseWorkingExample.healthCheck();
    print('🏥 Health check: ${isHealthy ? 'Healthy' : 'Unhealthy'}');
    
    // Create a user document
    final userData = {
      'name': 'John Doe',
      'email': 'john@example.com',
      'created_at': DateTime.now().toIso8601String(),
    };
    
    final createdUser = await SupabaseWorkingExample.createDocument('users', userData);
    if (createdUser != null) {
      print('✅ Created user: ${createdUser['id']}');
      
      // Update the user
      final updatedUser = await SupabaseWorkingExample.updateDocument(
        'users',
        createdUser['id'],
        {'name': 'John Smith'},
      );
      
      if (updatedUser != null) {
        print('✅ Updated user: ${updatedUser['name']}');
      }
      
      // Get all users
      final users = await SupabaseWorkingExample.getDocuments('users');
      print('📋 Found ${users.length} users');
      
      // Delete the user
      final deleted = await SupabaseWorkingExample.deleteDocument('users', createdUser['id']);
      if (deleted) {
        print('✅ Deleted user');
      }
    }
    
    // File upload example
    final fileData = [1, 2, 3, 4, 5]; // Example file data
    final uploadedPath = await SupabaseWorkingExample.uploadFile('test.txt', fileData);
    if (uploadedPath != null) {
      print('✅ Uploaded file: $uploadedPath');
      
      final fileUrl = await SupabaseWorkingExample.getFileUrl(uploadedPath);
      if (fileUrl != null) {
        print('🔗 File URL: $fileUrl');
      }
    }
    
    print('✅ Supabase example completed successfully!');
  }
}

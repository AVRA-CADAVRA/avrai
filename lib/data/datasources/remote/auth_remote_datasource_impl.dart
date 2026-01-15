import 'package:avrai/core/models/user.dart' as local;
import 'package:avrai/data/datasources/remote/auth_remote_datasource.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:avrai_core/avra_core.dart' as core;
import 'package:avrai/injection_container.dart' as di;

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthBackend? get _auth {
    try {
      return di.sl<AuthBackend>();
    } catch (_) {
      // AuthBackend not registered (e.g., Supabase not initialized)
      return null;
    }
  }

  @override
  Future<local.User?> signIn(String email, String password) async {
    final auth = _auth;
    if (auth == null) return null;
    final coreUser = await auth.signInWithEmailPassword(email, password);
    return coreUser == null ? null : _toLocalUser(coreUser);
  }

  @override
  Future<local.User?> signUp(String email, String password, String name) async {
    final auth = _auth;
    if (auth == null) {
      throw Exception(
          'Authentication backend not available. Please check your Supabase configuration.');
    }
    try {
      final coreUser =
          await auth.registerWithEmailPassword(email, password, name);
      return coreUser == null ? null : _toLocalUser(coreUser);
    } catch (e) {
      // Re-throw with more context for common Supabase errors
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('user already registered') ||
          errorString.contains('email already exists')) {
        throw Exception(
            'An account with this email already exists. Please sign in instead.');
      } else if (errorString.contains('password') &&
          errorString.contains('weak')) {
        throw Exception(
            'Password is too weak. Please use a stronger password.');
      } else if (errorString.contains('rate limit') ||
          errorString.contains('over_email_send_rate_limit') ||
          errorString.contains('429')) {
        throw Exception(
            'Too many signup attempts. Please wait a few minutes before trying again. If you continue to see this error, try using a different email address.');
      } else if (errorString.contains('email') &&
          (errorString.contains('invalid') || errorString.contains('format'))) {
        // Show the actual Supabase error for email validation issues
        throw Exception(
            'Invalid email address: ${e.toString()}. Please check your email format and try again.');
      } else if (errorString.contains('network') ||
          errorString.contains('connection')) {
        throw Exception(
            'Network error. Please check your internet connection and try again.');
      }
      // Re-throw original error for other cases to see actual error
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    final auth = _auth;
    if (auth == null) return;
    try {
      await auth.signOut();
    } catch (_) {
      // Ignore errors if backend not available
    }
  }

  @override
  Future<local.User?> getCurrentUser() async {
    final auth = _auth;
    if (auth == null) return null;
    try {
      final coreUser = await auth.getCurrentUser();
      return coreUser == null ? null : _toLocalUser(coreUser);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<local.User?> updateUser(local.User user) async {
    // Fast path: return local user for now to avoid cross-model conversion.
    // Backend profile update can be wired later if needed.
    return user;
  }

  @override
  Future<void> updatePassword(
      String currentPassword, String newPassword) async {
    final auth = _auth;
    if (auth == null) return;
    try {
      await auth.updatePassword(currentPassword, newPassword);
    } catch (_) {
      // Ignore errors if backend not available
    }
  }

  local.User _toLocalUser(core.User u) {
    final role = _mapRole(u.role);
    return local.User(
      id: u.id,
      email: u.email,
      name: u.name,
      displayName: u.displayName,
      role: role,
      createdAt: u.createdAt,
      updatedAt: u.updatedAt,
      isOnline: u.isOnline,
    );
  }

  local.UserRole _mapRole(core.UserRole r) {
    switch (r) {
      case core.UserRole.admin:
        return local.UserRole.admin;
      default:
        return local.UserRole.user;
    }
  }
}

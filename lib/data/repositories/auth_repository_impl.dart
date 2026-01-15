import 'dart:developer' as developer;
import 'package:avrai/core/models/user.dart';
import 'package:avrai/data/datasources/local/auth_local_datasource.dart';
import 'package:avrai/data/datasources/remote/auth_remote_datasource.dart';
import 'package:avrai/domain/repositories/auth_repository.dart';
import 'package:avrai/data/repositories/repository_patterns.dart';

/// Auth Repository Implementation
///
/// Uses different patterns per operation:
/// - Sign In/Sign Up: Online-first (requires server)
/// - Get Current User: Offline-first (can work with cached credentials)
/// - Update User: Offline-first (local-first with sync)
/// - Update Password: Remote-only (requires online)
class AuthRepositoryImpl extends SimplifiedRepositoryBase
    implements AuthRepository {
  final AuthLocalDataSource? localDataSource;
  final AuthRemoteDataSource? remoteDataSource;

  AuthRepositoryImpl({
    super.connectivity,
    this.localDataSource,
    this.remoteDataSource,
  });

  @override
  Future<User?> signIn(String email, String password) async {
    developer.log('🔐 AuthRepository: Starting sign in for $email');

    try {
      // Auth should attempt remote even if connectivity checks are flaky.
      // Some environments can throw during Connectivity.checkConnectivity(); do not
      // treat that as definitive offline for sign-in.
      if (remoteDataSource == null) {
        throw Exception(
            'Remote data source not available (backend not initialized)');
      }

      developer.log('🔐 AuthRepository: Trying remote sign in');
      final user = await remoteDataSource!.signIn(email, password);
      if (user != null) {
        developer.log('🔐 AuthRepository: Remote sign in successful');
        await localDataSource?.saveUser(user);
        return user;
      }

      developer.log(
          '🔐 AuthRepository: Remote sign in returned null; trying local fallback');
      final localUser = await localDataSource?.signIn(email, password);
      developer.log(
          '🔐 AuthRepository: Local sign in result: ${localUser?.email ?? 'null'}');
      return localUser;
    } catch (e) {
      developer.log('🔐 AuthRepository: Sign in error: $e');
      developer.log('Sign in failed: $e', name: 'AuthRepository');
      // Final fallback to local
      final localUser = await localDataSource?.signIn(email, password);
      if (localUser != null) return localUser;
      // Surface the root cause if local fallback is not available.
      rethrow;
    }
  }

  @override
  Future<User?> signUp(String email, String password, String name) async {
    // Sign up is remote-only, but do not rely on Connectivity checks which may be flaky.
    if (remoteDataSource == null) {
      throw Exception(
          'Authentication service is not available. Please check your Supabase configuration and try again.');
    }

    try {
      final user = await remoteDataSource!.signUp(email, password, name);
      if (user != null) {
        await localDataSource?.saveUser(user);
      }
      return user;
    } catch (e) {
      developer.log('🔐 AuthRepository: Sign up error: $e',
          name: 'AuthRepository');
      // Re-throw to let AuthBloc handle the error message
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Try remote sign out first, but always clear local data regardless
      if (remoteDataSource != null && await isOnline) {
        try {
          await remoteDataSource!.signOut();
        } catch (e) {
          developer.log('Remote sign out failed: $e', name: 'AuthRepository');
          // Continue to clear local data even if remote fails
        }
      }

      // Always clear local data
      await localDataSource?.clearUser();
    } catch (e) {
      developer.log('Sign out error: $e', name: 'AuthRepository');
      // Still try to clear local data
      await localDataSource?.clearUser();
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    // Auth state should be able to hydrate from the remote session even when
    // connectivity checks are flaky (e.g., simulator / plugin edge-cases).
    //
    // Strategy:
    // - Try remote first (best-effort).
    // - Fall back to local cached user if remote is unavailable/fails.
    try {
      if (remoteDataSource != null) {
        final remoteUser = await remoteDataSource!.getCurrentUser();
        if (remoteUser != null) {
          await localDataSource?.saveUser(remoteUser);
          return remoteUser;
        }
      }
    } catch (e) {
      developer.log('Get current user (remote) failed: $e',
          name: 'AuthRepository');
    }

    return await (localDataSource?.getCurrentUser() ?? Future.value(null));
  }

  @override
  Future<User?> updateCurrentUser(User user) async {
    // Offline-first: update local immediately, sync to remote if online
    return await executeOfflineFirst<User?>(
      localOperation: () async {
        await localDataSource?.saveUser(user);
        return user;
      },
      remoteOperation: remoteDataSource != null
          ? () => remoteDataSource!.updateUser(user)
          : null,
      syncToLocal: (remoteUser) async {
        if (remoteUser != null) {
          await localDataSource?.saveUser(remoteUser);
        }
      },
    );
  }

  @override
  Future<bool> isOfflineMode() async {
    return remoteDataSource == null;
  }

  @override
  Future<void> updateUser(User user) async {
    await updateCurrentUser(user);
  }

  @override
  Future<void> updatePassword(
      String currentPassword, String newPassword) async {
    // Password update requires online connection
    if (remoteDataSource == null) {
      throw Exception(
          'Cannot update password: remote data source not available');
    }

    await executeRemoteOnly<void>(
      remoteOperation: () async {
        await remoteDataSource!.updatePassword(currentPassword, newPassword);
        developer.log('Password updated successfully', name: 'AuthRepository');
      },
    );
  }
}

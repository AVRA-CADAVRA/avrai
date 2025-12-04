import 'dart:developer' as developer;
import 'package:spots/core/models/user.dart';
import 'package:spots/data/datasources/local/auth_local_datasource.dart';
import 'package:spots/data/datasources/remote/auth_remote_datasource.dart';
import 'package:spots/domain/repositories/auth_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource? localDataSource;
  final AuthRemoteDataSource? remoteDataSource;
  final Connectivity? connectivity;

  AuthRepositoryImpl({
    this.localDataSource,
    this.remoteDataSource,
    this.connectivity,
  });

  @override
  Future<User?> signIn(String email, String password) async {
    try {
      developer.log('🔐 AuthRepository: Starting sign in for $email');
      
      // Check connectivity first - offline-first approach
      final connectivityResult = await connectivity?.checkConnectivity() ?? [ConnectivityResult.none];
      final isOnline = !connectivityResult.contains(ConnectivityResult.none);
      
      if (isOnline && remoteDataSource != null) {
        developer.log('🔐 AuthRepository: Trying remote sign in');
        final user = await remoteDataSource!.signIn(email, password);
        if (user != null) {
          developer.log('🔐 AuthRepository: Remote sign in successful');
          await localDataSource?.saveUser(user);
          return user;
        }
      }
      
      // Use local sign in (either offline or remote failed)
      developer.log('🔐 AuthRepository: Trying local sign in');
      developer.log('🔐 AuthRepository: localDataSource is ${localDataSource == null ? 'null' : 'not null'}');
      final localUser = await localDataSource?.signIn(email, password);
      developer.log('🔐 AuthRepository: Local sign in result: ${localUser?.email ?? 'null'}');
      return localUser;
    } catch (e) {
      developer.log('🔐 AuthRepository: Sign in error: $e');
      developer.log('Online sign in failed: $e', name: 'AuthRepository');
      // Fallback to local
      return await localDataSource?.signIn(email, password);
    }
  }

  @override
  Future<User?> signUp(String email, String password, String name) async {
    // Check connectivity first
    final connectivityResult = await connectivity?.checkConnectivity() ?? [ConnectivityResult.none];
    final isOnline = !connectivityResult.contains(ConnectivityResult.none);
    
    if (!isOnline) {
      throw Exception('Cannot sign up while offline. Please connect to the internet to create a new account.');
    }
    
    try {
      // Online sign up
      if (remoteDataSource != null) {
        final user = await remoteDataSource!.signUp(email, password, name);
        if (user != null) {
          await localDataSource?.saveUser(user);
          return user;
        }
      }
      
      // If remote signup failed, create local user
      final now = DateTime.now();
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: email,
        name: name,
        role: UserRole.user,
        createdAt: now,
        updatedAt: now,
      );
      return await localDataSource?.signUp(email, password, user);
    } catch (e) {
      developer.log('Online sign up failed: $e', name: 'AuthRepository');
      // Try local sign up as fallback
      final now = DateTime.now();
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: email,
        name: name,
        role: UserRole.user,
        createdAt: now,
        updatedAt: now,
      );
      return await localDataSource?.signUp(email, password, user);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Try remote sign out first
      if (remoteDataSource != null) {
        await remoteDataSource!.signOut();
      }
      
      // Always clear local data
      await localDataSource?.clearUser();
    } catch (e) {
      developer.log('Online sign out failed: $e', name: 'AuthRepository');
      // Still clear local data
      await localDataSource?.clearUser();
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      // Try to get from remote first
      if (remoteDataSource != null) {
        final user = await remoteDataSource!.getCurrentUser();
        if (user != null) {
          await localDataSource?.saveUser(user);
          return user;
        }
      }
      
      // Fallback to local
      return await localDataSource?.getCurrentUser();
    } catch (e) {
      developer.log('Error getting remote user: $e', name: 'AuthRepository');
      // Fallback to local
      return await localDataSource?.getCurrentUser();
    }
  }

  @override
  Future<User?> updateCurrentUser(User user) async {
    try {
      // Try remote update first
      if (remoteDataSource != null) {
        final updatedUser = await remoteDataSource!.updateUser(user);
        if (updatedUser != null) {
          await localDataSource?.saveUser(updatedUser);
          return updatedUser;
        }
      }
      
      // Fallback to local update
      await localDataSource?.saveUser(user);
      return user;
    } catch (e) {
      developer.log('Error getting current user: $e', name: 'AuthRepository');
      // Fallback to local update
      await localDataSource?.saveUser(user);
      return user;
    }
  }

  @override
  Future<bool> isOfflineMode() async {
    return remoteDataSource == null;
  }

  @override
  Future<void> updateUser(User user) async {
    await updateCurrentUser(user);
  }
}

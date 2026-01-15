import 'package:avrai/core/services/logger.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/models/user.dart';
import 'package:avrai/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:avrai/domain/usecases/auth/sign_in_usecase.dart';
import 'package:avrai/domain/usecases/auth/sign_out_usecase.dart';
import 'package:avrai/domain/usecases/auth/sign_up_usecase.dart';
import 'package:avrai/domain/usecases/auth/update_password_usecase.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:avrai/core/services/personality_sync_service.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/ai2ai/connection_orchestrator.dart';
import 'package:avrai/core/services/storage_service.dart' show StorageService;
import 'package:avrai/injection_container.dart' as di;

// Events
abstract class AuthEvent {}

class SignInRequested extends AuthEvent {
  final String email;
  final String password;

  SignInRequested(this.email, this.password);
}

class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;

  SignUpRequested(this.email, this.password, this.name);
}

class SignOutRequested extends AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class UpdatePasswordRequested extends AuthEvent {
  final String currentPassword;
  final String newPassword;

  UpdatePasswordRequested(this.currentPassword, this.newPassword);
}

// States
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;
  final bool isOffline;

  Authenticated({required this.user, this.isOffline = false});
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AppLogger _logger =
      const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  final SignInUseCase signInUseCase;
  final SignUpUseCase signUpUseCase;
  final SignOutUseCase signOutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final UpdatePasswordUseCase updatePasswordUseCase;

  AuthBloc({
    required this.signInUseCase,
    required this.signUpUseCase,
    required this.signOutUseCase,
    required this.getCurrentUserUseCase,
    required this.updatePasswordUseCase,
  }) : super(AuthInitial()) {
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<UpdatePasswordRequested>(_onUpdatePasswordRequested);
  }

  /// Normalize a login identifier into an email address.
  ///
  /// The app supports logging in using either:
  /// - an email (`user@example.com`)
  /// - a username (`reis`) which maps to a deterministic dev email (`reis@avrai.app`)
  ///
  /// This keeps the backend auth model simple (email+password) while allowing a
  /// friendlier UX on the login page.
  String _normalizeEmailOrUsername(String value) {
    final v = value.trim();
    if (v.isEmpty) return v;
    if (v.contains('@')) return v;
    final safe = v.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    return '$safe@avrai.app';
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final normalizedEmail = _normalizeEmailOrUsername(event.email);
      _logger.info('🔐 AuthBloc: Attempting sign in for ${event.email}',
          tag: 'AuthBloc');
      final user = await signInUseCase(normalizedEmail, event.password);
      _logger.debug(
          '🔐 AuthBloc: Sign in result - user: ${user?.email ?? 'null'}',
          tag: 'AuthBloc');
      if (user != null) {
        final isOffline = user.isOnline == false;
        _logger.info('🔐 AuthBloc: User authenticated successfully',
            tag: 'AuthBloc');

        // Emit authenticated ASAP so routing/UI can proceed immediately.
        // All heavy post-login initialization runs in the background.
        emit(Authenticated(user: user, isOffline: isOffline));

        unawaited(_postLoginInit(
          user: user,
          password: event.password,
          allowCloudLoad: true,
        ));

        return;
      } else {
        _logger.warn('🔐 AuthBloc: User authentication failed - null user',
            tag: 'AuthBloc');
        emit(AuthError('Invalid credentials'));
      }
    } catch (e) {
      _logger.error('🔐 AuthBloc: Sign in error', error: e, tag: 'AuthBloc');
      final msg = e.toString();
      if (msg.contains('email_not_confirmed') ||
          msg.toLowerCase().contains('email not confirmed')) {
        emit(AuthError(
            'Email not confirmed. Ask support to confirm your account (dev: confirm the user in Supabase) and try again.'));
      } else {
        emit(AuthError(msg));
      }
    }
  }

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await signUpUseCase(event.email, event.password, event.name);
      if (user != null) {
        final isOffline = user.isOnline == false;
        emit(Authenticated(user: user, isOffline: isOffline));
      } else {
        emit(AuthError(
            'Failed to create account. Please check your connection and try again.'));
      }
    } catch (e) {
      _logger.error('🔐 AuthBloc: Sign up error', error: e, tag: 'AuthBloc');
      // Extract user-friendly error message
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      emit(AuthError(
          errorMessage.isEmpty ? 'Failed to create account' : errorMessage));
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Clear stored password from secure storage before sign out
      try {
        final authState = state;
        if (authState is Authenticated) {
          const secureStorage = FlutterSecureStorage();
          await secureStorage.delete(
              key: 'user_password_session_${authState.user.id}');
          _logger.debug('🔐 AuthBloc: Password cleared from secure storage',
              tag: 'AuthBloc');
        }
      } catch (e) {
        // MissingPluginException is expected in unit tests (platform channels not available)
        // Only log at debug level to avoid cluttering test output
        if (e.toString().contains('MissingPluginException')) {
          _logger.debug(
              '🔐 AuthBloc: Secure storage not available (expected in tests): $e',
              tag: 'AuthBloc');
        } else {
          _logger.warn('🔐 AuthBloc: Failed to clear password: $e',
              tag: 'AuthBloc');
        }
        // Don't block sign out if password clearing fails
      }

      await signOutUseCase();

      // Ensure AI2AI background work is stopped on sign out.
      try {
        final orchestrator = di.sl<VibeConnectionOrchestrator>();
        await orchestrator.shutdown();
      } catch (e) {
        _logger.debug('AuthBloc: Orchestrator shutdown skipped: $e',
            tag: 'AuthBloc');
      }

      emit(Unauthenticated());
    } catch (e) {
      _logger.error('🔐 AuthBloc: Sign out error', error: e, tag: 'AuthBloc');
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await getCurrentUserUseCase();
      if (user != null) {
        final isOffline = user.isOnline == false;
        emit(Authenticated(user: user, isOffline: isOffline));

        // Background init (no password available during auth-check).
        unawaited(_postLoginInit(
          user: user,
          password: null,
          allowCloudLoad: false,
        ));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  Future<void> _postLoginInit({
    required User user,
    required String? password,
    required bool allowCloudLoad,
  }) async {
    // Store password temporarily in secure storage for cloud sync operations.
    if (password != null && password.isNotEmpty) {
      try {
        const secureStorage = FlutterSecureStorage();
        await secureStorage.write(
          key: 'user_password_session_${user.id}',
          value: password,
        );
        _logger.debug('🔐 AuthBloc: Password stored in secure storage for sync',
            tag: 'AuthBloc');
      } catch (e) {
        // MissingPluginException is expected in unit tests (platform channels not available)
        if (e.toString().contains('MissingPluginException')) {
          _logger.debug(
              '🔐 AuthBloc: Secure storage not available (expected in tests): $e',
              tag: 'AuthBloc');
        } else {
          _logger.warn('🔐 AuthBloc: Failed to store password for sync: $e',
              tag: 'AuthBloc');
        }
      }
    }

    // Initialize personality (cloud load if enabled and we have a password).
    PersonalityProfile? profile;
    try {
      final personalityLearning = di.sl<PersonalityLearning>();
      if (allowCloudLoad && password != null && password.isNotEmpty) {
        final syncService = di.sl<PersonalitySyncService>();
        final syncEnabled = await syncService.isCloudSyncEnabled(user.id);
        if (syncEnabled) {
          _logger.info(
              '☁️ AuthBloc: Cloud sync enabled, initializing personality with cloud load...',
              tag: 'AuthBloc');
          profile = await personalityLearning.initializePersonality(
            user.id,
            password: password,
          );
          _logger.info(
              '✅ AuthBloc: Personality initialized (may have loaded from cloud)',
              tag: 'AuthBloc');
        } else {
          profile = await personalityLearning.initializePersonality(user.id);
        }
      } else {
        profile = await personalityLearning.initializePersonality(user.id);
      }
    } catch (e) {
      _logger.warn('⚠️ AuthBloc: Personality init failed/skipped: $e',
          tag: 'AuthBloc');
    }

    // Start/stop AI2AI orchestration based on the discovery switch.
    try {
      final discoveryEnabled =
          StorageService.instance.getBool('discovery_enabled') ?? false;
      final orchestrator = di.sl<VibeConnectionOrchestrator>();
      if (!discoveryEnabled) {
        await orchestrator.shutdown();
      } else {
        final personalityLearning = di.sl<PersonalityLearning>();
        profile ??= await personalityLearning.getCurrentPersonality(user.id) ??
            await personalityLearning.initializePersonality(user.id);
        await orchestrator.initializeOrchestration(user.id, profile);
      }
    } catch (e) {
      _logger.debug('AuthBloc: AI2AI post-login init skipped: $e',
          tag: 'AuthBloc');
    }
  }

  Future<void> _onUpdatePasswordRequested(
    UpdatePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Capture authenticated state BEFORE emitting AuthLoading
    // (state will be AuthLoading after emit, so we need to capture it first)
    final authState = state is Authenticated ? state as Authenticated : null;

    // Emit loading state FIRST (before any async operations)
    // This ensures blocTest captures the state immediately
    emit(AuthLoading());

    if (authState == null) {
      emit(AuthError('Must be authenticated to change password'));
      return;
    }

    try {
      final userId = authState.user.id;
      _logger.info('🔐 AuthBloc: Updating password for user: $userId',
          tag: 'AuthBloc');

      // Re-encrypt personality profile with new password BEFORE updating password
      // This ensures we can decrypt with old password, then re-encrypt with new
      try {
        final syncService = di.sl<PersonalitySyncService>();
        final syncEnabled = await syncService.isCloudSyncEnabled(userId);

        if (syncEnabled) {
          _logger.info(
            '☁️ AuthBloc: Cloud sync enabled, re-encrypting profile with new password...',
            tag: 'AuthBloc',
          );
          await syncService.reEncryptWithNewPassword(
            userId,
            event.currentPassword,
            event.newPassword,
          );
          _logger.info('✅ AuthBloc: Profile re-encrypted successfully',
              tag: 'AuthBloc');
        }
      } catch (e) {
        // Catch both Exception and Error (like StateError from GetIt)
        _logger.error(
          '❌ AuthBloc: Failed to re-encrypt profile: $e',
          error: e,
          tag: 'AuthBloc',
        );
        // Don't block password update if re-encryption fails
        // User will lose cloud access but can still change password
        _logger.warn(
          '⚠️ AuthBloc: Password will be updated but cloud profile may be inaccessible',
          tag: 'AuthBloc',
        );
      }

      // Update password in auth system
      await updatePasswordUseCase(event.currentPassword, event.newPassword);

      // Update stored password in secure storage
      try {
        const secureStorage = FlutterSecureStorage();
        await secureStorage.write(
          key: 'user_password_session_$userId',
          value: event.newPassword,
        );
        _logger.debug('🔐 AuthBloc: Updated password in secure storage',
            tag: 'AuthBloc');
      } catch (e) {
        // MissingPluginException is expected in unit tests (platform channels not available)
        // Only log at debug level to avoid cluttering test output
        if (e.toString().contains('MissingPluginException')) {
          _logger.debug(
              '🔐 AuthBloc: Secure storage not available (expected in tests): $e',
              tag: 'AuthBloc');
        } else {
          _logger.warn(
              '🔐 AuthBloc: Failed to update password in secure storage: $e',
              tag: 'AuthBloc');
        }
        // Don't block - password is updated in auth system
      }

      _logger.info('✅ AuthBloc: Password updated successfully',
          tag: 'AuthBloc');

      // Re-emit authenticated state (user is still authenticated)
      emit(Authenticated(user: authState.user, isOffline: authState.isOffline));
    } catch (e) {
      // Catch both Exception and Error types
      _logger.error('🔐 AuthBloc: Password update error',
          error: e, tag: 'AuthBloc');
      final errorMessage = e is Error
          ? 'Failed to update password: ${e.toString()}'
          : 'Failed to update password: ${e.toString()}';
      emit(AuthError(errorMessage));
    }
  }
}

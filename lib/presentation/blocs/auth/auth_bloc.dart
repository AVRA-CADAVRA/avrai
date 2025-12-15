import 'package:spots/core/services/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/core/models/user.dart';
import 'package:spots/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:spots/domain/usecases/auth/sign_in_usecase.dart';
import 'package:spots/domain/usecases/auth/sign_out_usecase.dart';
import 'package:spots/domain/usecases/auth/sign_up_usecase.dart';
import 'package:spots/domain/usecases/auth/update_password_usecase.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:spots/core/services/personality_sync_service.dart';
import 'package:spots/core/ai/personality_learning.dart';
import 'package:spots/injection_container.dart' as di;

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

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      _logger.info('🔐 AuthBloc: Attempting sign in for ${event.email}',
          tag: 'AuthBloc');
      final user = await signInUseCase(event.email, event.password);
      _logger.debug(
          '🔐 AuthBloc: Sign in result - user: ${user?.email ?? 'null'}',
          tag: 'AuthBloc');
      if (user != null) {
        final isOffline = user.isOnline == false;
        _logger.info('🔐 AuthBloc: User authenticated successfully',
            tag: 'AuthBloc');

        // Store password temporarily in secure storage for cloud sync operations
        // This is needed for password-derived encryption key generation
        try {
          final secureStorage = const FlutterSecureStorage();
          await secureStorage.write(
            key: 'user_password_session_${user.id}',
            value: event.password,
          );
          _logger.debug(
              '🔐 AuthBloc: Password stored in secure storage for sync',
              tag: 'AuthBloc');
        } catch (e) {
          // MissingPluginException is expected in unit tests (platform channels not available)
          // Only log at debug level to avoid cluttering test output
          if (e.toString().contains('MissingPluginException')) {
            _logger.debug('🔐 AuthBloc: Secure storage not available (expected in tests): $e',
                tag: 'AuthBloc');
          } else {
            _logger.warn('🔐 AuthBloc: Failed to store password for sync: $e',
                tag: 'AuthBloc');
          }
          // Don't block login if password storage fails
        }

        // Attempt to load personality from cloud if sync is enabled
        try {
          final syncService = di.sl<PersonalitySyncService>();
          final syncEnabled = await syncService.isCloudSyncEnabled(user.id);

          if (syncEnabled) {
            _logger.info(
                '☁️ AuthBloc: Cloud sync enabled, initializing personality with cloud load...',
                tag: 'AuthBloc');
            // Initialize personality with password to enable cloud loading
            final personalityLearning = di.sl<PersonalityLearning>();
            await personalityLearning.initializePersonality(user.id,
                password: event.password);
            _logger.info(
                '✅ AuthBloc: Personality initialized (may have loaded from cloud)',
                tag: 'AuthBloc');
          } else {
            // Still initialize personality (local only)
            final personalityLearning = di.sl<PersonalityLearning>();
            await personalityLearning.initializePersonality(user.id);
          }
        } catch (e) {
          _logger.warn('⚠️ AuthBloc: Error loading cloud profile: $e',
              tag: 'AuthBloc');
          // Don't block login if cloud sync fails
        }

        emit(Authenticated(user: user, isOffline: isOffline));
      } else {
        _logger.warn('🔐 AuthBloc: User authentication failed - null user',
            tag: 'AuthBloc');
        emit(AuthError('Invalid credentials'));
      }
    } catch (e) {
      _logger.error('🔐 AuthBloc: Sign in error', error: e, tag: 'AuthBloc');
      emit(AuthError(e.toString()));
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
        emit(AuthError('Failed to create account'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
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
          final secureStorage = const FlutterSecureStorage();
          await secureStorage.delete(
              key: 'user_password_session_${authState.user.id}');
          _logger.debug('🔐 AuthBloc: Password cleared from secure storage',
              tag: 'AuthBloc');
        }
      } catch (e) {
        // MissingPluginException is expected in unit tests (platform channels not available)
        // Only log at debug level to avoid cluttering test output
        if (e.toString().contains('MissingPluginException')) {
          _logger.debug('🔐 AuthBloc: Secure storage not available (expected in tests): $e',
              tag: 'AuthBloc');
        } else {
          _logger.warn('🔐 AuthBloc: Failed to clear password: $e',
              tag: 'AuthBloc');
        }
        // Don't block sign out if password clearing fails
      }

      await signOutUseCase();
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
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(Unauthenticated());
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
        final secureStorage = const FlutterSecureStorage();
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
          _logger.debug('🔐 AuthBloc: Secure storage not available (expected in tests): $e',
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

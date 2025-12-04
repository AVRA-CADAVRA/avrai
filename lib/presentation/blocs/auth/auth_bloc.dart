import 'package:spots/core/services/logger.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/core/models/user.dart';
import 'package:spots/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:spots/domain/usecases/auth/sign_in_usecase.dart';
import 'package:spots/domain/usecases/auth/sign_out_usecase.dart';
import 'package:spots/domain/usecases/auth/sign_up_usecase.dart';

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
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  final SignInUseCase signInUseCase;
  final SignUpUseCase signUpUseCase;
  final SignOutUseCase signOutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;

  AuthBloc({
    required this.signInUseCase,
    required this.signUpUseCase,
    required this.signOutUseCase,
    required this.getCurrentUserUseCase,
  }) : super(AuthInitial()) {
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<AuthCheckRequested>(_onAuthCheckRequested);
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      _logger.info('🔐 AuthBloc: Attempting sign in for ${event.email}', tag: 'AuthBloc');
      final user = await signInUseCase(event.email, event.password);
      _logger.debug('🔐 AuthBloc: Sign in result - user: ${user?.email ?? 'null'}', tag: 'AuthBloc');
      if (user != null) {
        final isOffline = user.isOnline == false;
        _logger.info('🔐 AuthBloc: User authenticated successfully', tag: 'AuthBloc');
        emit(Authenticated(user: user, isOffline: isOffline));
      } else {
        _logger.warn('🔐 AuthBloc: User authentication failed - null user', tag: 'AuthBloc');
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
      await signOutUseCase();
      emit(Unauthenticated());
    } catch (e) {
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
}

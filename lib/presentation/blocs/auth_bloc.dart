import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/repositories/auth_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String nom;
  final String email;
  final String telephone;
  final String password;
  const AuthRegisterRequested({
    required this.nom,
    required this.email,
    required this.telephone,
    required this.password,
  });
  @override
  List<Object?> get props => [nom, email, telephone];
}

class AuthGoogleLoginRequested extends AuthEvent {
  const AuthGoogleLoginRequested();
}

class AuthForgotPasswordRequested extends AuthEvent {
  final String email;
  const AuthForgotPasswordRequested({required this.email});
  @override
  List<Object?> get props => [email];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class _AuthUserChanged extends AuthEvent {
  final AppUser? user;
  const _AuthUserChanged(this.user);
  @override
  List<Object?> get props => [user];
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final AppUser user;
  const AuthAuthenticated({required this.user});
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthPasswordResetSent extends AuthState {
  final String email;
  const AuthPasswordResetSent({required this.email});
  @override
  List<Object?> get props => [email];
}

class AuthError extends AuthState {
  final String message;
  const AuthError({required this.message});
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<AppUser?>? _authSubscription;

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthGoogleLoginRequested>(_onGoogleLogin);
    on<AuthForgotPasswordRequested>(_onForgotPassword);
    on<AuthLogoutRequested>(_onLogout);
    on<_AuthUserChanged>(_onUserChanged);
  }

  // ── AuthStarted — subscribe to Firebase auth state stream ─────────────────

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    // Cancel any previous subscription
    await _authSubscription?.cancel();

    // Listen to Firebase auth state and forward changes as BLoC events
    _authSubscription = _authRepository.authStateChanges.listen(
      (user) => add(_AuthUserChanged(user)),
      onError: (_) => add(const _AuthUserChanged(null)),
    );
  }

  // ── Internal auth state change forwarded from stream ─────────────────────

  void _onUserChanged(_AuthUserChanged event, Emitter<AuthState> emit) {
    if (event.user != null) {
      emit(AuthAuthenticated(user: event.user!));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  // ── Login with email ──────────────────────────────────────────────────────

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.loginWithEmail(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user: user));
    } on AuthFailure catch (f) {
      emit(AuthError(message: f.message));
    } on ServerFailure catch (f) {
      emit(AuthError(message: f.message));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.registerWithEmail(
        name: event.nom,
        email: event.email,
        phone: event.telephone,
        password: event.password,
      );
      emit(AuthAuthenticated(user: user));
    } on AuthFailure catch (f) {
      emit(AuthError(message: f.message));
    } on ServerFailure catch (f) {
      emit(AuthError(message: f.message));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  // ── Google sign-in ────────────────────────────────────────────────────────

  Future<void> _onGoogleLogin(
    AuthGoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.loginWithGoogle();
      emit(AuthAuthenticated(user: user));
    } on AuthFailure catch (f) {
      emit(AuthError(message: f.message));
    } on ServerFailure catch (f) {
      emit(AuthError(message: f.message));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  // ── Forgot password ───────────────────────────────────────────────────────

  Future<void> _onForgotPassword(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.sendPasswordResetEmail(email: event.email);
      emit(AuthPasswordResetSent(email: event.email));
    } on AuthFailure catch (f) {
      emit(AuthError(message: f.message));
    } on ServerFailure catch (f) {
      emit(AuthError(message: f.message));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.logout();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}

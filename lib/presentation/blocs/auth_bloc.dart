import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/driver_credentials.dart';
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

class AuthRegisterPassengerRequested extends AuthEvent {
  final String name, email, phone, password;
  const AuthRegisterPassengerRequested({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
  });
  @override
  List<Object?> get props => [name, email, phone];
}

class AuthRegisterDriverStep1Requested extends AuthEvent {
  final String name, email, phone, password;
  const AuthRegisterDriverStep1Requested({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
  });
  @override
  List<Object?> get props => [name, email, phone];
}

class AuthSubmitDriverCredentials extends AuthEvent {
  final DriverCredentials credentials;
  const AuthSubmitDriverCredentials(this.credentials);
  @override
  List<Object?> get props => [credentials];
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

/// Driver completed step 1 — needs to submit credentials (step 2).
class AuthDriverStep1Complete extends AuthState {
  final AppUser user;
  const AuthDriverStep1Complete({required this.user});
  @override
  List<Object?> get props => [user];
}

/// Driver credentials submitted — verification is now pending.
class AuthDriverCredentialsSubmitted extends AuthState {
  const AuthDriverCredentialsSubmitted();
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
  StreamSubscription<AppUser?>? _authSub;

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterPassengerRequested>(_onRegisterPassenger);
    on<AuthRegisterDriverStep1Requested>(_onRegisterDriverStep1);
    on<AuthSubmitDriverCredentials>(_onSubmitCredentials);
    on<AuthGoogleLoginRequested>(_onGoogleLogin);
    on<AuthForgotPasswordRequested>(_onForgotPassword);
    on<AuthLogoutRequested>(_onLogout);
    on<_AuthUserChanged>(_onUserChanged);
  }

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    await _authSub?.cancel();
    _authSub = _authRepository.authStateChanges.listen(
      (user) => add(_AuthUserChanged(user)),
      onError: (_) => add(const _AuthUserChanged(null)),
    );
  }

  void _onUserChanged(_AuthUserChanged event, Emitter<AuthState> emit) {
    if (event.user != null) {
      emit(AuthAuthenticated(user: event.user!));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

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

  Future<void> _onRegisterPassenger(
    AuthRegisterPassengerRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.registerPassenger(
        name: event.name,
        email: event.email,
        phone: event.phone,
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

  Future<void> _onRegisterDriverStep1(
    AuthRegisterDriverStep1Requested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.registerDriver(
        name: event.name,
        email: event.email,
        phone: event.phone,
        password: event.password,
      );
      // Don't fully authenticate — navigate to credentials step
      emit(AuthDriverStep1Complete(user: user));
    } on AuthFailure catch (f) {
      emit(AuthError(message: f.message));
    } on ServerFailure catch (f) {
      emit(AuthError(message: f.message));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onSubmitCredentials(
    AuthSubmitDriverCredentials event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.submitDriverCredentials(event.credentials);
      emit(const AuthDriverCredentialsSubmitted());
    } on ServerFailure catch (f) {
      emit(AuthError(message: f.message));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

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
    _authSub?.cancel();
    return super.close();
  }
}

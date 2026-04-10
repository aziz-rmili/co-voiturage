import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/repositories/auth_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class ProfileLoadRequested extends ProfileEvent {
  const ProfileLoadRequested();
}

class ProfileLogoutRequested extends ProfileEvent {
  const ProfileLogoutRequested();
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final AppUser user;
  final double co2SavedKg;
  final double distanceSharedKm;

  const ProfileLoaded({
    required this.user,
    required this.co2SavedKg,
    required this.distanceSharedKm,
  });

  @override
  List<Object?> get props => [user, co2SavedKg, distanceSharedKm];
}

class ProfileLoggedOut extends ProfileState {}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final AuthRepository _authRepository;

  ProfileBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(ProfileInitial()) {
    on<ProfileLoadRequested>(_onLoad);
    on<ProfileLogoutRequested>(_onLogout);
  }

  Future<void> _onLoad(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      final user = await _authRepository.getCurrentUser();
      if (user == null) {
        emit(ProfileLoggedOut());
        return;
      }
      emit(
        ProfileLoaded(
          user: user,
          co2SavedKg: user.co2SavedKg,
          distanceSharedKm: user.distanceSharedKm,
        ),
      );
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onLogout(
    ProfileLogoutRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      await _authRepository.logout();
      emit(ProfileLoggedOut());
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}

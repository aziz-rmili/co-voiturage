import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/ride.dart';
import '../../../domain/repositories/ride_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class TripDetailEvent extends Equatable {
  const TripDetailEvent();
  @override
  List<Object?> get props => [];
}

class TripDetailLoadRequested extends TripDetailEvent {
  final String rideId;
  const TripDetailLoadRequested(this.rideId);
  @override
  List<Object?> get props => [rideId];
}

class TripDetailBookRequested extends TripDetailEvent {
  final String userId;
  const TripDetailBookRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class TripDetailState extends Equatable {
  const TripDetailState();
  @override
  List<Object?> get props => [];
}

class TripDetailInitial extends TripDetailState {}

class TripDetailLoading extends TripDetailState {}

class TripDetailLoaded extends TripDetailState {
  final Ride ride;
  final AppUser? driver;
  final bool isBooked;
  final bool isBooking;

  const TripDetailLoaded({
    required this.ride,
    this.driver,
    this.isBooked = false,
    this.isBooking = false,
  });

  TripDetailLoaded copyWith({
    Ride? ride,
    AppUser? driver,
    bool? isBooked,
    bool? isBooking,
  }) => TripDetailLoaded(
    ride: ride ?? this.ride,
    driver: driver ?? this.driver,
    isBooked: isBooked ?? this.isBooked,
    isBooking: isBooking ?? this.isBooking,
  );

  @override
  List<Object?> get props => [ride, driver, isBooked, isBooking];
}

class TripDetailBooked extends TripDetailState {
  final Ride ride;
  const TripDetailBooked(this.ride);
  @override
  List<Object?> get props => [ride];
}

class TripDetailError extends TripDetailState {
  final String message;
  const TripDetailError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

class TripDetailBloc extends Bloc<TripDetailEvent, TripDetailState> {
  final RideRepository _rideRepository;

  TripDetailBloc({required RideRepository rideRepository})
    : _rideRepository = rideRepository,
      super(TripDetailInitial()) {
    on<TripDetailLoadRequested>(_onLoad);
    on<TripDetailBookRequested>(_onBook);
  }

  Future<void> _onLoad(
    TripDetailLoadRequested event,
    Emitter<TripDetailState> emit,
  ) async {
    emit(TripDetailLoading());
    try {
      final ride = await _rideRepository.getRideById(event.rideId);
      if (ride == null) {
        emit(const TripDetailError('Ride not found.'));
        return;
      }
      emit(TripDetailLoaded(ride: ride));
    } catch (e) {
      emit(TripDetailError(e.toString()));
    }
  }

  Future<void> _onBook(
    TripDetailBookRequested event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded) return;
    final current = state as TripDetailLoaded;
    emit(current.copyWith(isBooking: true));
    try {
      await _rideRepository.bookRide(
        rideId: current.ride.id,
        userId: event.userId,
      );
      emit(TripDetailBooked(current.ride));
    } catch (e) {
      emit(TripDetailError(e.toString()));
    }
  }
}

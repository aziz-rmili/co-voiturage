import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/exceptions.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/ride.dart';
import '../../../domain/repositories/ride_repository.dart';
import '../../../domain/repositories/user_repository.dart';

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

/// Passenger requests a booking — status becomes Pending until driver confirms.
class TripDetailBookRequested extends TripDetailEvent {
  final String userId;
  const TripDetailBookRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

/// Driver confirms a pending passenger.
class TripDetailConfirmPassenger extends TripDetailEvent {
  final String passengerId;
  const TripDetailConfirmPassenger(this.passengerId);
  @override
  List<Object?> get props => [passengerId];
}

/// Driver rejects a pending passenger.
class TripDetailRejectPassenger extends TripDetailEvent {
  final String passengerId;
  const TripDetailRejectPassenger(this.passengerId);
  @override
  List<Object?> get props => [passengerId];
}

/// Cancel booking (passenger cancels, or driver rejects).
class TripDetailCancelBooking extends TripDetailEvent {
  final String userId;
  const TripDetailCancelBooking(this.userId);
  @override
  List<Object?> get props => [userId];
}

class TripDetailSubmitReportRequested extends TripDetailEvent {
  final String rideId;
  final String reporterId;
  final String driverId;
  final String reason;
  final String? details;

  const TripDetailSubmitReportRequested({
    required this.rideId,
    required this.reporterId,
    required this.driverId,
    required this.reason,
    this.details,
  });

  @override
  List<Object?> get props => [rideId, reporterId, driverId, reason, details];
}

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
  final bool isBooking;
  final bool isReporting;
  final String? message;

  /// Whether the current user has a pending booking request.
  final bool hasPendingBooking;

  /// Whether the current user is already confirmed.
  final bool isConfirmed;

  const TripDetailLoaded({
    required this.ride,
    this.driver,
    this.isBooking = false,
    this.isReporting = false,
    this.hasPendingBooking = false,
    this.isConfirmed = false,
    this.message,
  });

  TripDetailLoaded copyWith({
    Ride? ride,
    AppUser? driver,
    bool? isBooking,
    bool? isReporting,
    String? message,
    bool? hasPendingBooking,
    bool? isConfirmed,
  }) => TripDetailLoaded(
    ride: ride ?? this.ride,
    driver: driver ?? this.driver,
    isBooking: isBooking ?? this.isBooking,
    isReporting: isReporting ?? this.isReporting,
    hasPendingBooking: hasPendingBooking ?? this.hasPendingBooking,
    isConfirmed: isConfirmed ?? this.isConfirmed,
    message: message ?? this.message,
  );

  @override
  List<Object?> get props => [
    ride,
    driver,
    isBooking,
    isReporting,
    message,
    hasPendingBooking,
    isConfirmed,
  ];
}

class TripDetailBookingRequested extends TripDetailState {
  const TripDetailBookingRequested();
}

class TripDetailError extends TripDetailState {
  final String message;
  const TripDetailError(this.message);
  @override
  List<Object?> get props => [message];
}

class TripDetailBloc extends Bloc<TripDetailEvent, TripDetailState> {
  final RideRepository _rideRepository;
  final UserRepository _userRepository;

  TripDetailBloc({
    required RideRepository rideRepository,
    required UserRepository userRepository,
  }) : _rideRepository = rideRepository,
       _userRepository = userRepository,
       super(TripDetailInitial()) {
    on<TripDetailLoadRequested>(_onLoad);
    on<TripDetailBookRequested>(_onBook);
    on<TripDetailConfirmPassenger>(_onConfirm);
    on<TripDetailRejectPassenger>(_onReject);
    on<TripDetailCancelBooking>(_onCancel);
    on<TripDetailSubmitReportRequested>(_onReport);
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
      final driver = await _userRepository.getUserById(ride.driverId);
      emit(TripDetailLoaded(ride: ride, driver: driver));
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
      await _rideRepository.requestBooking(
        rideId: current.ride.id,
        userId: event.userId,
      );
      // Reload ride to get updated passenger lists
      final updated = await _rideRepository.getRideById(current.ride.id);
      emit(
        TripDetailLoaded(
          ride: updated ?? current.ride,
          driver: current.driver,
          hasPendingBooking: true,
          isConfirmed: false,
        ),
      );
    } catch (e) {
      emit(TripDetailError(e.toString()));
    }
  }

  Future<void> _onConfirm(
    TripDetailConfirmPassenger event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded) return;
    final current = state as TripDetailLoaded;
    try {
      await _rideRepository.confirmPassenger(
        rideId: current.ride.id,
        passengerId: event.passengerId,
      );
      final updated = await _rideRepository.getRideById(current.ride.id);
      emit(current.copyWith(ride: updated ?? current.ride));
    } catch (e) {
      emit(TripDetailError(e.toString()));
    }
  }

  Future<void> _onReject(
    TripDetailRejectPassenger event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded) return;
    final current = state as TripDetailLoaded;
    try {
      await _rideRepository.rejectPassenger(
        rideId: current.ride.id,
        passengerId: event.passengerId,
      );
      final updated = await _rideRepository.getRideById(current.ride.id);
      emit(current.copyWith(ride: updated ?? current.ride));
    } catch (e) {
      emit(TripDetailError(e.toString()));
    }
  }

  Future<void> _onCancel(
    TripDetailCancelBooking event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded) return;
    final current = state as TripDetailLoaded;
    try {
      await _rideRepository.cancelBooking(
        rideId: current.ride.id,
        userId: event.userId,
      );
      final updated = await _rideRepository.getRideById(current.ride.id);
      emit(
        TripDetailLoaded(
          ride: updated ?? current.ride,
          driver: current.driver,
          hasPendingBooking: false,
          isConfirmed: false,
        ),
      );
    } catch (e) {
      emit(TripDetailError(e.toString()));
    }
  }

  Future<void> _onReport(
    TripDetailSubmitReportRequested event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded) return;
    final current = state as TripDetailLoaded;
    emit(current.copyWith(isReporting: true, message: null));

    try {
      await _rideRepository.reportRide(
        rideId: event.rideId,
        reporterId: event.reporterId,
        driverId: event.driverId,
        reason: event.reason,
        details: event.details,
      );
      final updated = await _rideRepository.getRideById(event.rideId);
      emit(
        current.copyWith(
          ride: updated ?? current.ride,
          isReporting: false,
          message: 'Trip reported successfully.',
        ),
      );
    } catch (e) {
      final errorMessage = e is ServerException
          ? e.message
          : 'You\'ve already submitted a report for this trip.';
      emit(current.copyWith(isReporting: false, message: errorMessage));
    }
  }
}

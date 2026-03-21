import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/ride.dart';
import '../../../domain/repositories/ride_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class TripsEvent extends Equatable {
  const TripsEvent();
  @override
  List<Object?> get props => [];
}

class TripsLoadRequested extends TripsEvent {
  final String userId;
  const TripsLoadRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

class TripsTabChanged extends TripsEvent {
  final int tabIndex; // 0 = upcoming, 1 = past
  const TripsTabChanged(this.tabIndex);
  @override
  List<Object?> get props => [tabIndex];
}

class TripCancelRequested extends TripsEvent {
  final String rideId;
  final bool isDriver;
  const TripCancelRequested({required this.rideId, required this.isDriver});
  @override
  List<Object?> get props => [rideId, isDriver];
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class TripsState extends Equatable {
  const TripsState();
  @override
  List<Object?> get props => [];
}

class TripsInitial extends TripsState {}

class TripsLoading extends TripsState {}

class TripsLoaded extends TripsState {
  final List<Ride> upcomingRides;
  final List<Ride> pastRides;
  final int activeTab;
  final double totalCo2SavedKg;

  const TripsLoaded({
    required this.upcomingRides,
    required this.pastRides,
    this.activeTab = 0,
    required this.totalCo2SavedKg,
  });

  List<Ride> get activeRides => activeTab == 0 ? upcomingRides : pastRides;

  TripsLoaded copyWith({
    List<Ride>? upcomingRides,
    List<Ride>? pastRides,
    int? activeTab,
    double? totalCo2SavedKg,
  }) => TripsLoaded(
    upcomingRides: upcomingRides ?? this.upcomingRides,
    pastRides: pastRides ?? this.pastRides,
    activeTab: activeTab ?? this.activeTab,
    totalCo2SavedKg: totalCo2SavedKg ?? this.totalCo2SavedKg,
  );

  @override
  List<Object?> get props => [
    upcomingRides,
    pastRides,
    activeTab,
    totalCo2SavedKg,
  ];
}

class TripsError extends TripsState {
  final String message;
  const TripsError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

class TripsBloc extends Bloc<TripsEvent, TripsState> {
  final RideRepository _rideRepository;

  TripsBloc({required RideRepository rideRepository})
    : _rideRepository = rideRepository,
      super(TripsInitial()) {
    on<TripsLoadRequested>(_onLoad);
    on<TripsTabChanged>(_onTabChanged);
    on<TripCancelRequested>(_onCancel);
  }

  Future<void> _onLoad(
    TripsLoadRequested event,
    Emitter<TripsState> emit,
  ) async {
    emit(TripsLoading());
    await emit.forEach(
      _rideRepository.getUserRides(event.userId),
      onData: (rides) {
        final now = DateTime.now();
        final upcoming =
            rides
                .where(
                  (r) =>
                      r.dateHour.isAfter(now) &&
                      r.status != RideStatus.cancelled &&
                      r.status != RideStatus.completed,
                )
                .toList()
              ..sort((a, b) => a.dateHour.compareTo(b.dateHour));

        final past =
            rides
                .where(
                  (r) =>
                      r.dateHour.isBefore(now) ||
                      r.status == RideStatus.completed ||
                      r.status == RideStatus.cancelled,
                )
                .toList()
              ..sort((a, b) => b.dateHour.compareTo(a.dateHour));

        // ~2.4 kg CO2 saved per carpooled trip (rough estimate)
        final co2 = past.length * 2.4;
        final tab = state is TripsLoaded ? (state as TripsLoaded).activeTab : 0;

        return TripsLoaded(
          upcomingRides: upcoming,
          pastRides: past,
          activeTab: tab,
          totalCo2SavedKg: co2,
        );
      },
      onError: (e, _) => TripsError(e.toString()),
    );
  }

  void _onTabChanged(TripsTabChanged event, Emitter<TripsState> emit) {
    if (state is TripsLoaded) {
      emit((state as TripsLoaded).copyWith(activeTab: event.tabIndex));
    }
  }

  Future<void> _onCancel(
    TripCancelRequested event,
    Emitter<TripsState> emit,
  ) async {
    try {
      if (event.isDriver) {
        await _rideRepository.cancelRide(event.rideId);
      } else {
        // passenger cancels booking — userId resolved upstream
        await _rideRepository.cancelRide(event.rideId);
      }
    } catch (e) {
      emit(TripsError(e.toString()));
    }
  }
}

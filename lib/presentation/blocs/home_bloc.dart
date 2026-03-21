import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/ride.dart';
import '../../../domain/repositories/ride_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object?> get props => [];
}

class HomeLoadRequested extends HomeEvent {
  final double userLat;
  final double userLng;
  const HomeLoadRequested({required this.userLat, required this.userLng});
  @override
  List<Object?> get props => [userLat, userLng];
}

class HomeSearchChanged extends HomeEvent {
  final String query;
  const HomeSearchChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class HomeDateFilterChanged extends HomeEvent {
  final String filter; // 'today' | 'tomorrow' | 'group'
  const HomeDateFilterChanged(this.filter);
  @override
  List<Object?> get props => [filter];
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<Ride> popularRides;
  final double co2SavedKg;
  final int activeTrips;
  final String dateFilter;
  final String searchQuery;

  const HomeLoaded({
    required this.popularRides,
    required this.co2SavedKg,
    required this.activeTrips,
    this.dateFilter = 'today',
    this.searchQuery = '',
  });

  HomeLoaded copyWith({
    List<Ride>? popularRides,
    double? co2SavedKg,
    int? activeTrips,
    String? dateFilter,
    String? searchQuery,
  }) => HomeLoaded(
    popularRides: popularRides ?? this.popularRides,
    co2SavedKg: co2SavedKg ?? this.co2SavedKg,
    activeTrips: activeTrips ?? this.activeTrips,
    dateFilter: dateFilter ?? this.dateFilter,
    searchQuery: searchQuery ?? this.searchQuery,
  );

  @override
  List<Object?> get props => [
    popularRides,
    co2SavedKg,
    activeTrips,
    dateFilter,
    searchQuery,
  ];
}

class HomeError extends HomeState {
  final String message;
  const HomeError({required this.message});
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final RideRepository _rideRepository;

  HomeBloc({required RideRepository rideRepository})
    : _rideRepository = rideRepository,
      super(HomeInitial()) {
    on<HomeLoadRequested>(_onLoad);
    on<HomeSearchChanged>(_onSearchChanged);
    on<HomeDateFilterChanged>(_onFilterChanged);
  }

  Future<void> _onLoad(HomeLoadRequested event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    try {
      // Listen to nearby rides stream
      await emit.forEach(
        _rideRepository.getNearbyRides(
          location: GeoPoint(event.userLat, event.userLng),
          radiusKm: 50,
        ),
        onData: (rides) {
          final scheduled = rides
              .where((r) => r.status == RideStatus.scheduled)
              .toList();

          final co2Saved = scheduled
              .map((r) => r.effectiveCo2SavedKg)
              .fold<double>(0.0, (prev, element) => prev + element);

          return HomeLoaded(
            popularRides: scheduled.take(5).toList(),
            co2SavedKg: double.parse(co2Saved.toStringAsFixed(1)),
            activeTrips: scheduled.length,
          );
        },
        onError: (e, _) => HomeError(message: e.toString()),
      );
    } catch (e) {
      emit(HomeError(message: e.toString()));
    }
  }

  void _onSearchChanged(HomeSearchChanged event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      emit((state as HomeLoaded).copyWith(searchQuery: event.query));
    }
  }

  void _onFilterChanged(HomeDateFilterChanged event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      emit((state as HomeLoaded).copyWith(dateFilter: event.filter));
    }
  }
}

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/ride.dart';
import '../../../domain/repositories/ride_repository.dart';
import '../../../domain/repositories/user_repository.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object?> get props => [];
}

class HomeLoadRequested extends HomeEvent {
  final double userLat;
  final double userLng;
  final String userId;
  const HomeLoadRequested({
    required this.userLat,
    required this.userLng,
    required this.userId,
  });
  @override
  List<Object?> get props => [userLat, userLng, userId];
}

class HomeSearchChanged extends HomeEvent {
  final String query;
  const HomeSearchChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class HomeDateFilterChanged extends HomeEvent {
  /// 'today' | 'tomorrow' | 'group'
  final String filter;
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
  /// All scheduled rides from Firestore (unfiltered).
  final List<Ride> allRides;

  /// Driver lookup map populated asynchronously.
  final Map<String, AppUser> drivers;

  /// CO2 saved by the current user across all their completed rides.
  final double co2SavedKg;

  /// Number of currently scheduled (active) rides in the system.
  final int activeTrips;
  final String dateFilter;
  final String searchQuery;

  const HomeLoaded({
    required this.allRides,
    required this.drivers,
    required this.co2SavedKg,
    required this.activeTrips,
    this.dateFilter = 'today',
    this.searchQuery = '',
  });

  /// Rides filtered by [searchQuery] (arrival address) AND [dateFilter] date.
  List<Ride> get filteredRides {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return allRides.where((r) {
      // ── Arrival address search
      if (searchQuery.isNotEmpty) {
        final addr = r.arrivalAddress.toLowerCase();
        if (!addr.contains(searchQuery.toLowerCase())) return false;
      }

      // ── Date filter
      final rideDay = DateTime(
        r.dateHour.year,
        r.dateHour.month,
        r.dateHour.day,
      );
      switch (dateFilter) {
        case 'all':
          return true; // no date restriction
        case 'today':
          return rideDay.isAtSameMomentAs(today);
        case 'tomorrow':
          return rideDay.isAtSameMomentAs(tomorrow);
        case 'group':
          return r.passengersIds.length >= 2;
        default:
          return true;
      }
    }).toList();
  }

  HomeLoaded copyWith({
    List<Ride>? allRides,
    Map<String, AppUser>? drivers,
    double? co2SavedKg,
    int? activeTrips,
    String? dateFilter,
    String? searchQuery,
  }) => HomeLoaded(
    allRides: allRides ?? this.allRides,
    drivers: drivers ?? this.drivers,
    co2SavedKg: co2SavedKg ?? this.co2SavedKg,
    activeTrips: activeTrips ?? this.activeTrips,
    dateFilter: dateFilter ?? this.dateFilter,
    searchQuery: searchQuery ?? this.searchQuery,
  );

  @override
  List<Object?> get props => [
    allRides,
    drivers,
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
  final UserRepository _userRepository;
  StreamSubscription<List<Ride>>? _userRideSub;
  String _currentUserId = '';

  HomeBloc({
    required RideRepository rideRepository,
    required UserRepository userRepository,
  }) : _rideRepository = rideRepository,
       _userRepository = userRepository,
       super(HomeInitial()) {
    on<HomeLoadRequested>(_onLoad);
    on<HomeSearchChanged>(_onSearchChanged);
    on<HomeDateFilterChanged>(_onFilterChanged);
  }

  Future<void> _onLoad(HomeLoadRequested event, Emitter<HomeState> emit) async {
    _currentUserId = event.userId;
    emit(HomeLoading());

    // Subscribe to user's own rides to compute real CO2 saved
    await _userRideSub?.cancel();
    _userRideSub = _rideRepository.getUserRides(event.userId).listen((
      userRides,
    ) {
      final completedRides = userRides
          .where((r) => r.status == RideStatus.completed)
          .toList();
      // Each completed ride saves ≈ 2.4 kg CO2 per seat carpooled
      final co2 = completedRides.fold<double>(
        0,
        (sum, r) => sum + (r.availableSeats * 2.4),
      );
      if (state is HomeLoaded) {
        emit((state as HomeLoaded).copyWith(co2SavedKg: co2));
      }
    });

    try {
      await emit.forEach(
        _rideRepository.getNearbyRides(
          location: GeoPoint(event.userLat, event.userLng),
          radiusKm: 200, // Wide radius for Tunisia-scale dataset
        ),
        onData: (rides) {
          final scheduled =
              rides.where((r) => r.status == RideStatus.scheduled).toList()
                ..sort((a, b) => a.dateHour.compareTo(b.dateHour));

          // Fetch drivers async — won't block the stream
          _fetchDrivers(scheduled);

          final prev = state is HomeLoaded ? (state as HomeLoaded) : null;
          return HomeLoaded(
            allRides: scheduled,
            drivers: prev?.drivers ?? {},
            co2SavedKg: prev?.co2SavedKg ?? 0.0,
            activeTrips: scheduled.length,
            dateFilter: prev?.dateFilter ?? 'all',
            searchQuery: prev?.searchQuery ?? '',
          );
        },
        onError: (e, _) => HomeError(message: e.toString()),
      );
    } catch (e) {
      emit(HomeError(message: e.toString()));
    }
  }

  Future<void> _fetchDrivers(List<Ride> rides) async {
    final ids = rides.map((r) => r.driverId).toSet().toList();
    if (ids.isEmpty) return;
    try {
      final users = await _userRepository.getUsersByIds(ids);
      final map = {for (final u in users) u.uid: u};
      if (state is HomeLoaded) {
        emit((state as HomeLoaded).copyWith(drivers: map));
      }
    } catch (_) {}
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

  @override
  Future<void> close() {
    _userRideSub?.cancel();
    return super.close();
  }
}

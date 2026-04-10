import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../domain/entities/driver_location.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/ride.dart';
import '../../../domain/repositories/map_repository.dart';
import '../../../domain/repositories/ride_repository.dart';
import '../../../domain/repositories/user_repository.dart';

/// Default search radius (km) when opening the map.
const double kDefaultMapRadiusKm = 10.0;

// ── Events ────────────────────────────────────────────────────────────────────

abstract class MapEvent extends Equatable {
  const MapEvent();
  @override
  List<Object?> get props => [];
}

class MapInitialized extends MapEvent {
  const MapInitialized();
}

class MapLocationUpdated extends MapEvent {
  final double lat;
  final double lng;
  const MapLocationUpdated({required this.lat, required this.lng});
  @override
  List<Object?> get props => [lat, lng];
}

class MapDriverSelected extends MapEvent {
  final DriverLocation driver;
  const MapDriverSelected(this.driver);
  @override
  List<Object?> get props => [driver];
}

class MapDriverDeselected extends MapEvent {
  const MapDriverDeselected();
}

class MapFetchRoute extends MapEvent {
  final DriverLocation driver;
  const MapFetchRoute(this.driver);
  @override
  List<Object?> get props => [driver];
}

class MapRideSelected extends MapEvent {
  final Ride ride;
  const MapRideSelected(this.ride);
  @override
  List<Object?> get props => [ride];
}

class MapSearchChanged extends MapEvent {
  final String query;
  const MapSearchChanged(this.query);
  @override
  List<Object?> get props => [query];
}

/// User-adjustable map filters (default radius 10 km).
class MapFiltersChanged extends MapEvent {
  final MapFilter filter;
  const MapFiltersChanged(this.filter);
  @override
  List<Object?> get props => [filter];
}

/// Filter for nearby trips: radius, optional preference tags, optional max price.
class MapFilter extends Equatable {
  /// Search radius in km (default 10).
  final double radiusKm;

  /// Ride must include every tag (e.g. no_smoking). Empty = no preference filter.
  final Set<String> requiredPreferenceTags;

  /// Only rides with price ≤ this. Null = no limit.
  final double? maxPricePerSeat;

  const MapFilter({
    this.radiusKm = kDefaultMapRadiusKm,
    this.requiredPreferenceTags = const {},
    this.maxPricePerSeat,
  });

  MapFilter copyWith({
    double? radiusKm,
    Set<String>? requiredPreferenceTags,
    double? maxPricePerSeat,
    bool clearMaxPrice = false,
  }) {
    return MapFilter(
      radiusKm: radiusKm ?? this.radiusKm,
      requiredPreferenceTags:
          requiredPreferenceTags ?? this.requiredPreferenceTags,
      maxPricePerSeat: clearMaxPrice ? null : (maxPricePerSeat ?? this.maxPricePerSeat),
    );
  }

  static const MapFilter defaults = MapFilter();

  @override
  List<Object?> get props => [radiusKm, requiredPreferenceTags, maxPricePerSeat];
}

class _DriversUpdated extends MapEvent {
  final List<DriverLocation> drivers;
  const _DriversUpdated(this.drivers);
  @override
  List<Object?> get props => [drivers];
}

class _RidesUpdated extends MapEvent {
  final List<Ride> rides;
  const _RidesUpdated(this.rides);
  @override
  List<Object?> get props => [rides];
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class MapState extends Equatable {
  const MapState();
  @override
  List<Object?> get props => [];
}

class MapInitial extends MapState {}

class MapLoading extends MapState {}

class MapPermissionDenied extends MapState {}

class MapLoaded extends MapState {
  final double userLat;
  final double userLng;
  final List<DriverLocation> nearbyDrivers;
  final List<Ride> nearbyRides; // rides within radius + matching filter prefs/price
  final Map<String, AppUser> driverProfiles;
  final DriverLocation? selectedDriver;
  final String? selectedRideId;
  final List<List<double>> routePolyline;
  final String searchQuery;
  final MapFilter mapFilter;

  const MapLoaded({
    required this.userLat,
    required this.userLng,
    required this.nearbyDrivers,
    required this.nearbyRides,
    this.driverProfiles = const {},
    this.selectedDriver,
    this.selectedRideId,
    this.routePolyline = const [],
    this.searchQuery = '',
    this.mapFilter = MapFilter.defaults,
  });

  /// Rides filtered by search query on arrivalAddress.
  List<Ride> get filteredRides {
    if (searchQuery.isEmpty) return nearbyRides;
    final q = searchQuery.toLowerCase();
    return nearbyRides
        .where(
          (r) =>
              r.arrivalAddress.toLowerCase().contains(q) ||
              r.departureAddress.toLowerCase().contains(q),
        )
        .toList();
  }

  MapLoaded copyWith({
    double? userLat,
    double? userLng,
    List<DriverLocation>? nearbyDrivers,
    List<Ride>? nearbyRides,
    Map<String, AppUser>? driverProfiles,
    DriverLocation? selectedDriver,
    String? selectedRideId,
    List<List<double>>? routePolyline,
    String? searchQuery,
    MapFilter? mapFilter,
    bool clearSelected = false,
  }) => MapLoaded(
    userLat: userLat ?? this.userLat,
    userLng: userLng ?? this.userLng,
    nearbyDrivers: nearbyDrivers ?? this.nearbyDrivers,
    nearbyRides: nearbyRides ?? this.nearbyRides,
    driverProfiles: driverProfiles ?? this.driverProfiles,
    selectedDriver: clearSelected
        ? null
        : selectedDriver ?? this.selectedDriver,
    selectedRideId: clearSelected
        ? null
        : selectedRideId ?? this.selectedRideId,
    routePolyline: clearSelected ? [] : routePolyline ?? this.routePolyline,
    searchQuery: searchQuery ?? this.searchQuery,
    mapFilter: mapFilter ?? this.mapFilter,
  );

  @override
  List<Object?> get props => [
    userLat,
    userLng,
    nearbyDrivers,
    nearbyRides,
    driverProfiles,
    selectedDriver,
    selectedRideId,
    routePolyline,
    searchQuery,
    mapFilter,
  ];
}

class MapError extends MapState {
  final String message;
  const MapError({required this.message});
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

class MapBloc extends Bloc<MapEvent, MapState> {
  final MapRepository _mapRepository;
  final RideRepository _rideRepository;
  final UserRepository _userRepository;

  StreamSubscription<List<DriverLocation>>? _driverSub;
  StreamSubscription<List<Ride>>? _rideSub;

  static const double _defaultLat = 36.8065;
  static const double _defaultLng = 10.1815;

  MapBloc({
    required MapRepository mapRepository,
    required RideRepository rideRepository,
    required UserRepository userRepository,
  }) : _mapRepository = mapRepository,
       _rideRepository = rideRepository,
       _userRepository = userRepository,
       super(MapInitial()) {
    on<MapInitialized>(_onInitialized);
    on<MapLocationUpdated>(_onLocationUpdated);
    on<MapDriverSelected>(_onDriverSelected);
    on<MapDriverDeselected>(_onDriverDeselected);
    on<MapFetchRoute>(_onFetchRoute);
    on<MapRideSelected>(_onRideSelected);
    on<MapSearchChanged>(_onSearchChanged);
    on<MapFiltersChanged>(_onFiltersChanged);
    on<_DriversUpdated>(_onDriversUpdated);
    on<_RidesUpdated>(_onRidesUpdated);
  }

  Future<void> _onInitialized(
    MapInitialized event,
    Emitter<MapState> emit,
  ) async {
    emit(MapLoading());
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(const MapError(message: 'Location service is disabled.'));
        add(const MapLocationUpdated(lat: _defaultLat, lng: _defaultLng));
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        emit(MapPermissionDenied());
        add(const MapLocationUpdated(lat: _defaultLat, lng: _defaultLng));
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      add(MapLocationUpdated(lat: pos.latitude, lng: pos.longitude));
    } catch (_) {
      add(const MapLocationUpdated(lat: _defaultLat, lng: _defaultLng));
    }
  }

  /// Subscribes to both streams in parallel using plain listeners that
  /// dispatch internal events — avoids the blocking emit.forEach pattern.
  Future<void> _onLocationUpdated(
    MapLocationUpdated event,
    Emitter<MapState> emit,
  ) async {
    MapFilter filter = MapFilter.defaults;
    if (state is MapLoaded) {
      filter = (state as MapLoaded).mapFilter;
    }

    await _driverSub?.cancel();
    await _rideSub?.cancel();

    emit(
      MapLoaded(
        userLat: event.lat,
        userLng: event.lng,
        nearbyDrivers: const [],
        nearbyRides: const [],
        mapFilter: filter,
      ),
    );

    await _subscribeStreams(event.lat, event.lng, filter);
  }

  Future<void> _subscribeStreams(
    double lat,
    double lng,
    MapFilter filter,
  ) async {
    await _driverSub?.cancel();
    await _rideSub?.cancel();

    _driverSub = _mapRepository
        .getNearbyDrivers(
          latitude: lat,
          longitude: lng,
          radiusKm: filter.radiusKm,
        )
        .listen((drivers) => add(_DriversUpdated(drivers)));

    _rideSub = _rideRepository
        .getNearbyRides(
          location: GeoPoint(lat, lng),
          radiusKm: filter.radiusKm,
        )
        .listen(
          (rides) => add(
            _RidesUpdated(
              rides.where((r) => r.status == RideStatus.scheduled).toList(),
            ),
          ),
        );
  }

  Future<void> _onFiltersChanged(
    MapFiltersChanged event,
    Emitter<MapState> emit,
  ) async {
    if (state is! MapLoaded) {
      return;
    }
    final s = state as MapLoaded;
    emit(s.copyWith(mapFilter: event.filter, clearSelected: true));
    await _subscribeStreams(s.userLat, s.userLng, event.filter);
  }

  void _onDriversUpdated(_DriversUpdated event, Emitter<MapState> emit) {
    if (state is MapLoaded) {
      final current = state as MapLoaded;
      final allowedRideIds = current.nearbyRides.map((r) => r.id).toSet();
      final scoped = event.drivers
          .where((d) => d.rideId != null && allowedRideIds.contains(d.rideId))
          .toList();
      emit(current.copyWith(nearbyDrivers: scoped));
    }
  }

  Future<void> _onRidesUpdated(_RidesUpdated event, Emitter<MapState> emit) async {
    if (state is! MapLoaded) return;
    final current = state as MapLoaded;

    // First apply price cap now; preference tags require driver profiles.
    final priceFiltered = event.rides
        .where((r) => _rideMatchesPrice(r, current.mapFilter))
        .toList();

    final profiles =
        await _ensureDriverProfiles(priceFiltered, current.driverProfiles);
    if (emit.isDone || state is! MapLoaded) return;
    final s = state as MapLoaded;

    final prefFiltered = priceFiltered
        .where((r) => _rideMatchesDriverPrefs(r, s.mapFilter, profiles))
        .toList();

    final allowedRideIds = prefFiltered.map((r) => r.id).toSet();
    final selected = s.selectedDriver;
    final shouldClearSelected = selected != null &&
        (selected.rideId == null || !allowedRideIds.contains(selected.rideId));

    emit(
      s.copyWith(
        nearbyRides: prefFiltered,
        driverProfiles: profiles,
        nearbyDrivers: s.nearbyDrivers
            .where((d) => d.rideId != null && allowedRideIds.contains(d.rideId))
            .toList(),
        clearSelected: shouldClearSelected,
      ),
    );
  }

  bool _rideMatchesPrice(Ride r, MapFilter f) {
    if (f.maxPricePerSeat != null && r.pricePerPassenger > f.maxPricePerSeat!) {
      return false;
    }
    return true;
  }

  bool _rideMatchesDriverPrefs(
    Ride r,
    MapFilter f,
    Map<String, AppUser> profiles,
  ) {
    if (f.requiredPreferenceTags.isEmpty) return true;
    final driver = profiles[r.driverId];
    if (driver == null) return false;
    final tags = driver.ridePreferenceTags.toSet();
    for (final t in f.requiredPreferenceTags) {
      if (!tags.contains(t)) return false;
    }
    return true;
  }

  Future<Map<String, AppUser>> _ensureDriverProfiles(
    List<Ride> rides,
    Map<String, AppUser> existing,
  ) async {
    final missingIds = rides
        .map((r) => r.driverId)
        .where((id) => !existing.containsKey(id))
        .toSet()
        .toList();
    if (missingIds.isEmpty) return existing;
    try {
      final users = await _userRepository.getUsersByIds(missingIds);
      final merged = Map<String, AppUser>.from(existing);
      for (final u in users) {
        merged[u.uid] = u;
      }
      return merged;
    } catch (_) {
      return existing;
    }
  }

  void _onDriverSelected(MapDriverSelected event, Emitter<MapState> emit) {
    if (state is MapLoaded) {
      emit(
        (state as MapLoaded).copyWith(
          selectedDriver: event.driver,
          selectedRideId: event.driver.rideId,
          routePolyline: [],
        ),
      );
      add(MapFetchRoute(event.driver));
    }
  }

  Future<void> _onRideSelected(
    MapRideSelected event,
    Emitter<MapState> emit,
  ) async {
    if (state is! MapLoaded) {
      return;
    }
    final current = state as MapLoaded;
    final ride = event.ride;
    DriverLocation? driver;
    for (final d in current.nearbyDrivers) {
      if (d.rideId == ride.id) {
        driver = d;
        break;
      }
    }

    emit(
      current.copyWith(
        selectedDriver: driver,
        selectedRideId: ride.id,
        routePolyline: const [],
      ),
    );

    try {
      final polyline = await _mapRepository.getRoute(
        fromLat: ride.departure.latitude,
        fromLng: ride.departure.longitude,
        toLat: ride.arrival.latitude,
        toLng: ride.arrival.longitude,
      );
      if (state is MapLoaded) {
        emit((state as MapLoaded).copyWith(routePolyline: polyline));
      }
    } catch (_) {
      // Keep route empty if no valid road route could be resolved.
    }
  }

  void _onDriverDeselected(MapDriverDeselected event, Emitter<MapState> emit) {
    if (state is MapLoaded) {
      emit((state as MapLoaded).copyWith(clearSelected: true));
    }
  }

  Future<void> _onFetchRoute(
    MapFetchRoute event,
    Emitter<MapState> emit,
  ) async {
    final d = event.driver;
    if (d.departureLat == null || d.arrivalLat == null) return;
    try {
      final polyline = await _mapRepository.getRoute(
        fromLat: d.departureLat!,
        fromLng: d.departureLng!,
        toLat: d.arrivalLat!,
        toLng: d.arrivalLng!,
      );
      if (state is MapLoaded) {
        emit((state as MapLoaded).copyWith(routePolyline: polyline));
      }
    } catch (_) {
      // Non-fatal — no polyline shown
    }
  }

  void _onSearchChanged(MapSearchChanged event, Emitter<MapState> emit) {
    if (state is MapLoaded) {
      emit((state as MapLoaded).copyWith(searchQuery: event.query));
    }
  }

  @override
  Future<void> close() {
    _driverSub?.cancel();
    _rideSub?.cancel();
    return super.close();
  }
}

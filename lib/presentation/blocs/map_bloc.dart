import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../domain/entities/driver_location.dart';
import '../../../domain/entities/ride.dart';
import '../../../domain/repositories/map_repository.dart';
import '../../../domain/repositories/ride_repository.dart';

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

class MapSearchChanged extends MapEvent {
  final String query;
  const MapSearchChanged(this.query);
  @override
  List<Object?> get props => [query];
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class MapState extends Equatable {
  const MapState();
  @override
  List<Object?> get props => [];
}

class MapInitial extends MapState {}

class MapLoading extends MapState {}

class MapLoaded extends MapState {
  final double userLat;
  final double userLng;
  final List<DriverLocation> nearbyDrivers;
  final List<Ride> nearbyRides;
  final DriverLocation? selectedDriver;

  const MapLoaded({
    required this.userLat,
    required this.userLng,
    required this.nearbyDrivers,
    required this.nearbyRides,
    this.selectedDriver,
  });

  MapLoaded copyWith({
    double? userLat,
    double? userLng,
    List<DriverLocation>? nearbyDrivers,
    List<Ride>? nearbyRides,
    DriverLocation? selectedDriver,
    bool clearSelected = false,
  }) => MapLoaded(
    userLat: userLat ?? this.userLat,
    userLng: userLng ?? this.userLng,
    nearbyDrivers: nearbyDrivers ?? this.nearbyDrivers,
    nearbyRides: nearbyRides ?? this.nearbyRides,
    selectedDriver: clearSelected
        ? null
        : selectedDriver ?? this.selectedDriver,
  );

  @override
  List<Object?> get props => [
    userLat,
    userLng,
    nearbyDrivers,
    nearbyRides,
    selectedDriver,
  ];
}

class MapPermissionDenied extends MapState {}

class MapError extends MapState {
  final String message;
  const MapError({required this.message});
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

class MapBloc extends Bloc<MapEvent, MapState> {
  final MapRepository _mapRepository;
  StreamSubscription<List<DriverLocation>>? _driverSub;

  // Default: Tunis center
  static const double _defaultLat = 36.8065;
  static const double _defaultLng = 10.1815;

  MapBloc({
    required MapRepository mapRepository,
    required RideRepository rideRepository,
  }) : _mapRepository = mapRepository,
       super(MapInitial()) {
    on<MapInitialized>(_onInitialized);
    on<MapLocationUpdated>(_onLocationUpdated);
    on<MapDriverSelected>(_onDriverSelected);
    on<MapDriverDeselected>(_onDriverDeselected);
  }

  Future<void> _onInitialized(
    MapInitialized event,
    Emitter<MapState> emit,
  ) async {
    emit(MapLoading());
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      double lat = _defaultLat;
      double lng = _defaultLng;

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition();
        lat = pos.latitude;
        lng = pos.longitude;
      } else {
        emit(MapPermissionDenied());
      }

      add(MapLocationUpdated(lat: lat, lng: lng));
    } catch (e) {
      emit(
        MapLoaded(
          userLat: _defaultLat,
          userLng: _defaultLng,
          nearbyDrivers: const [],
          nearbyRides: const [],
        ),
      );
    }
  }

  Future<void> _onLocationUpdated(
    MapLocationUpdated event,
    Emitter<MapState> emit,
  ) async {
    await _driverSub?.cancel();

    await emit.forEach(
      _mapRepository.getNearbyDrivers(
        latitude: event.lat,
        longitude: event.lng,
      ),
      onData: (drivers) {
        final current = state is MapLoaded ? (state as MapLoaded) : null;
        return MapLoaded(
          userLat: event.lat,
          userLng: event.lng,
          nearbyDrivers: drivers,
          nearbyRides: current?.nearbyRides ?? [],
          selectedDriver: current?.selectedDriver,
        );
      },
      onError: (e, _) => MapError(message: e.toString()),
    );
  }

  void _onDriverSelected(MapDriverSelected event, Emitter<MapState> emit) {
    if (state is MapLoaded) {
      emit((state as MapLoaded).copyWith(selectedDriver: event.driver));
    }
  }

  void _onDriverDeselected(MapDriverDeselected event, Emitter<MapState> emit) {
    if (state is MapLoaded) {
      emit((state as MapLoaded).copyWith(clearSelected: true));
    }
  }

  @override
  Future<void> close() {
    _driverSub?.cancel();
    return super.close();
  }
}

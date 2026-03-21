import '../entities/driver_location.dart';

abstract class MapRepository {
  /// Stream of nearby active driver locations from Firebase Realtime Database
  Stream<List<DriverLocation>> getNearbyDrivers({
    required double latitude,
    required double longitude,
    double radiusKm = 20,
  });

  /// Publish current user's location as a driver
  Future<void> publishDriverLocation(DriverLocation location);

  /// Remove driver location when ride ends
  Future<void> removeDriverLocation(String driverId);

  /// Fetch a polyline route from OpenRouteService
  Future<List<List<double>>> getRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  });
}

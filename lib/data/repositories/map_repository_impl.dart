import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/driver_location.dart';
import '../../domain/repositories/map_repository.dart';
import '../datasources/map_remote_datasource.dart';

class MapRepositoryImpl implements MapRepository {
  final MapRemoteDataSource _remote;
  MapRepositoryImpl({required MapRemoteDataSource remote}) : _remote = remote;

  @override
  Stream<List<DriverLocation>> getNearbyDrivers({
    required double latitude,
    required double longitude,
    double radiusKm = 20,
  }) => _remote.getNearbyDrivers(
    latitude: latitude,
    longitude: longitude,
    radiusKm: radiusKm,
  );

  @override
  Future<void> publishDriverLocation(DriverLocation location) async {
    try {
      await _remote.publishDriverLocation(location);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<void> removeDriverLocation(String driverId) async {
    try {
      await _remote.removeDriverLocation(driverId);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<List<List<double>>> getRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    try {
      return await _remote.getRoute(
        fromLat: fromLat,
        fromLng: fromLng,
        toLat: toLat,
        toLng: toLng,
      );
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }
}

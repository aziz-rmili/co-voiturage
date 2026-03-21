import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/ride.dart';
import '../../domain/repositories/ride_repository.dart';
import '../datasources/ride_remote_datasource.dart';
import '../models/ride_model.dart';

class RideRepositoryImpl implements RideRepository {
  final RideRemoteDataSource _remoteDataSource;

  RideRepositoryImpl({required RideRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  @override
  Future<Ride> createRide(Ride ride) async {
    try {
      final model = RideModel.fromEntity(ride);
      return await _remoteDataSource.createRide(model);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<Ride?> getRideById(String id) async {
    try {
      return await _remoteDataSource.getRideById(id);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Stream<List<Ride>> getNearbyRides({
    required GeoPoint location,
    double radiusKm = 20,
  }) {
    return _remoteDataSource
        .getNearbyRides(location: location, radiusKm: radiusKm)
        .handleError((e) {
          if (e is ServerException) throw ServerFailure(message: e.message);
          throw ServerFailure(message: e.toString());
        });
  }

  @override
  Stream<List<Ride>> getUserRides(String userId) {
    return _remoteDataSource.getUserRides(userId).handleError((e) {
      if (e is ServerException) throw ServerFailure(message: e.message);
      throw ServerFailure(message: e.toString());
    });
  }

  @override
  Future<void> bookRide({
    required String rideId,
    required String userId,
  }) async {
    try {
      await _remoteDataSource.bookRide(rideId: rideId, userId: userId);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<void> cancelBooking({
    required String rideId,
    required String userId,
  }) async {
    try {
      await _remoteDataSource.cancelBooking(rideId: rideId, userId: userId);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<void> cancelRide(String rideId) async {
    try {
      await _remoteDataSource.cancelRide(rideId);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<void> completeRide(String rideId) async {
    try {
      await _remoteDataSource.completeRide(rideId);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }
}

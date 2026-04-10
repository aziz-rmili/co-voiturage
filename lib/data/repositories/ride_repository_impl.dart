import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/ride.dart';
import '../../domain/entities/ride_report.dart';
import '../../domain/repositories/ride_repository.dart';
import '../datasources/ride_remote_datasource.dart';
import '../models/ride_model.dart';

class RideRepositoryImpl implements RideRepository {
  final RideRemoteDataSource _remote;
  RideRepositoryImpl({required RideRemoteDataSource remoteDataSource})
    : _remote = remoteDataSource;

  @override
  Future<Ride> createRide(Ride ride) async {
    try {
      return await _remote.createRide(RideModel.fromEntity(ride));
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<Ride?> getRideById(String id) async {
    try {
      return await _remote.getRideById(id);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Stream<List<Ride>> getNearbyRides({
    required GeoPoint location,
    double radiusKm = 20,
  }) => _remote
      .getNearbyRides(location: location, radiusKm: radiusKm)
      .handleError((e) {
        if (e is ServerException) throw ServerFailure(message: e.message);
      });

  @override
  Stream<List<Ride>> getAllRides() => _remote.getAllRides().handleError((e) {
    if (e is ServerException) throw ServerFailure(message: e.message);
  });

  @override
  Stream<List<Ride>> getUserRides(String userId) =>
      _remote.getUserRides(userId).handleError((e) {
        if (e is ServerException) throw ServerFailure(message: e.message);
      });

  @override
  Future<void> requestBooking({
    required String rideId,
    required String userId,
  }) async {
    try {
      await _remote.requestBooking(rideId: rideId, userId: userId);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<void> confirmPassenger({
    required String rideId,
    required String passengerId,
  }) async {
    try {
      await _remote.confirmPassenger(rideId: rideId, passengerId: passengerId);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<void> rejectPassenger({
    required String rideId,
    required String passengerId,
  }) async {
    try {
      await _remote.rejectPassenger(rideId: rideId, passengerId: passengerId);
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
      await _remote.cancelBooking(rideId: rideId, userId: userId);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<void> cancelRide(String rideId) async {
    try {
      await _remote.cancelRide(rideId);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<void> deleteRide(String rideId) async {
    try {
      await _remote.deleteRide(rideId);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<void> completeRide(String rideId) async {
    try {
      await _remote.completeRide(rideId);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<void> reportRide({
    required String rideId,
    required String reporterId,
    required String driverId,
    required String reason,
    String? details,
  }) async {
    try {
      await _remote.reportRide(
        rideId: rideId,
        reporterId: reporterId,
        driverId: driverId,
        reason: reason,
        details: details,
      );
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Stream<List<RideReport>> getRideReports() =>
      _remote.getRideReports().handleError((e) {
        if (e is ServerException) throw ServerFailure(message: e.message);
      });

  @override
  Future<void> resolveRideReport(String reportId) async {
    try {
      await _remote.resolveRideReport(reportId);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<void> updatePassengerCo2({
    required List<String> passengerIds,
    required double co2PerPassenger,
  }) async {
    try {
      await _remote.updatePassengerCo2(
        passengerIds: passengerIds,
        co2PerPassenger: co2PerPassenger,
      );
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }
}

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_datasource.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _remote;
  UserRepositoryImpl({required UserRemoteDataSource remote}) : _remote = remote;

  @override
  Future<AppUser?> getUserById(String uid) async {
    try {
      return await _remote.getUserById(uid);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<List<AppUser>> getUsersByIds(List<String> uids) async {
    try {
      return await _remote.getUsersByIds(uids);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<void> updateRidePreferences({
    required String uid,
    required Map<String, dynamic> ridePreferences,
  }) async {
    try {
      await _remote.updateRidePreferences(
        uid: uid,
        ridePreferences: ridePreferences,
      );
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<void> updateVehicles({
    required String uid,
    required List<Vehicle> vehicles,
  }) async {
    try {
      await _remote.updateVehicles(uid: uid, vehicles: vehicles);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<void> updateUser({
    required String uid,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _remote.updateUser(uid: uid, updates: updates);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Stream<List<AppUser>> getPendingDrivers() {
    try {
      return _remote.getPendingDrivers();
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Stream<List<AppUser>> getReportedDrivers() {
    try {
      return _remote.getReportedDrivers();
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<void> approveDriver(String uid) async {
    try {
      await _remote.approveDriver(uid);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<void> banDriver({
    required String uid,
    DateTime? until,
    bool indefinite = false,
  }) async {
    try {
      await _remote.banDriver(uid: uid, until: until, indefinite: indefinite);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }
}

import '../entities/app_user.dart';
import '../entities/vehicle.dart';

abstract class UserRepository {
  Future<AppUser?> getUserById(String uid);
  Future<List<AppUser>> getUsersByIds(List<String> uids);
  Stream<List<AppUser>> getPendingDrivers();
  Stream<List<AppUser>> getReportedDrivers();
  Future<void> approveDriver(String uid);
  Future<void> banDriver({
    required String uid,
    DateTime? until,
    bool indefinite = false,
  });
  Future<void> updateRidePreferences({
    required String uid,
    required Map<String, dynamic> ridePreferences,
  });
  Future<void> updateVehicles({
    required String uid,
    required List<Vehicle> vehicles,
  });
  Future<void> updateUser({
    required String uid,
    required Map<String, dynamic> updates,
  });
}

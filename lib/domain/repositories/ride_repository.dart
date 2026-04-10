import 'package:cloud_firestore/cloud_firestore.dart';
import '../entities/ride.dart';
import '../entities/ride_report.dart';

abstract class RideRepository {
  /// Create a new ride in Firestore. Returns the created [Ride] with its id.
  Future<Ride> createRide(Ride ride);

  /// Fetch a single ride by id.
  Future<Ride?> getRideById(String id);

  /// Stream all scheduled rides near [location] within [radiusKm].
  Stream<List<Ride>> getNearbyRides({
    required GeoPoint location,
    double radiusKm = 20,
  });

  /// Stream all rides for admin reporting and statistics.
  Stream<List<Ride>> getAllRides();

  Future<void> reportRide({
    required String rideId,
    required String reporterId,
    required String driverId,
    required String reason,
    String? details,
  });

  Stream<List<RideReport>> getRideReports();

  Future<void> resolveRideReport(String reportId);

  /// Stream rides where the current user is driver or passenger.
  Stream<List<Ride>> getUserRides(String userId);

  Future<void> requestBooking({required String rideId, required String userId});
  Future<void> confirmPassenger({
    required String rideId,
    required String passengerId,
  });
  Future<void> rejectPassenger({
    required String rideId,
    required String passengerId,
  });
  Future<void> cancelBooking({required String rideId, required String userId});
  Future<void> cancelRide(String rideId);
  Future<void> deleteRide(String rideId);
  Future<void> completeRide(String rideId);
  Future<void> updatePassengerCo2({
    required List<String> passengerIds,
    required double co2PerPassenger,
  });
}

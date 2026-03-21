import 'package:cloud_firestore/cloud_firestore.dart';
import '../entities/ride.dart';

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

  /// Stream rides where the current user is driver or passenger.
  Stream<List<Ride>> getUserRides(String userId);

  /// Add a passenger to a ride.
  Future<void> bookRide({required String rideId, required String userId});

  /// Remove a passenger from a ride.
  Future<void> cancelBooking({required String rideId, required String userId});

  /// Driver cancels the entire ride.
  Future<void> cancelRide(String rideId);

  /// Mark a ride as completed.
  Future<void> completeRide(String rideId);
}

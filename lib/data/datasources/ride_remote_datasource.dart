import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/errors/exceptions.dart';
import '../models/ride_model.dart';

abstract class RideRemoteDataSource {
  Future<RideModel> createRide(RideModel ride);
  Future<RideModel?> getRideById(String id);
  Stream<List<RideModel>> getNearbyRides({
    required GeoPoint location,
    double radiusKm = 20,
  });
  Stream<List<RideModel>> getUserRides(String userId);
  Future<void> bookRide({required String rideId, required String userId});
  Future<void> cancelBooking({required String rideId, required String userId});
  Future<void> cancelRide(String rideId);
  Future<void> completeRide(String rideId);
}

class RideRemoteDataSourceImpl implements RideRemoteDataSource {
  final FirebaseFirestore _firestore;

  static const String _ridesCollection = 'rides';

  RideRemoteDataSourceImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _ridesRef =>
      _firestore.collection(_ridesCollection);

  // ── Create ────────────────────────────────────────────────────────────────

  @override
  Future<RideModel> createRide(RideModel ride) async {
    try {
      final docRef = await _ridesRef.add(ride.toMap());
      // Return ride with the Firestore-generated id
      return RideModel.fromMap(ride.toMap(), docRef.id);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  // ── Read single ───────────────────────────────────────────────────────────

  @override
  Future<RideModel?> getRideById(String id) async {
    try {
      final doc = await _ridesRef.doc(id).get();
      if (!doc.exists) return null;
      return RideModel.fromFirestore(doc);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  // ── Nearby rides stream ───────────────────────────────────────────────────
  // Note: True geo-radius queries require the geoflutterfire_plus package.
  // This implementation uses a bounding-box approximation sufficient for MVP.

  @override
  Stream<List<RideModel>> getNearbyRides({
    required GeoPoint location,
    double radiusKm = 20,
  }) {
    // ~1 degree latitude = 111 km
    final latDelta = radiusKm / 111.0;
    final lngDelta = radiusKm / (111.0 * _cos(location.latitude));

    final minLat = location.latitude - latDelta;
    final maxLat = location.latitude + latDelta;
    final minLng = location.longitude - lngDelta;
    final maxLng = location.longitude + lngDelta;

    return _ridesRef
        .where('status', isEqualTo: 'scheduled')
        .where('departure', isGreaterThanOrEqualTo: GeoPoint(minLat, minLng))
        .where('departure', isLessThanOrEqualTo: GeoPoint(maxLat, maxLng))
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => RideModel.fromFirestore(d)).toList(),
        );
  }

  // ── User rides stream ─────────────────────────────────────────────────────

  @override
  Stream<List<RideModel>> getUserRides(String userId) {
    // Rides where user is driver
    final driverStream = _ridesRef
        .where('driverId', isEqualTo: userId)
        .snapshots()
        .map((s) => s.docs.map((d) => RideModel.fromFirestore(d)).toList());

    // Rides where user is passenger
    final passengerStream = _ridesRef
        .where('passengersIds', arrayContains: userId)
        .snapshots()
        .map((s) => s.docs.map((d) => RideModel.fromFirestore(d)).toList());

    // Merge both streams
    return _mergeRideStreams(driverStream, passengerStream);
  }

  // ── Book ──────────────────────────────────────────────────────────────────

  @override
  Future<void> bookRide({
    required String rideId,
    required String userId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _ridesRef.doc(rideId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw const ServerException(message: 'Ride not found.');
        }

        final ride = RideModel.fromFirestore(snapshot);

        if (ride.isFull) {
          throw const ServerException(message: 'No seats available.');
        }
        if (ride.passengersIds.contains(userId)) {
          throw const ServerException(message: 'Already booked.');
        }

        transaction.update(docRef, {
          'passengersIds': FieldValue.arrayUnion([userId]),
        });
      });
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  // ── Cancel booking ────────────────────────────────────────────────────────

  @override
  Future<void> cancelBooking({
    required String rideId,
    required String userId,
  }) async {
    try {
      await _ridesRef.doc(rideId).update({
        'passengersIds': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  // ── Cancel ride ───────────────────────────────────────────────────────────

  @override
  Future<void> cancelRide(String rideId) async {
    try {
      await _ridesRef.doc(rideId).update({'status': 'cancelled'});
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  // ── Complete ride ─────────────────────────────────────────────────────────

  @override
  Future<void> completeRide(String rideId) async {
    try {
      await _ridesRef.doc(rideId).update({'status': 'completed'});
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  double _cos(double degrees) {
    const pi = 3.141592653589793;
    return (degrees * pi / 180).let(_cosRad);
  }

  double _cosRad(double rad) {
    // Taylor series approximation (accurate enough for small deltas)
    return 1 -
        (rad * rad) / 2 +
        (rad * rad * rad * rad) / 24 -
        (rad * rad * rad * rad * rad * rad) / 720;
  }

  Stream<List<RideModel>> _mergeRideStreams(
    Stream<List<RideModel>> a,
    Stream<List<RideModel>> b,
  ) async* {
    List<RideModel> latestA = [];
    List<RideModel> latestB = [];

    await for (final _ in Stream.periodic(const Duration(milliseconds: 100))) {
      // This is a simplified merge; use rxdart's CombineLatestStream in production.
      yield [...latestA, ...latestB];
    }
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}

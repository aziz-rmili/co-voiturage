import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/errors/exceptions.dart';
import '../models/ride_model.dart';
import '../models/ride_report_model.dart';

abstract class RideRemoteDataSource {
  Future<RideModel> createRide(RideModel ride);
  Future<RideModel?> getRideById(String id);
  Stream<List<RideModel>> getNearbyRides({
    required GeoPoint location,
    double radiusKm = 20,
  });
  Stream<List<RideModel>> getAllRides();
  Stream<List<RideModel>> getUserRides(String userId);
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

  Future<void> reportRide({
    required String rideId,
    required String reporterId,
    required String driverId,
    required String reason,
    String? details,
  });

  Stream<List<RideReportModel>> getRideReports();

  Future<void> resolveRideReport(String reportId);

  /// Called when a ride is completed — adds CO2 savings to each passenger's profile.
  Future<void> updatePassengerCo2({
    required List<String> passengerIds,
    required double co2PerPassenger,
  });
}

class RideRemoteDataSourceImpl implements RideRemoteDataSource {
  final FirebaseFirestore _firestore;
  RideRemoteDataSourceImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _rides =>
      _firestore.collection('rides');
  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('ride_reports');

  Future<void> _updateLatestBookingNotification({
    required Transaction tx,
    required String driverId,
    required String rideId,
    required String passengerId,
    required String newType,
    required String title,
    required String body,
    required bool requiresAction,
  }) async {
    final q = _notifications
        .where('userId', isEqualTo: driverId)
        .where('relatedId', isEqualTo: rideId)
        .where('passengerId', isEqualTo: passengerId)
        .where('type', isEqualTo: 'bookingRequested')
        .limit(1);
    final qSnap = await q.get();
    if (qSnap.docs.isEmpty) return;
    tx.update(qSnap.docs.first.reference, {
      'type': newType,
      'title': title,
      'body': body,
      'requiresAction': requiresAction,
      // make it pop to top as "just updated"
      'timestamp': Timestamp.now(),
      // keep isRead as-is (don't force unread/read changes)
    });
  }

  @override
  Future<RideModel> createRide(RideModel ride) async {
    try {
      final ref = await _rides.add(ride.toMap());
      return RideModel.fromMap(ride.toMap(), ref.id);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<RideModel?> getRideById(String id) async {
    try {
      final doc = await _rides.doc(id).get();
      if (!doc.exists) return null;
      return RideModel.fromFirestore(doc);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Stream<List<RideModel>> getNearbyRides({
    required GeoPoint location,
    double radiusKm = 20,
  }) {
    return _rides
        .where('status', isEqualTo: 'scheduled')
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => RideModel.fromFirestore(d)).where((r) {
            final now = DateTime.now().toUtc();
            final dist = _distanceKm(
              location.latitude,
              location.longitude,
              r.departure.latitude,
              r.departure.longitude,
            );
            return dist <= radiusKm &&
                r.isAvailable &&
                !r.dateHour.toUtc().isBefore(now);
          }).toList(),
        );
  }

  @override
  Stream<List<RideModel>> getAllRides() {
    return _rides.snapshots().map(
      (snap) => snap.docs.map((d) => RideModel.fromFirestore(d)).toList(),
    );
  }

  @override
  Stream<List<RideModel>> getUserRides(String userId) {
    final driverStream = _rides
        .where('driverId', isEqualTo: userId)
        .snapshots()
        .map((s) => s.docs.map((d) => RideModel.fromFirestore(d)).toList());

    final pendingStream = _rides
        .where('pendingPassengerIds', arrayContains: userId)
        .snapshots()
        .map((s) => s.docs.map((d) => RideModel.fromFirestore(d)).toList());

    final confirmedStream = _rides
        .where('confirmedPassengerIds', arrayContains: userId)
        .snapshots()
        .map((s) => s.docs.map((d) => RideModel.fromFirestore(d)).toList());

    List<RideModel> a = [], b = [], c = [];
    final controller = StreamController<List<RideModel>>.broadcast();

    driverStream.listen((data) {
      a = data;
      controller.add(_merge([a, b, c]));
    });
    pendingStream.listen((data) {
      b = data;
      controller.add(_merge([a, b, c]));
    });
    confirmedStream.listen((data) {
      c = data;
      controller.add(_merge([a, b, c]));
    });

    return controller.stream;
  }

  List<RideModel> _merge(List<List<RideModel>> lists) {
    final map = <String, RideModel>{};
    for (final list in lists) {
      for (final r in list) {
        map[r.id] = r;
      }
    }
    return map.values.toList();
  }

  @override
  Future<void> requestBooking({
    required String rideId,
    required String userId,
  }) async {
    try {
      await _firestore.runTransaction((tx) async {
        final ref = _rides.doc(rideId);
        final snap = await tx.get(ref);
        if (!snap.exists) {
          throw const ServerException(message: 'Ride not found.');
        }
        final ride = RideModel.fromFirestore(snap);
        if (ride.isFull) {
          throw const ServerException(message: 'No seats available.');
        }
        if (ride.pendingPassengerIds.contains(userId) ||
            ride.confirmedPassengerIds.contains(userId)) {
          throw const ServerException(message: 'Already booked.');
        }
        tx.update(ref, {
          'pendingPassengerIds': FieldValue.arrayUnion([userId]),
        });

        // Notify the driver (in-app notifications collection).
        // This enables the driver to open Trip Details and confirm the seat.
        final notifRef = _notifications.doc();
        tx.set(notifRef, {
          'userId': ride.driverId,
          'type': 'bookingRequested',
          'title': 'New booking request',
          'body': 'A passenger requested a seat for your trip. Tap to review.',
          'timestamp': Timestamp.now(),
          'isRead': false,
          'requiresAction': true,
          'relatedId': rideId,
          'passengerId':
              userId, // extra field; safe for older clients to ignore
        });
      });
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> confirmPassenger({
    required String rideId,
    required String passengerId,
  }) async {
    try {
      await _firestore.runTransaction((tx) async {
        final ref = _rides.doc(rideId);
        final snap = await tx.get(ref);
        if (!snap.exists) {
          throw const ServerException(message: 'Ride not found.');
        }
        final ride = RideModel.fromFirestore(snap);
        if (ride.isFull) {
          throw const ServerException(message: 'Ride is already full.');
        }
        tx.update(ref, {
          'pendingPassengerIds': FieldValue.arrayRemove([passengerId]),
          'confirmedPassengerIds': FieldValue.arrayUnion([passengerId]),
        });

        await _updateLatestBookingNotification(
          tx: tx,
          driverId: ride.driverId,
          rideId: rideId,
          passengerId: passengerId,
          newType: 'bookingApproved',
          title: 'Passenger approved',
          body: 'You approved this booking request.',
          requiresAction: false,
        );
      });
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> rejectPassenger({
    required String rideId,
    required String passengerId,
  }) async {
    try {
      await _firestore.runTransaction((tx) async {
        final ref = _rides.doc(rideId);
        final snap = await tx.get(ref);
        if (!snap.exists) {
          throw const ServerException(message: 'Ride not found.');
        }
        final ride = RideModel.fromFirestore(snap);

        tx.update(ref, {
          'pendingPassengerIds': FieldValue.arrayRemove([passengerId]),
          // ensure the passenger isn't in confirmed either
          'confirmedPassengerIds': FieldValue.arrayRemove([passengerId]),
        });

        await _updateLatestBookingNotification(
          tx: tx,
          driverId: ride.driverId,
          rideId: rideId,
          passengerId: passengerId,
          newType: 'bookingRejected',
          title: 'Passenger rejected',
          body: 'You rejected this booking request.',
          requiresAction: false,
        );
      });
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> cancelBooking({
    required String rideId,
    required String userId,
  }) async {
    try {
      await _rides.doc(rideId).update({
        'pendingPassengerIds': FieldValue.arrayRemove([userId]),
        'confirmedPassengerIds': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> cancelRide(String rideId) async {
    try {
      await _rides.doc(rideId).update({'status': 'cancelled'});
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteRide(String rideId) async {
    try {
      await _rides.doc(rideId).delete();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> completeRide(String rideId) async {
    try {
      final doc = await _rides.doc(rideId).get();
      if (!doc.exists) return;
      final ride = RideModel.fromFirestore(doc);

      await _rides.doc(rideId).update({'status': 'completed'});

      // Add CO2 savings to each confirmed passenger's Firestore document
      final co2PerPassenger =
          ride.availableSeats *
          2.4 /
          (ride.confirmedPassengerIds.isEmpty
              ? 1
              : ride.confirmedPassengerIds.length);
      await updatePassengerCo2(
        passengerIds: ride.confirmedPassengerIds,
        co2PerPassenger: co2PerPassenger,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
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
      final existingReportSnapshot = await _reports
          .where('rideId', isEqualTo: rideId)
          .where('reporterId', isEqualTo: reporterId)
          .limit(1)
          .get();

      if (existingReportSnapshot.docs.isNotEmpty) {
        throw const ServerException(
          message: 'You already submitted a report for this trip.',
        );
      }

      await _firestore.runTransaction((tx) async {
        final rideRef = _rides.doc(rideId);
        final rideSnap = await tx.get(rideRef);
        if (!rideSnap.exists) {
          throw const ServerException(message: 'Ride not found.');
        }

        final reportRef = _reports.doc();
        tx.set(reportRef, {
          'rideId': rideId,
          'reporterId': reporterId,
          'driverId': driverId,
          'reason': reason,
          'details': details,
          'createdAt': Timestamp.now(),
          'status': 'open',
        });

        final driverRef = _firestore.collection('users').doc(driverId);
        tx.set(driverRef, {
          'reportCount': FieldValue.increment(1),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Stream<List<RideReportModel>> getRideReports() {
    return _reports.where('status', isEqualTo: 'open').snapshots().map((snap) {
      final list = snap.docs
          .map((doc) => RideReportModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Future<void> resolveRideReport(String reportId) async {
    try {
      await _reports.doc(reportId).update({'status': 'resolved'});
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> updatePassengerCo2({
    required List<String> passengerIds,
    required double co2PerPassenger,
  }) async {
    try {
      final batch = _firestore.batch();
      for (final uid in passengerIds) {
        final ref = _firestore.collection('users').doc(uid);
        batch.update(ref, {
          'co2SavedKg': FieldValue.increment(co2PerPassenger),
        });
      }
      await batch.commit();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degToRad(double deg) => deg * math.pi / 180.0;
}

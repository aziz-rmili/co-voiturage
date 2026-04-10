import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/ride.dart';

class RideModel extends Ride {
  const RideModel({
    required super.id,
    required super.driverId,
    required super.departure,
    required super.arrival,
    super.departureAddress,
    super.arrivalAddress,
    required super.dateHour,
    required super.availableSeats,
    required super.pricePerPassenger,
    super.pendingPassengerIds,
    super.confirmedPassengerIds,
    super.status,
    super.note,
    super.co2SavedKg,
  });

  // ─────────────────────────────────────────────
  // Firestore → Model
  // ─────────────────────────────────────────────

  factory RideModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RideModel.fromMap(data, doc.id);
  }

  factory RideModel.fromMap(Map<String, dynamic> map, String id) {
    return RideModel(
      id: id,
      driverId: map['driverId'] as String? ?? '',
      departure: map['departure'] as GeoPoint,
      arrival: map['arrival'] as GeoPoint,
      departureAddress: map['departureAddress'] as String? ?? '',
      arrivalAddress: map['arrivalAddress'] as String? ?? '',
      dateHour: (map['dateHour'] as Timestamp).toDate(),
      availableSeats: (map['availableSeats'] as num?)?.toInt() ?? 1,
      pricePerPassenger: (map['pricePerPassenger'] as num?)?.toDouble() ?? 0.0,
      pendingPassengerIds: List<String>.from(map['pendingPassengerIds'] ?? []),
      confirmedPassengerIds: List<String>.from(
        map['confirmedPassengerIds'] ?? [],
      ),
      status: _parseStatus(map['status']),
      note: map['note'] as String? ?? '',
      co2SavedKg: (map['co2SavedKg'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // ─────────────────────────────────────────────
  // Model → Firestore
  // ─────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'departure': departure,
      'arrival': arrival,
      'departureAddress': departureAddress,
      'arrivalAddress': arrivalAddress,
      'dateHour': Timestamp.fromDate(dateHour),
      'availableSeats': availableSeats,
      'pricePerPassenger': pricePerPassenger,
      'pendingPassengerIds': pendingPassengerIds,
      'confirmedPassengerIds': confirmedPassengerIds,
      'status': status.name,
      'note': note,
      'co2SavedKg': co2SavedKg,
    };
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────

  static RideStatus _parseStatus(dynamic value) {
    switch (value as String?) {
      case 'active':
        return RideStatus.active;
      case 'completed':
        return RideStatus.completed;
      case 'cancelled':
        return RideStatus.cancelled;
      default:
        return RideStatus.scheduled;
    }
  }

  // ─────────────────────────────────────────────
  // Entity → Model
  // ─────────────────────────────────────────────

  factory RideModel.fromEntity(Ride ride) {
    return RideModel(
      id: ride.id,
      driverId: ride.driverId,
      departure: ride.departure,
      arrival: ride.arrival,
      departureAddress: ride.departureAddress,
      arrivalAddress: ride.arrivalAddress,
      dateHour: ride.dateHour,
      availableSeats: ride.availableSeats,
      pricePerPassenger: ride.pricePerPassenger,
      pendingPassengerIds: ride.pendingPassengerIds,
      confirmedPassengerIds: ride.confirmedPassengerIds,
      status: ride.status,
      note: ride.note,
      co2SavedKg: ride.effectiveCo2SavedKg,
    );
  }
}

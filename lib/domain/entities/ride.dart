import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum RideStatus { scheduled, active, completed, cancelled }

class Ride extends Equatable {
  final String id;
  final String driverId;
  final GeoPoint departure;
  final GeoPoint arrival;
  final String departureAddress;
  final String arrivalAddress;
  final DateTime dateHour;
  final int availableSeats;
  final double pricePerPassenger;

  /// Passengers who requested the ride but await confirmation
  final List<String> pendingPassengerIds;

  /// Passengers confirmed by the driver
  final List<String> confirmedPassengerIds;
  final RideStatus status;
  final String note;

  /// Optional stored CO2 value
  final double? co2SavedKg;

  const Ride({
    required this.id,
    required this.driverId,
    required this.departure,
    required this.arrival,
    this.departureAddress = '',
    this.arrivalAddress = '',
    required this.dateHour,
    required this.availableSeats,
    required this.pricePerPassenger,
    this.pendingPassengerIds = const [],
    this.confirmedPassengerIds = const [],
    this.status = RideStatus.scheduled,
    this.note = '',
    this.co2SavedKg = 0.0,
  });

  /// Legacy accessor combining both lists
  List<String> get passengersIds => [
    ...pendingPassengerIds,
    ...confirmedPassengerIds,
  ];

  /// Ride is full when confirmed seats reach capacity
  bool get isFull => confirmedPassengerIds.length >= availableSeats;

  int get seatsLeft => availableSeats - confirmedPassengerIds.length;

  /// Ride appears in search only if scheduled and not full
  bool get isAvailable => status == RideStatus.scheduled && !isFull;

  /// Distance between departure and arrival
  double get distanceKm => _haversineDistance(departure, arrival);

  /// CO2 saved either stored or computed
  double get effectiveCo2SavedKg {
    if (co2SavedKg != null && co2SavedKg! > 0.0) return co2SavedKg!;
    return computeCo2SavedKg(distanceKm);
  }

  static double computeCo2SavedKg(double km, {double factor = 0.12}) {
    return double.parse((km * factor).toStringAsFixed(2));
  }

  static double _toRad(double degree) => degree * (3.141592653589793 / 180);

  static double _haversineDistance(GeoPoint a, GeoPoint b) {
    final lat1 = a.latitude;
    final lon1 = a.longitude;
    final lat2 = b.latitude;
    final lon2 = b.longitude;

    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);

    final radLat1 = _toRad(lat1);
    final radLat2 = _toRad(lat2);

    final haversine =
        (sin(dLat / 2) * sin(dLat / 2)) +
        (sin(dLon / 2) * sin(dLon / 2)) * cos(radLat1) * cos(radLat2);

    final c = 2 * atan2(sqrt(haversine), sqrt(1 - haversine));

    const earthRadiusKm = 6371.0;

    return double.parse((earthRadiusKm * c).toStringAsFixed(2));
  }

  Ride copyWith({
    String? id,
    String? driverId,
    GeoPoint? departure,
    GeoPoint? arrival,
    String? departureAddress,
    String? arrivalAddress,
    DateTime? dateHour,
    int? availableSeats,
    double? pricePerPassenger,
    List<String>? pendingPassengerIds,
    List<String>? confirmedPassengerIds,
    RideStatus? status,
    String? note,
    double? co2SavedKg,
  }) {
    return Ride(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      departure: departure ?? this.departure,
      arrival: arrival ?? this.arrival,
      departureAddress: departureAddress ?? this.departureAddress,
      arrivalAddress: arrivalAddress ?? this.arrivalAddress,
      dateHour: dateHour ?? this.dateHour,
      availableSeats: availableSeats ?? this.availableSeats,
      pricePerPassenger: pricePerPassenger ?? this.pricePerPassenger,
      pendingPassengerIds: pendingPassengerIds ?? this.pendingPassengerIds,
      confirmedPassengerIds:
          confirmedPassengerIds ?? this.confirmedPassengerIds,
      status: status ?? this.status,
      note: note ?? this.note,
      co2SavedKg: co2SavedKg ?? this.co2SavedKg,
    );
  }

  @override
  List<Object?> get props => [
    id,
    driverId,
    departure,
    arrival,
    dateHour,
    availableSeats,
    pricePerPassenger,
    pendingPassengerIds,
    confirmedPassengerIds,
    status,
    note,
    co2SavedKg,
  ];
}

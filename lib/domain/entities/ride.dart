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
  final List<String> passengersIds;
  final RideStatus status;
  final double co2SavedKg;

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
    this.passengersIds = const [],
    this.status = RideStatus.scheduled,
    this.co2SavedKg = 0.0,
  });

  bool get isFull => passengersIds.length >= availableSeats;
  int get seatsLeft => availableSeats - passengersIds.length;

  double get distanceKm => _haversineDistance(departure, arrival);

  double get effectiveCo2SavedKg {
    if (co2SavedKg > 0.0) return co2SavedKg;
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
    List<String>? passengersIds,
    RideStatus? status,
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
      passengersIds: passengersIds ?? this.passengersIds,
      status: status ?? this.status,
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
    passengersIds,
    status,
    co2SavedKg,
  ];
}

import 'package:equatable/equatable.dart';

class DriverLocation extends Equatable {
  final String driverId;
  final double latitude;
  final double longitude;
  final String? rideId;
  final String? destination;
  final String? departure; // departure address
  final String? departureTime;
  final double? departureLat;
  final double? departureLng;
  final double? arrivalLat;
  final double? arrivalLng;
  final int seatsLeft;
  final double? pricePerSeat;
  final DateTime updatedAt;

  const DriverLocation({
    required this.driverId,
    required this.latitude,
    required this.longitude,
    this.rideId,
    this.destination,
    this.departure,
    this.departureTime,
    this.departureLat,
    this.departureLng,
    this.arrivalLat,
    this.arrivalLng,
    this.seatsLeft = 0,
    this.pricePerSeat,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [driverId, latitude, longitude, rideId, updatedAt];
}

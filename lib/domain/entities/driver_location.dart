import 'package:equatable/equatable.dart';

class DriverLocation extends Equatable {
  final String driverId;
  final double latitude;
  final double longitude;
  final String? rideId;
  final String? destination;
  final String? departureTime;
  final int seatsLeft;
  final DateTime updatedAt;

  const DriverLocation({
    required this.driverId,
    required this.latitude,
    required this.longitude,
    this.rideId,
    this.destination,
    this.departureTime,
    this.seatsLeft = 0,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [driverId, latitude, longitude, rideId, updatedAt];
}

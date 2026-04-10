import 'package:equatable/equatable.dart';

import 'vehicle.dart';

class DriverCredentials extends Equatable {
  final String userId;
  final String licenseNumber;
  final DateTime licenseExpirationDate;
  final Vehicle vehicle;
  final String licensePhotoUrl; // Firebase Storage URL after upload
  final DateTime submittedAt;

  const DriverCredentials({
    required this.userId,
    required this.licenseNumber,
    required this.licenseExpirationDate,
    required this.vehicle,
    this.licensePhotoUrl = '',
    required this.submittedAt,
  });

  @override
  List<Object?> get props => [
    userId,
    licenseNumber,
    licenseExpirationDate,
    vehicle,
    licensePhotoUrl,
    submittedAt,
  ];
}

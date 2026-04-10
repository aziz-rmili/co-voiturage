import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Vehicle extends Equatable {
  final String licensePlate;
  final String model;
  final String color;
  final String licenseNumber;
  final DateTime licenseExpirationDate;

  Vehicle({
    required this.licensePlate,
    this.model = '',
    this.color = '',
    this.licenseNumber = '',
    DateTime? licenseExpirationDate,
  }) : licenseExpirationDate = licenseExpirationDate ?? DateTime(1970);

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    final expiry = map['licenseExpirationDate'];
    DateTime parsedExpiry;
    if (expiry is Timestamp) {
      parsedExpiry = expiry.toDate();
    } else if (expiry is String) {
      parsedExpiry = DateTime.tryParse(expiry) ?? DateTime(1970);
    } else {
      parsedExpiry = DateTime(1970);
    }

    return Vehicle(
      licensePlate: map['licensePlate'] as String? ?? '',
      model: map['model'] as String? ?? '',
      color: map['color'] as String? ?? '',
      licenseNumber: map['licenseNumber'] as String? ?? '',
      licenseExpirationDate: parsedExpiry,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'licensePlate': licensePlate,
      'model': model,
      'color': color,
      'licenseNumber': licenseNumber,
      'licenseExpirationDate': Timestamp.fromDate(licenseExpirationDate),
    };
  }

  @override
  List<Object?> get props => [
    licensePlate,
    model,
    color,
    licenseNumber,
    licenseExpirationDate,
  ];
}

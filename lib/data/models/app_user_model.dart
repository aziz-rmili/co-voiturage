import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/vehicle.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.uid,
    required super.name,
    required super.email,
    required super.phone,
    super.photoUrl,
    required super.dateInscription,
    super.preferences,
    super.vehicles,
    super.ridePreferences,
    super.averageRating,
    super.verification,
    super.role,
    super.co2SavedKg,
    super.distanceSharedKm,
    super.reportCount,
    super.isBanned,
    super.bannedUntil,
  });

  factory AppUserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUserModel.fromMap(data, doc.id);
  }

  factory AppUserModel.fromMap(Map<String, dynamic> map, String uid) {
    return AppUserModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',
      dateInscription: map['dateInscription'] != null
          ? (map['dateInscription'] as Timestamp).toDate()
          : DateTime.now(),
      preferences: List<String>.from(map['preferences'] ?? []),
      vehicles:
          (map['vehicles'] as List?)
              ?.map((vehicleData) {
                if (vehicleData is String) {
                  return Vehicle(licensePlate: vehicleData);
                }
                if (vehicleData is Map) {
                  return Vehicle.fromMap(
                    Map<String, dynamic>.from(vehicleData),
                  );
                }
                return null;
              })
              .whereType<Vehicle>()
              .toList() ??
          [],
      ridePreferences: Map<String, dynamic>.from(
        map['ridePreferences'] as Map? ?? const {},
      ),
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
      verification: _parseVerification(map['verification']),
      role: _parseRole(map['role']),
      co2SavedKg: (map['co2SavedKg'] as num?)?.toDouble() ?? 0.0,
      distanceSharedKm: (map['distanceSharedKm'] as num?)?.toDouble() ?? 0.0,
      reportCount: (map['reportCount'] as num?)?.toInt() ?? 0,
      isBanned: map['isBanned'] as bool? ?? false,
      bannedUntil: map['bannedUntil'] != null
          ? (map['bannedUntil'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'dateInscription': Timestamp.fromDate(dateInscription),
      'preferences': preferences,
      'vehicles': vehicles.map((vehicle) => vehicle.toMap()).toList(),
      'ridePreferences': ridePreferences,
      'averageRating': averageRating,
      'verification': verification.name,
      'role': role.name,
      'co2SavedKg': co2SavedKg,
      'distanceSharedKm': distanceSharedKm,
      'reportCount': reportCount,
      'isBanned': isBanned,
      'bannedUntil': bannedUntil != null
          ? Timestamp.fromDate(bannedUntil!)
          : null,
    };
  }

  static VerificationStatus _parseVerification(dynamic value) {
    switch (value as String?) {
      case 'pending':
        return VerificationStatus.pending;
      case 'verified':
        return VerificationStatus.verified;
      default:
        return VerificationStatus.unverified;
    }
  }

  static UserRole _parseRole(dynamic value) {
    switch (value as String?) {
      case 'driver':
        return UserRole.driver;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.passenger;
    }
  }

  factory AppUserModel.fromEntity(AppUser user) => AppUserModel(
    uid: user.uid,
    name: user.name,
    email: user.email,
    phone: user.phone,
    photoUrl: user.photoUrl,
    dateInscription: user.dateInscription,
    preferences: user.preferences,
    vehicles: user.vehicles,
    ridePreferences: user.ridePreferences,
    averageRating: user.averageRating,
    verification: user.verification,
    role: user.role,
    co2SavedKg: user.co2SavedKg,
    distanceSharedKm: user.distanceSharedKm,
  );
}

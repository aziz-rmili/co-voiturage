import 'package:equatable/equatable.dart';

import 'vehicle.dart';

enum VerificationStatus { unverified, pending, verified }

enum UserRole { passenger, driver, admin }

class AppUser extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String photoUrl;
  final DateTime dateInscription;
  final List<String> preferences;
  final List<Vehicle> vehicles;
  final Map<String, dynamic> ridePreferences;
  final double averageRating;
  final VerificationStatus verification;
  final UserRole role;
  final double co2SavedKg;
  final double distanceSharedKm;
  final int reportCount;
  final bool isBanned;
  final DateTime? bannedUntil;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl = '',
    required this.dateInscription,
    this.preferences = const [],
    this.vehicles = const [],
    this.ridePreferences = const {},
    this.averageRating = 0.0,
    this.verification = VerificationStatus.unverified,
    this.role = UserRole.passenger,
    this.co2SavedKg = 0.0,
    this.distanceSharedKm = 0.0,
    this.reportCount = 0,
    this.isBanned = false,
    this.bannedUntil,
  });

  bool get isDriver => role == UserRole.driver;
  bool get isVerifiedDriver =>
      isDriver && verification == VerificationStatus.verified;
  bool get isAdmin => role == UserRole.admin;
  bool get isPassenger => role == UserRole.passenger;
  bool get isCurrentlyBanned {
    if (isBanned) return true;
    if (bannedUntil == null) return false;
    return bannedUntil!.toUtc().isAfter(DateTime.now().toUtc());
  }

  /// Tags used across the app to represent the driver's ride preferences.
  ///
  /// These are derived from the structured `ridePreferences` saved in profile.
  /// Keep this mapping in the domain layer so the rest of the app can filter
  /// and display preferences without relying on ride documents.
  List<String> get ridePreferenceTags {
    final prefs = ridePreferences;
    final tags = <String>{};

    final smokingAllowed = prefs['smokingAllowed'] as bool?;
    if (smokingAllowed == false) tags.add('no_smoking');

    final petsAllowed = prefs['petsAllowed'] as bool?;
    if (petsAllowed == true) tags.add('pets_welcome');

    final luggageSize = prefs['luggageSize'] as String?;
    switch (luggageSize) {
      case 'smallBagOnly':
        tags.add('small_bag_only');
        break;
      case 'standardSuitcase':
        tags.add('medium_bag');
        break;
      case 'largeItems':
        tags.add('large_items');
        break;
    }

    final conversationLevel = prefs['conversationLevel'] as String?;
    if (conversationLevel == 'quietRide') tags.add('quiet_trip');
    if (conversationLevel == 'chatty') tags.add('chatty');

    final musicLevel = prefs['musicLevel'] as String?;
    if (musicLevel == 'quiet') tags.add('quiet_trip');

    final result = tags.toList()..sort();
    return result;
  }

  AppUser copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    DateTime? dateInscription,
    List<String>? preferences,
    List<Vehicle>? vehicles,
    Map<String, dynamic>? ridePreferences,
    double? averageRating,
    VerificationStatus? verification,
    UserRole? role,
    double? co2SavedKg,
    double? distanceSharedKm,
    int? reportCount,
    bool? isBanned,
    DateTime? bannedUntil,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      dateInscription: dateInscription ?? this.dateInscription,
      preferences: preferences ?? this.preferences,
      vehicles: vehicles ?? this.vehicles,
      ridePreferences: ridePreferences ?? this.ridePreferences,
      averageRating: averageRating ?? this.averageRating,
      verification: verification ?? this.verification,
      role: role ?? this.role,
      co2SavedKg: co2SavedKg ?? this.co2SavedKg,
      distanceSharedKm: distanceSharedKm ?? this.distanceSharedKm,
      reportCount: reportCount ?? this.reportCount,
      isBanned: isBanned ?? this.isBanned,
      bannedUntil: bannedUntil ?? this.bannedUntil,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    name,
    email,
    phone,
    photoUrl,
    dateInscription,
    preferences,
    vehicles,
    ridePreferences,
    averageRating,
    verification,
    role,
    co2SavedKg,
    distanceSharedKm,
  ];
}

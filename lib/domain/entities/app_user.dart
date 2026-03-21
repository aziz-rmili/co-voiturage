import 'package:equatable/equatable.dart';

enum VerificationStatus { unverified, pending, verified }

class AppUser extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String photoUrl;
  final DateTime dateInscription;
  final List<String> preferences;
  final double averageRating;
  final VerificationStatus verification;
  final double co2SavedKg;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl = '',
    required this.dateInscription,
    this.preferences = const [],
    this.averageRating = 0.0,
    this.verification = VerificationStatus.unverified,
    this.co2SavedKg = 0.0,
  });

  AppUser copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    DateTime? dateInscription,
    List<String>? preferences,
    double? averageRating,
    VerificationStatus? verification,
    double? co2SavedKg,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      dateInscription: dateInscription ?? this.dateInscription,
      preferences: preferences ?? this.preferences,
      averageRating: averageRating ?? this.averageRating,
      verification: verification ?? this.verification,
      co2SavedKg: co2SavedKg ?? this.co2SavedKg,
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
    averageRating,
    verification,
    co2SavedKg,
  ];
}

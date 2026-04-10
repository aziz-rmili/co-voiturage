import '../entities/app_user.dart';
import '../entities/driver_credentials.dart';

abstract class AuthRepository {
  Future<AppUser?> getCurrentUser();

  Future<AppUser> loginWithEmail({
    required String email,
    required String password,
  });

  // Creates a passenger account — verification stays unverified.
  Future<AppUser> registerPassenger({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  /// Creates a driver account (step 1) — verification unverified until
  /// credentials are submitted via [submitDriverCredentials].
  Future<AppUser> registerDriver({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  /// Submits driver license + photo — sets verification to pending.
  Future<void> submitDriverCredentials(DriverCredentials credentials);

  Future<void> sendPasswordResetEmail({required String email});
  Future<AppUser> loginWithGoogle();
  Future<void> logout();
  Stream<AppUser?> get authStateChanges;
}

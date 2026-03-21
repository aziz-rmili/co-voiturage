import '../entities/app_user.dart';

/// Contract that the data layer must implement.
/// The presentation layer depends only on this abstract interface.
abstract class AuthRepository {
  /// Returns the currently signed-in user, or null if unauthenticated.
  Future<AppUser?> getCurrentUser();

  /// Sign in with email + password. Returns the authenticated [AppUser].
  Future<AppUser> loginWithEmail({
    required String email,
    required String password,
  });

  /// Create a new account and write the [AppUser] document to Firestore.
  Future<AppUser> registerWithEmail({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  /// Trigger Firebase's password-reset email flow.
  Future<void> sendPasswordResetEmail({required String email});

  /// Sign in with Google OAuth. Creates Firestore doc on first sign-in.
  Future<AppUser> loginWithGoogle();

  /// Sign out from Firebase (and Google if applicable).
  Future<void> logout();

  /// Stream that emits the current user whenever auth state changes.
  Stream<AppUser?> get authStateChanges;
}

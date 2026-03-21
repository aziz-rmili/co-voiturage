import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/errors/exceptions.dart';
import '../models/app_user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AppUserModel> loginWithEmail({
    required String email,
    required String password,
  });

  Future<AppUserModel> registerWithEmail({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  Future<void> sendPasswordResetEmail({required String email});

  Future<AppUserModel> loginWithGoogle();

  Future<void> logout();

  Future<AppUserModel?> getCurrentUser();

  Stream<AppUserModel?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  static const String _usersCollection = 'users';

  AuthRemoteDataSourceImpl({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore,
       _googleSignIn = googleSignIn;

  // ── Login with email ──────────────────────────────────────────────────────

  @override
  Future<AppUserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return await _fetchUserDocument(credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  // ── Register with email ───────────────────────────────────────────────────

  @override
  Future<AppUserModel> registerWithEmail({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;

      // Update display name in Firebase Auth
      await user.updateDisplayName(name);

      // Create AppUser model for Firestore
      final appUser = AppUserModel(
        uid: user.uid,
        name: name,
        email: email,
        phone: phone,
        photoUrl: '',
        dateInscription: DateTime.now(),
        preferences: const [],
        averageRating: 0.0,
      );

      // Write user document to Firestore
      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .set(appUser.toMap());

      return appUser;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  // ── Password reset ────────────────────────────────────────────────────────

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  // ── Google sign-in ────────────────────────────────────────────────────────

  @override
  Future<AppUserModel> loginWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException(message: 'Google sign-in was cancelled.');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final firebaseUser = userCredential.user!;

      // Check if user document already exists (returning user)
      final docRef = _firestore
          .collection(_usersCollection)
          .doc(firebaseUser.uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        // First Google sign-in — create Firestore document
        final newUser = AppUserModel(
          uid: firebaseUser.uid,
          name: firebaseUser.displayName ?? '',
          email: firebaseUser.email ?? '',
          phone: firebaseUser.phoneNumber ?? '',
          photoUrl: firebaseUser.photoURL ?? '',
          dateInscription: DateTime.now(),
          preferences: const [],
          averageRating: 0.0,
        );
        await docRef.set(newUser.toMap());
        return newUser;
      }

      return AppUserModel.fromFirestore(doc);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  @override
  Future<void> logout() async {
    try {
      await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  // ── Current user ──────────────────────────────────────────────────────────

  @override
  Future<AppUserModel?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return await _fetchUserDocument(user.uid);
  }

  // ── Auth state stream ─────────────────────────────────────────────────────

  @override
  Stream<AppUserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return await _fetchUserDocument(user.uid);
    });
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<AppUserModel> _fetchUserDocument(String uid) async {
    final doc = await _firestore.collection(_usersCollection).doc(uid).get();
    if (!doc.exists) {
      throw const ServerException(
        message: 'User document not found in Firestore.',
      );
    }
    return AppUserModel.fromFirestore(doc);
  }

  AuthException _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return const AuthException(message: 'No account found for this email.');
      case 'wrong-password':
        return const AuthException(message: 'Incorrect password.');
      case 'invalid-email':
        return const AuthException(message: 'The email address is invalid.');
      case 'user-disabled':
        return const AuthException(message: 'This account has been disabled.');
      case 'email-already-in-use':
        return const AuthException(
          message: 'An account already exists for this email.',
        );
      case 'weak-password':
        return const AuthException(
          message: 'Password must be at least 6 characters.',
        );
      case 'too-many-requests':
        return const AuthException(
          message: 'Too many attempts. Please try again later.',
        );
      case 'network-request-failed':
        return const AuthException(
          message: 'Network error. Check your connection.',
        );
      default:
        return AuthException(
          message: e.message ?? 'An unexpected error occurred.',
        );
    }
  }
}

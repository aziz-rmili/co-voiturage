import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthDataSource {

  final FirebaseAuth auth;

  FirebaseAuthDataSource(this.auth);

  Future<UserCredential> signUp(
      String email,
      String password) {

    return auth.createUserWithEmailAndPassword(
        email: email,
        password: password);
  }

  Future<UserCredential> signIn(
      String email,
      String password) {

    return auth.signInWithEmailAndPassword(
        email: email,
        password: password);
  }

  Future<void> signOut() {
    return auth.signOut();
  }

}
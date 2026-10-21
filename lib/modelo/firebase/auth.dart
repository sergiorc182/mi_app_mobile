import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  FirebaseAuth get auth => FirebaseAuth.instance;

  User? get currentUser => auth.currentUser;

  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await auth.signOut();
  }
}

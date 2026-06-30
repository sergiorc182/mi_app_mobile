import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Use a getter to avoid premature initialization of FirebaseAuth.instance
  FirebaseAuth get auth => FirebaseAuth.instance;

  Future<UserCredential> loginAnonimo() async {
    return auth.signInAnonymously();
  }

  Future<void> logout() async {
    await auth.signOut();
  }
}

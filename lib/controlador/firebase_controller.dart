import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../modelo/firebase/firebase.dart';
import '../modelo/firebase/auth.dart';
import '../modelo/firebase/firestore.dart';

class FirebaseController {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  Future<FirebaseStatus> inicializar() async {
    try {
      // Firebase.initializeApp() is executed in main() before runApp().
      try {
        await _authService.loginAnonimo();
        debugPrint('Firebase Auth conectado');
      } on FirebaseAuthException catch (e) {
        debugPrint('Error Auth: $e');
        return FirebaseStatus.authError;
      }

      final collectionStatus = await _firestoreService.verificarColeccionUsers();
      await _firestoreService.semillarPreguntas();
      return collectionStatus;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        debugPrint('Error Firestore: $e');
        return FirebaseStatus.firestoreDenied;
      }
      debugPrint('Error Firebase: $e');
      return FirebaseStatus.firebaseError;
    } catch (e) {
      debugPrint('Error Firebase: $e');
      return FirebaseStatus.firebaseError;
    }
  }
}

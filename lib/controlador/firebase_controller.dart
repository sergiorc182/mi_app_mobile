import 'package:flutter/foundation.dart';

import '../modelo/firebase/firebase.dart';
import '../modelo/firebase/firestore.dart';

class FirebaseController {
  final FirestoreService _firestoreService = FirestoreService();

  Future<FirebaseStatus> inicializar() async {
    try {
      await FirebaseService.initialize();
      await _firestoreService.asegurarProductosIniciales();
      debugPrint('Firebase conectado');
      return FirebaseStatus.connected;
    } catch (e) {
      debugPrint('Error Firebase: $e');
      return FirebaseStatus.firebaseError;
    }
  }
}

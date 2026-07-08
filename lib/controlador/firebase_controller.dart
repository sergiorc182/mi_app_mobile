import 'package:flutter/foundation.dart';

import '../modelo/firebase/firebase.dart';

class FirebaseController {
  Future<FirebaseStatus> inicializar() async {
    try {
      await FirebaseService.initialize();
      debugPrint('Firebase conectado');
      return FirebaseStatus.connected;
    } catch (e) {
      debugPrint('Error Firebase: $e');
      return FirebaseStatus.firebaseError;
    }
  }
}

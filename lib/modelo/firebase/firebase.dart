import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';

enum FirebaseStatus {
  connected,
  firebaseError,
  authError,
  firestoreDenied,
  firestoreError,
  collectionMissing,
}

class FirebaseService {
  static Future<void> initialize() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }
}

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
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

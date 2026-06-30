import 'package:flutter/material.dart';
import '../controlador/firebase_controller.dart';
import 'login_vista.dart';
import '../modelo/firebase/firebase.dart';

class SplashVista extends StatefulWidget {
  const SplashVista({super.key});

  @override
  State<SplashVista> createState() => _SplashVistaState();
}

class _SplashVistaState extends State<SplashVista> {
  String _estado = 'Inicializando...';

  @override
  void initState() {
    super.initState();
    _iniciarFirebase();
  }

  Future<void> _iniciarFirebase() async {
    setState(() => _estado = 'Conectando a Firebase...');
    final controller = FirebaseController();
    final status = await controller
        .inicializar()
        .timeout(const Duration(seconds: 20))
        .catchError((_) => FirebaseStatus.firebaseError);

    if (!mounted) return;

    switch (status) {
      case FirebaseStatus.connected:
      case FirebaseStatus.collectionMissing:
        setState(() => _estado = 'Conectado. Preparando la app...');
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginVista()),
        );
        return;
      case FirebaseStatus.authError:
        setState(() => _estado = 'Error Auth. Revise configuración.');
        return;
      case FirebaseStatus.firestoreDenied:
        setState(() => _estado = 'Firestore sin permisos. Revise reglas.');
        return;
      case FirebaseStatus.firestoreError:
        setState(() => _estado = 'Error Firestore. Ver logs.');
        return;
      case FirebaseStatus.firebaseError:
        setState(() => _estado = 'Firebase no inicializado.');
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          _estado,
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

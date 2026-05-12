import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 👇 MVC
import 'controlador/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chatbot Compras',
      debugShowCheckedModeBanner: false,
      home: const InitScreen(),
    );
  }
}

// 🔥 PANTALLA INICIAL (verifica Firebase)
class InitScreen extends StatefulWidget {
  const InitScreen({super.key});

  @override
  State<InitScreen> createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen> {
  String estado = "Conectando a Firebase...";

  @override
  void initState() {
    super.initState();
    verificarFirebase();
  }

  Future<void> verificarFirebase() async {
    try {
      await FirebaseAuth.instance.signInAnonymously();

      setState(() {
        estado = "✅ Firebase conectado correctamente";
      });

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
        );
      }
    } catch (e) {
  print("🔥 ERROR FIREBASE: $e");

  setState(() {
    estado = "❌ Error conectando Firebase";
  });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          estado,
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
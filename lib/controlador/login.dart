import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 👇 chat
import 'chat.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController dniController = TextEditingController();
  bool isLoading = false;

  Future<void> loginConDNI() async {
    final dni = dniController.text.trim();

    if (dni.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresá tu DNI")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final db = FirebaseFirestore.instance;

      final result = await db
          .collection("users")
          .where("dni", isEqualTo: dni)
          .get();

      Map<String, dynamic> userData;

      if (result.docs.isNotEmpty) {
        // ✔ Usuario existe
        userData = result.docs.first.data();
      } else {
        // 🆕 Crear usuario
        userData = {
          "dni": dni,
          "createdAt": FieldValue.serverTimestamp(),
        };

        await db.collection("users").add(userData);
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(userData: userData),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error en el login")),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login DNI")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Ingresá tu DNI"),
            const SizedBox(height: 20),

            TextField(
              controller: dniController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "DNI",
              ),
            ),

            const SizedBox(height: 20),

            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: loginConDNI,
                    child: const Text("Ingresar"),
                  ),
          ],
        ),
      ),
    );
  }
}
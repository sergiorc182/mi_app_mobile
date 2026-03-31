import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      title: 'Flutter Demo con Firebase',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Mi primera app con Flutter y Firebase'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  // Instancias de Firebase
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  // Función para enviar evento a Firebase Analytics
  Future<void> _sendAnalyticsEvent() async {
    await analytics.logEvent(
      name: 'contador_incrementado',
      parameters: {'valor': _counter},
    );
    print('Evento enviado a Firebase Analytics: $_counter');
  }

  // Función para enviar dato a Firestore
  Future<void> _sendDataToFirestore() async {
    await firestore.collection('contador').add({
      'valor': _counter,
      'timestamp': FieldValue.serverTimestamp(),
    });
    print('Dato enviado a Firestore: $_counter');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Has presionado el botón esta cantidad de veces:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendAnalyticsEvent,
              child: const Text('Enviar evento a Firebase Analytics'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _sendDataToFirestore,
              child: const Text('Enviar dato a Firestore'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Incrementar',
        child: const Icon(Icons.add),
      ),
    );
  }
}
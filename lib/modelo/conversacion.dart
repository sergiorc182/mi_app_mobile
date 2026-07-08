import 'package:cloud_firestore/cloud_firestore.dart';

class Conversacion {
  final String id;
  final String titulo;
  final DateTime createdAt;

  Conversacion({
    required this.id,
    required this.titulo,
    required this.createdAt,
  });

  factory Conversacion.fromFirestore(Map<String, dynamic> data, String id) {
    return Conversacion(
      id: id,
      titulo: data['titulo']?.toString() ?? 'Nueva conversación',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'titulo': titulo,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

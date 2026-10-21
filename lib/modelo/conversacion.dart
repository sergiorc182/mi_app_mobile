import 'package:cloud_firestore/cloud_firestore.dart';

class Conversacion {
  final String id;
  final String usuarioId;
  final String titulo;
  final String estado;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversacion({
    required this.id,
    required this.usuarioId,
    required this.titulo,
    required this.estado,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversacion.fromFirestore(Map<String, dynamic> data, String id) {
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    return Conversacion(
      id: id,
      usuarioId: data['usuarioId']?.toString() ?? '',
      titulo: data['titulo']?.toString() ?? 'Nueva conversación',
      estado: data['estado']?.toString() ?? 'activa',
      createdAt: createdAt,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? createdAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'usuarioId': usuarioId,
      'titulo': titulo,
      'estado': estado,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

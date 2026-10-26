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

  Map<String, dynamic> toFirestore({bool useServerTimestamps = false}) {
    return {
      'usuarioId': usuarioId,
      'titulo': titulo,
      'estado': estado,
      'createdAt': useServerTimestamps
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
      'updatedAt': useServerTimestamps
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt),
    };
  }

  Conversacion copyWith({
    String? id,
    String? usuarioId,
    String? titulo,
    String? estado,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversacion(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      titulo: titulo ?? this.titulo,
      estado: estado ?? this.estado,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

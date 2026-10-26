import 'package:cloud_firestore/cloud_firestore.dart';

class Mensaje {
  final String id;
  final String autor;
  final String mensaje;
  final DateTime createdAt;
  final String tipo;
  final String? productoId;

  Mensaje({
    required this.id,
    required this.autor,
    required this.mensaje,
    required this.createdAt,
    required this.tipo,
    this.productoId,
  });

  factory Mensaje.fromFirestore(Map<String, dynamic> data, String id) {
    return Mensaje(
      id: id,
      autor: data['autor']?.toString() ?? 'user',
      mensaje: data['mensaje']?.toString() ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tipo: data['tipo']?.toString() ?? 'texto',
      productoId: data['productoId']?.toString(),
    );
  }

  Map<String, dynamic> toFirestore({bool useServerTimestamps = false}) {
    return {
      'autor': autor,
      'mensaje': mensaje,
      'createdAt': useServerTimestamps
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
      'tipo': tipo,
      if (productoId != null && productoId!.isNotEmpty)
        'productoId': productoId,
    };
  }

  Mensaje copyWith({
    String? id,
    String? autor,
    String? mensaje,
    DateTime? createdAt,
    String? tipo,
    String? productoId,
  }) {
    return Mensaje(
      id: id ?? this.id,
      autor: autor ?? this.autor,
      mensaje: mensaje ?? this.mensaje,
      createdAt: createdAt ?? this.createdAt,
      tipo: tipo ?? this.tipo,
      productoId: productoId ?? this.productoId,
    );
  }
}

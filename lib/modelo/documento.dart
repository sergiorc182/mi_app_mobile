import 'package:cloud_firestore/cloud_firestore.dart';

class Documento {
  final String id;
  final String nombre;
  final String storagePath;
  final String contentType;
  final String estado;
  final DateTime createdAt;
  final String? usuarioId;
  final String? negocioId;

  Documento({
    required this.id,
    required this.nombre,
    required this.storagePath,
    required this.contentType,
    required this.estado,
    required this.createdAt,
    this.usuarioId,
    this.negocioId,
  });

  factory Documento.fromFirestore(Map<String, dynamic> data, String id) {
    return Documento(
      id: id,
      nombre: data['nombre']?.toString() ?? '',
      storagePath: data['storagePath']?.toString() ?? '',
      contentType: data['contentType']?.toString() ?? 'application/pdf',
      estado: data['estado']?.toString() ?? 'activo',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      usuarioId: data['usuarioId']?.toString(),
      negocioId: data['negocioId']?.toString(),
    );
  }

  Map<String, dynamic> toFirestore({bool useServerTimestamps = false}) {
    return {
      'nombre': nombre,
      'storagePath': storagePath,
      'contentType': contentType,
      'estado': estado,
      if (usuarioId != null && usuarioId!.isNotEmpty) 'usuarioId': usuarioId,
      if (negocioId != null && negocioId!.isNotEmpty) 'negocioId': negocioId,
      'createdAt': useServerTimestamps
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
    };
  }

  Documento copyWith({
    String? id,
    String? nombre,
    String? storagePath,
    String? contentType,
    String? estado,
    DateTime? createdAt,
    String? usuarioId,
    String? negocioId,
  }) {
    return Documento(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      storagePath: storagePath ?? this.storagePath,
      contentType: contentType ?? this.contentType,
      estado: estado ?? this.estado,
      createdAt: createdAt ?? this.createdAt,
      usuarioId: usuarioId ?? this.usuarioId,
      negocioId: negocioId ?? this.negocioId,
    );
  }
}

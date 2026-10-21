import 'package:cloud_firestore/cloud_firestore.dart';

class Documento {
  final String id;
  final String nombre;
  final String storagePath;
  final String contentType;
  final String estado;
  final DateTime createdAt;

  Documento({
    required this.id,
    required this.nombre,
    required this.storagePath,
    required this.contentType,
    required this.estado,
    required this.createdAt,
  });

  factory Documento.fromFirestore(Map<String, dynamic> data, String id) {
    return Documento(
      id: id,
      nombre: data['nombre']?.toString() ?? '',
      storagePath: data['storagePath']?.toString() ?? '',
      contentType: data['contentType']?.toString() ?? '',
      estado: data['estado']?.toString() ?? 'activo',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'storagePath': storagePath,
      'contentType': contentType,
      'estado': estado,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

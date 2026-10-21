import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  final String id;
  final String nombre;
  final String apellido;
  final String dni;
  final String email;
  final String fotoPerfil;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool activo;

  Usuario({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.dni,
    required this.email,
    required this.fotoPerfil,
    required this.createdAt,
    required this.updatedAt,
    required this.activo,
  });

  factory Usuario.fromFirestore(Map<String, dynamic> data, String docId) {
    return Usuario(
      id: docId,
      nombre: data['nombre']?.toString() ?? '',
      apellido: data['apellido']?.toString() ?? '',
      dni: data['dni']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      fotoPerfil: data['fotoPerfil']?.toString() ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      activo: data['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'dni': dni,
      'email': email,
      'fotoPerfil': fotoPerfil,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'activo': activo,
    };
  }
}

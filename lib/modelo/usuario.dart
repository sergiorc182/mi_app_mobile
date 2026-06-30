import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  final String id;
  final String dni;
  final String? email;
  final String nombre;
  final DateTime createdAt;
  final String? imagenCara;

  Usuario({
    required this.id,
    required this.dni,
    this.email,
    required this.nombre,
    required this.createdAt,
    this.imagenCara,
  });

  Usuario copyWith({
    String? id,
    String? dni,
    String? email,
    String? nombre,
    DateTime? createdAt,
    String? imagenCara,
  }) {
    return Usuario(
      id: id ?? this.id,
      dni: dni ?? this.dni,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      createdAt: createdAt ?? this.createdAt,
      imagenCara: imagenCara ?? this.imagenCara,
    );
  }

  factory Usuario.fromMap(Map<String, dynamic> data) {
    final createdAtValue = data['createdAt'];
    final createdAt = createdAtValue is Timestamp
        ? createdAtValue.toDate()
        : DateTime.tryParse(createdAtValue?.toString() ?? '') ??
            DateTime.now();

    return Usuario(
      id: data['id']?.toString() ?? '',
      dni: data['dni']?.toString() ?? '',
      email: data['email']?.toString(),
      nombre: data['nombre']?.toString() ?? '',
      createdAt: createdAt,
      imagenCara: data['imagenCara']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dni': dni,
      'email': email ?? '',
      'nombre': nombre,
      'createdAt': createdAt.toIso8601String(),
      'imagenCara': imagenCara ?? '',
    };
  }

  factory Usuario.fromFirestore(Map<String, dynamic> data, String docId) {
    return Usuario(
      id: docId,
      dni: data['dni'] as String? ?? '',
      email: data['email'] as String?,
      nombre: data['nombre'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      imagenCara: data['imagenCara'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'dni': dni,
      'email': email ?? '',
      'nombre': nombre,
      'createdAt': Timestamp.fromDate(createdAt),
      'imagenCara': imagenCara ?? '',
    };
  }
}

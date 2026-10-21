class Categoria {
  final String id;
  final String nombre;
  final String descripcion;
  final bool activo;

  Categoria({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.activo,
  });

  factory Categoria.fromFirestore(Map<String, dynamic> data, String id) {
    return Categoria(
      id: id,
      nombre: data['nombre']?.toString() ?? '',
      descripcion: data['descripcion']?.toString() ?? '',
      activo: data['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'activo': activo,
    };
  }
}

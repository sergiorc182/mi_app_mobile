class Producto {
  final String id;
  final String nombre;
  final String categoria;
  final String marca;
  final double precio;
  final int stock;
  final String descripcion;
  final String imagen;
  final bool activo;

  Producto({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.marca,
    required this.precio,
    required this.stock,
    required this.descripcion,
    required this.imagen,
    required this.activo,
  });

  factory Producto.fromFirestore(Map<String, dynamic> data, String id) {
    return Producto(
      id: id,
      nombre: data['nombre']?.toString() ?? '',
      categoria: data['categoria']?.toString() ?? '',
      marca: data['marca']?.toString() ?? '',
      precio: (data['precio'] as num?)?.toDouble() ?? 0.0,
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      descripcion: data['descripcion']?.toString() ?? '',
      imagen: data['imagen']?.toString() ?? '',
      activo: data['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'categoria': categoria,
      'marca': marca,
      'precio': precio,
      'stock': stock,
      'descripcion': descripcion,
      'imagen': imagen,
      'activo': activo,
    };
  }
}

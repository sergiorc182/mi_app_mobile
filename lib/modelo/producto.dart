class Producto {
  final String id;
  final String categoria;
  final String marca;
  final String modelo;
  final String especificacionClave;
  final double precioUSD;
  final String enlaceCompra;

  Producto({
    required this.id,
    required this.categoria,
    required this.marca,
    required this.modelo,
    required this.especificacionClave,
    required this.precioUSD,
    required this.enlaceCompra,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? '',
      marca: json['marca']?.toString() ?? '',
      modelo: json['modelo']?.toString() ?? '',
      especificacionClave: (json['especificacion_clave'] ?? json['especificacionClave'])?.toString() ?? '',
      precioUSD: (json['precio_usd'] ?? json['precioUSD'] as num?)?.toDouble() ?? 0.0,
      enlaceCompra: (json['enlace_compra'] ?? json['enlaceCompra'])?.toString() ?? '',
    );
  }

  factory Producto.fromFirestore(Map<String, dynamic> data, String docId) {
    return Producto(
      id: docId,
      categoria: data['categoria']?.toString() ?? '',
      marca: data['marca']?.toString() ?? '',
      modelo: data['modelo']?.toString() ?? '',
      especificacionClave: (data['especificacion_clave'] ?? data['especificacionClave'])?.toString() ?? '',
      precioUSD: (data['precio_usd'] ?? data['precioUSD'] as num?)?.toDouble() ?? 0.0,
      enlaceCompra: (data['enlace_compra'] ?? data['enlaceCompra'])?.toString() ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'categoria': categoria,
      'marca': marca,
      'modelo': modelo,
      'especificacion_clave': especificacionClave,
      'precio_usd': precioUSD,
      'enlace_compra': enlaceCompra,
    };
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'categoria': categoria,
    'marca': marca,
    'modelo': modelo,
    'especificacion_clave': especificacionClave,
    'precio_usd': precioUSD,
    'enlace_compra': enlaceCompra,
  };

  String get presentacion =>
      '$marca $modelo - \$${precioUSD.toStringAsFixed(0)} USD\n'
      '  $especificacionClave\n'
      '  [$enlaceCompra]';
}

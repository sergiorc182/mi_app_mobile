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
      id: json['id'] as String,
      categoria: json['categoria'] as String,
      marca: json['marca'] as String,
      modelo: json['modelo'] as String,
      especificacionClave: json['especificacion_clave'] as String,
      precioUSD: (json['precio_usd'] as num).toDouble(),
      enlaceCompra: json['enlace_compra'] as String,
    );
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

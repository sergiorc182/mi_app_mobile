import 'package:cloud_firestore/cloud_firestore.dart';

class Producto {
  final String id;
  final String nombre;
  final String descripcion;
  final String marca;
  final String categoriaId;
  final double precio;
  final String moneda;
  final int stock;
  final bool activo;
  final String sku;
  final String imagenUrl;
  final String urlExterna;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.marca,
    required this.categoriaId,
    required this.precio,
    required this.moneda,
    required this.stock,
    required this.activo,
    required this.sku,
    required this.imagenUrl,
    required this.urlExterna,
    this.createdAt,
    this.updatedAt,
  });

  factory Producto.fromFirestore(Map<String, dynamic> data, String id) {
    return Producto(
      id: id,
      nombre: data['nombre']?.toString() ?? data['modelo']?.toString() ?? '',
      descripcion: data['descripcion']?.toString() ??
          data['especificacion_clave']?.toString() ??
          data['especificacionClave']?.toString() ??
          '',
      marca: data['marca']?.toString() ?? '',
      categoriaId: data['categoriaId']?.toString() ??
          data['categoria']?.toString() ??
          '',
      precio: (data['precio'] as num?)?.toDouble() ??
          (data['precio_usd'] as num?)?.toDouble() ??
          0,
      moneda: data['moneda']?.toString() ?? 'USD',
      stock: (data['stock'] as num?)?.toInt() ?? 1,
      activo: data['activo'] as bool? ?? true,
      sku: data['sku']?.toString() ?? '',
      imagenUrl: data['imagenUrl']?.toString() ?? '',
      urlExterna: data['urlExterna']?.toString() ??
          data['enlace_compra']?.toString() ??
          '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ??
          json['modelo'] as String? ??
          '',
      descripcion: json['descripcion'] as String? ??
          json['especificacion_clave'] as String? ??
          json['especificacionClave'] as String? ??
          '',
      marca: json['marca'] as String? ?? '',
      categoriaId: json['categoriaId'] as String? ??
          json['categoria'] as String? ??
          '',
      precio: (json['precio'] as num?)?.toDouble() ??
          (json['precio_usd'] as num?)?.toDouble() ??
          0,
      moneda: json['moneda'] as String? ?? 'USD',
      stock: (json['stock'] as num?)?.toInt() ?? 1,
      activo: json['activo'] as bool? ?? true,
      sku: json['sku'] as String? ?? json['id'] as String? ?? '',
      imagenUrl: json['imagenUrl'] as String? ?? '',
      urlExterna: json['urlExterna'] as String? ??
          json['enlace_compra'] as String? ??
          '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'marca': marca,
      'categoriaId': categoriaId,
      'precio': precio,
      'moneda': moneda,
      'stock': stock,
      'activo': activo,
      'sku': sku,
      'imagenUrl': imagenUrl,
      'urlExterna': urlExterna,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  String get modelo => nombre;

  String get categoria => _nombreLegible(categoriaId);

  static String _nombreLegible(String valor) {
    if (valor.isEmpty) return '';
    return valor
        .replaceAll('_', ' ')
        .split(' ')
        .map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}')
        .join(' ');
  }

  String get presentacion =>
      '$marca $nombre - \$${precio.toStringAsFixed(0)} $moneda\n'
      '  $descripcion\n'
      '  [$urlExterna]';
}

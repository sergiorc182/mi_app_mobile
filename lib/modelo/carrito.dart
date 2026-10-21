import 'package:cloud_firestore/cloud_firestore.dart';

class ItemCarrito {
  final String productoId;
  final int cantidad;
  final DateTime addedAt;

  ItemCarrito({
    required this.productoId,
    required this.cantidad,
    required this.addedAt,
  });

  factory ItemCarrito.fromFirestore(Map<String, dynamic> data, String id) {
    return ItemCarrito(
      productoId: id,
      cantidad: (data['cantidad'] as num?)?.toInt() ?? 1,
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'cantidad': cantidad,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }
}

class Carrito {
  final String id;
  final String estado;
  final String moneda;
  final DateTime updatedAt;
  final List<ItemCarrito> items;

  Carrito({
    required this.id,
    required this.estado,
    required this.moneda,
    required this.updatedAt,
    this.items = const [],
  });

  factory Carrito.fromFirestore(
    Map<String, dynamic> data,
    String id, {
    List<ItemCarrito> items = const [],
  }) {
    return Carrito(
      id: id,
      estado: data['estado']?.toString() ?? 'abierto',
      moneda: data['moneda']?.toString() ?? 'USD',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      items: items,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'estado': estado,
      'moneda': moneda,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

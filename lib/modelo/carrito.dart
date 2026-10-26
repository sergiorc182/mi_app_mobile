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
    final cant = (data['cantidad'] as num?)?.toInt() ?? 1;
    return ItemCarrito(
      productoId: id,
      cantidad: cant > 0 ? cant : 1,
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore({bool useServerTimestamps = false}) {
    return {
      'cantidad': cantidad > 0 ? cantidad : 1,
      'addedAt': useServerTimestamps
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(addedAt),
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
      estado: data['estado']?.toString() ?? 'activo',
      moneda: data['moneda']?.toString() ?? 'ARS',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      items: items,
    );
  }

  Map<String, dynamic> toFirestore({bool useServerTimestamps = false}) {
    return {
      'estado': estado,
      'moneda': moneda,
      'updatedAt': useServerTimestamps
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt),
    };
  }
}

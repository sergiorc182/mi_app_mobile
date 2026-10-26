import 'package:cloud_firestore/cloud_firestore.dart';

class ItemPedido {
  final String productoId;
  final String nombre;
  final String sku;
  final double precioUnitario;
  final int cantidad;

  ItemPedido({
    required this.productoId,
    required this.nombre,
    required this.sku,
    required this.precioUnitario,
    required this.cantidad,
  });

  factory ItemPedido.fromMap(Map<String, dynamic> data) {
    return ItemPedido(
      productoId: data['productoId']?.toString() ?? '',
      nombre: data['nombre']?.toString() ?? '',
      sku: data['sku']?.toString() ?? '',
      precioUnitario: (data['precioUnitario'] as num?)?.toDouble() ?? 0,
      cantidad: (data['cantidad'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productoId': productoId,
      'nombre': nombre,
      'sku': sku,
      'precioUnitario': precioUnitario,
      'cantidad': cantidad,
    };
  }
}

class Pedido {
  final String id;
  final String usuarioId;
  final String estado;
  final String moneda;
  final double subtotal;
  final double costoEnvio;
  final double total;
  final String metodoPago;
  final String estadoPago;
  final String? pagoReferencia;
  final String? telegramChatId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ItemPedido> items;

  Pedido({
    required this.id,
    required this.usuarioId,
    required this.estado,
    required this.moneda,
    required this.subtotal,
    required this.costoEnvio,
    required this.total,
    required this.metodoPago,
    required this.estadoPago,
    this.pagoReferencia,
    this.telegramChatId,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  factory Pedido.fromFirestore(Map<String, dynamic> data, String id) {
    final itemsRaw = data['items'] as List<dynamic>? ?? const [];
    return Pedido(
      id: id,
      usuarioId: data['usuarioId']?.toString() ?? '',
      estado: data['estado']?.toString() ?? 'pendiente',
      moneda: data['moneda']?.toString() ?? 'ARS',
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0,
      costoEnvio: (data['costoEnvio'] as num?)?.toDouble() ?? 0,
      total: (data['total'] as num?)?.toDouble() ?? 0,
      metodoPago: data['metodoPago']?.toString() ?? '',
      estadoPago: data['estadoPago']?.toString() ?? 'pendiente',
      pagoReferencia: data['pagoReferencia']?.toString(),
      telegramChatId: data['telegramChatId']?.toString(),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      items: itemsRaw
          .whereType<Map<String, dynamic>>()
          .map((e) => ItemPedido.fromMap(e))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore({bool useServerTimestamps = false}) {
    return {
      'usuarioId': usuarioId,
      'estado': estado,
      'moneda': moneda,
      'subtotal': subtotal,
      'costoEnvio': costoEnvio,
      'total': total,
      'metodoPago': metodoPago,
      'estadoPago': estadoPago,
      if (pagoReferencia != null && pagoReferencia!.isNotEmpty)
        'pagoReferencia': pagoReferencia,
      if (telegramChatId != null && telegramChatId!.isNotEmpty)
        'telegramChatId': telegramChatId,
      'createdAt': useServerTimestamps
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
      'updatedAt': useServerTimestamps
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt),
      'items': items.map((e) => e.toMap()).toList(),
    };
  }

  Pedido copyWith({
    String? id,
    String? usuarioId,
    String? estado,
    String? moneda,
    double? subtotal,
    double? costoEnvio,
    double? total,
    String? metodoPago,
    String? estadoPago,
    String? pagoReferencia,
    String? telegramChatId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ItemPedido>? items,
  }) {
    return Pedido(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      estado: estado ?? this.estado,
      moneda: moneda ?? this.moneda,
      subtotal: subtotal ?? this.subtotal,
      costoEnvio: costoEnvio ?? this.costoEnvio,
      total: total ?? this.total,
      metodoPago: metodoPago ?? this.metodoPago,
      estadoPago: estadoPago ?? this.estadoPago,
      pagoReferencia: pagoReferencia ?? this.pagoReferencia,
      telegramChatId: telegramChatId ?? this.telegramChatId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }
}

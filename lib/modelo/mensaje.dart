import 'package:cloud_firestore/cloud_firestore.dart';

class Mensaje {
  final String id;
  final String conversacionId;
  final String autor;
  final String mensaje;
  final DateTime fecha;

  Mensaje({
    required this.id,
    required this.conversacionId,
    required this.autor,
    required this.mensaje,
    required this.fecha,
  });

  factory Mensaje.fromFirestore(Map<String, dynamic> data, String id) {
    return Mensaje(
      id: id,
      conversacionId: data['conversacionId']?.toString() ?? '',
      autor: data['autor']?.toString() ?? 'user',
      mensaje: data['mensaje']?.toString() ?? '',
      fecha: (data['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'conversacionId': conversacionId,
      'autor': autor,
      'mensaje': mensaje,
      'fecha': Timestamp.fromDate(fecha),
    };
  }
}

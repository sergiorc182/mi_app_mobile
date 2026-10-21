import 'package:cloud_firestore/cloud_firestore.dart';

class Configuracion {
  final String nombreNegocio;
  final String moneda;
  final String mensajeBienvenida;
  final String instruccionesAsistente;
  final String urlWeb;
  final String urlTelegram;
  final bool catalogoHabilitado;
  final bool comprasHabilitadas;
  final DateTime? updatedAt;

  Configuracion({
    required this.nombreNegocio,
    required this.moneda,
    required this.mensajeBienvenida,
    required this.instruccionesAsistente,
    required this.urlWeb,
    required this.urlTelegram,
    required this.catalogoHabilitado,
    required this.comprasHabilitadas,
    this.updatedAt,
  });

  factory Configuracion.fromFirestore(Map<String, dynamic> data) {
    return Configuracion(
      nombreNegocio: data['nombreNegocio']?.toString() ?? '',
      moneda: data['moneda']?.toString() ?? 'USD',
      mensajeBienvenida: data['mensajeBienvenida']?.toString() ?? '',
      instruccionesAsistente: data['instruccionesAsistente']?.toString() ?? '',
      urlWeb: data['urlWeb']?.toString() ?? '',
      urlTelegram: data['urlTelegram']?.toString() ?? '',
      catalogoHabilitado: data['catalogoHabilitado'] as bool? ?? true,
      comprasHabilitadas: data['comprasHabilitadas'] as bool? ?? true,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombreNegocio': nombreNegocio,
      'moneda': moneda,
      'mensajeBienvenida': mensajeBienvenida,
      'instruccionesAsistente': instruccionesAsistente,
      'urlWeb': urlWeb,
      'urlTelegram': urlTelegram,
      'catalogoHabilitado': catalogoHabilitado,
      'comprasHabilitadas': comprasHabilitadas,
      'updatedAt': Timestamp.fromDate(updatedAt ?? DateTime.now()),
    };
  }
}

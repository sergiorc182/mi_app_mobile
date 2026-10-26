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
      nombreNegocio: data['nombreNegocio']?.toString() ?? 'Mi Tienda',
      moneda: data['moneda']?.toString() ?? 'ARS',
      mensajeBienvenida: data['mensajeBienvenida']?.toString() ?? '¡Hola! ¿Qué estás buscando hoy?',
      instruccionesAsistente: data['instruccionesAsistente']?.toString() ?? 'Ayudá al usuario a encontrar productos del catálogo.',
      urlWeb: data['urlWeb']?.toString() ?? '',
      urlTelegram: data['urlTelegram']?.toString() ?? '',
      catalogoHabilitado: data['catalogoHabilitado'] as bool? ?? true,
      comprasHabilitadas: data['comprasHabilitadas'] as bool? ?? false,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore({bool useServerTimestamps = false}) {
    return {
      'nombreNegocio': nombreNegocio,
      'moneda': moneda,
      'mensajeBienvenida': mensajeBienvenida,
      'instruccionesAsistente': instruccionesAsistente,
      'urlWeb': urlWeb,
      'urlTelegram': urlTelegram,
      'catalogoHabilitado': catalogoHabilitado,
      'comprasHabilitadas': comprasHabilitadas,
      'updatedAt': useServerTimestamps
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt ?? DateTime.now()),
    };
  }

  Configuracion copyWith({
    String? nombreNegocio,
    String? moneda,
    String? mensajeBienvenida,
    String? instruccionesAsistente,
    String? urlWeb,
    String? urlTelegram,
    bool? catalogoHabilitado,
    bool? comprasHabilitadas,
    DateTime? updatedAt,
  }) {
    return Configuracion(
      nombreNegocio: nombreNegocio ?? this.nombreNegocio,
      moneda: moneda ?? this.moneda,
      mensajeBienvenida: mensajeBienvenida ?? this.mensajeBienvenida,
      instruccionesAsistente:
          instruccionesAsistente ?? this.instruccionesAsistente,
      urlWeb: urlWeb ?? this.urlWeb,
      urlTelegram: urlTelegram ?? this.urlTelegram,
      catalogoHabilitado: catalogoHabilitado ?? this.catalogoHabilitado,
      comprasHabilitadas: comprasHabilitadas ?? this.comprasHabilitadas,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

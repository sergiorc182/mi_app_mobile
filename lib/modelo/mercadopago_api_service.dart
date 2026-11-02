import 'dart:convert';
import 'package:http/http.dart' as http;

class MercadoPagoApiService {
  // Cambia esta IP según cómo pruebes:
  // - Emulador Android: http://10.0.2.2:8000
  // - Celular físico en misma WiFi: http://IP_DE_TU_PC:8000
  // - Misma PC (web/desktop): http://127.0.0.1:8000
  static const String baseUrl = 'http://127.0.0.1:8000';

  Future<String?> crearPreferencia({
    required String id,
    required String marca,
    required String modelo,
    required String especificacionClave,
    required double precioUsd,
  }) async {
    final uri = Uri.parse('$baseUrl/crear-preferencia');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': id,
        'marca': marca,
        'modelo': modelo,
        'especificacion_clave': especificacionClave,
        'precio_usd': precioUsd,
      }),
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return data['init_point'] ?? data['sandbox_init_point'];
    }
    throw Exception('Error al crear preferencia MP: ${resp.body}');
  }
}

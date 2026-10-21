import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatService {
  final String _apiUrl = "https://api.groq.com/openai/v1/chat/completions";

  String _systemPrompt(String fechaHoy) =>
      "Sos VendedorVirtual, un asistente inteligente de compras de electrodomésticos "
      "y tecnología. Hoy es $fechaHoy. Tus responsabilidades son: "
      "1) Comprender las necesidades del usuario mediante conversación. "
      "2) Hacer preguntas específicas para acotar la búsqueda. "
      "3) Recomendar productos basándote en la información que el backend te "
      "proporcione (catálogo de productos). "
      "4) Mostrar los enlaces de compra cuando estén disponibles. "
      "5) Guiar al usuario en el proceso comercial hasta la confirmación. "
      "NO inventes productos, precios, stock, URLs ni información técnica: "
      "si el catálogo no lo tiene, decís que no está disponible o pedís "
      "ajustar la búsqueda. "
      "ESTILO DE RESPUESTA: sé BREVE y directo, pensado para pantalla de "
      "celular. Respondé en 2 a 4 frases cortas. Usá listas con viñetas si "
      "hay más de una opción o dato clave. Sin introducciones tipo '¡claro!', "
      "sin despedidas largas ni repeticiones. Lo importante primero: precios, "
      "disponibilidad y enlace si lo hay. Iniciá siempre con: '¿Qué estás "
      "buscando hoy?' Respondé siempre en español, claro y profesional.";

  static String fechaHoy() {
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    final now = DateTime.now();
    return '${now.day} de ${meses[now.month - 1]} de ${now.year}';
  }

  Future<String> sendMessage(String userMessage, List<Map<String, String>> chatHistory) async {
    final String? apiKey = dotenv.env['GROQ_API_KEY'];

    if (apiKey == null) {
      throw Exception("API Key no configurada en el archivo .env");
    }

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: jsonEncode({
        "model": "qwen/qwen3.8-27b",
        "messages": [
          {"role": "system", "content": _systemPrompt(fechaHoy())},
          ...chatHistory,
          {"role": "user", "content": userMessage}
        ],
        "temperature": 0.7,
        "max_tokens": 500,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Error en API Groq: ${response.statusCode} - ${response.body}');
    }
  }
}
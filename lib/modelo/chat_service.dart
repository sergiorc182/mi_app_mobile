import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatService {
  final String _apiUrl = "https://api.groq.com/openai/v1/chat/completions";

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
        "model": "llama-3.1-8b-instant",
        "messages": [
          {"role": "system", "content": "Sos un asistente inteligente de compras. Tus responsabilidades son: 1) Comprender las necesidades del usuario mediante conversación. 2) Hacer preguntas específicas para acotar la búsqueda. 3) Recomendar productos adecuados basados en la información que el backend te proporcione. 4) Consultar información de documentos PDF cuando el backend la ponga a tu disposición. 5) Mostrar enlaces de compra cuando el backend los provea. 6) Guiar al usuario en el proceso comercial hasta la confirmación. NO inventes productos, precios, stock, URLs ni información técnica que el backend no te haya dado. Iniciá siempre con: '¿Qué estás buscando hoy?' Respondé siempre en español, claro y profesional."},
          ...chatHistory,
          {"role": "user", "content": userMessage}
        ],
        "temperature": 0.7,
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

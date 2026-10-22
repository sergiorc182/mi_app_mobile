import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatService {
  final String _apiUrl = "https://api.groq.com/openai/v1/chat/completions";
  static const String _modeloPorDefecto = 'qwen/qwen3.8-27b';
  static const Duration _timeout = Duration(seconds: 30);

  String get _modelo {
    final configurado = dotenv.env['GROQ_MODELO'];
    if (configurado == null || configurado.trim().isEmpty) {
      return _modeloPorDefecto;
    }
    return configurado.trim();
  }

  String _systemPrompt(String fechaHoy) =>
      "Sos VendedorVirtual, un asistente inteligente de compras de electrodomésticos "
      "y tecnología. Hoy es $fechaHoy. Tus responsabilidades son: "
      "1) Comprender las necesidades del usuario mediante conversación. "
      "2) Hacer preguntas específicas para acotar la búsqueda. "
      "3) Recomendar productos basándote en la información que el backend te "
      "proporcione (catálogo de productos). "
      "4) Mostrar los enlaces de compra cuando estén disponibles. "
      "5) Guiar al usuario activamente en el proceso comercial hasta la confirmación de la compra. "
      "En cada respuesta, intentá concretar la venta: ofrecé avanzar al siguiente paso "
      "(pasar el enlace de compra, confirmar el producto elegido, resolver dudas de precio o envío). "
      "Si el usuario duda entre opciones, recomenda una concreta y justificá brevemente por qué. "
      "Si el producto que pide no está disponible o no hay stock, decile claramente "
      "que no hay stock. "
      "ALCANCE ESTRICTO: tu único tema es la venta de electrodomésticos y tecnología "
      "del catálogo. Si te preguntan algo ajeno a las ventas (clima, deportes, "
      "política, programación, chistes, tareas, temas personales, etc.), no lo "
      "respondas: avisá amablemente que solo podés ayudar con la compra de productos "
      "y redirigí la conversación a qué quiere comprar. No des opiniones ni información "
      "general fuera de las ventas. "
      "NO inventes productos, precios, stock, URLs ni información técnica. "
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

  Future<String> generarTitulo(String primerMensaje) async {
    final String? apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null) return '';

    try {
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $apiKey",
            },
            body: jsonEncode({
              "model": _modelo,
              "messages": [
                {
                  "role": "system",
                  "content": "Generá un título muy corto (máximo 4 palabras) que "
                      "resuma qué quiere comprar el usuario en su primer mensaje. "
                      "Respondé SOLO con el título, sin comillas ni puntuación final.",
                },
                {"role": "user", "content": primerMensaje},
              ],
              "temperature": 0.3,
              "max_tokens": 20,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final titulo = (data['choices'][0]['message']['content'] as String)
            .trim()
            .replaceAll(RegExp(r'''^["']+|["']+$'''), '')
            .replaceAll(RegExp(r'[.\n]+$'), '')
            .trim();
        return titulo.length > 40 ? titulo.substring(0, 40).trim() : titulo;
      }
    } catch (_) {
      return '';
    }
    return '';
  }

  /// Construye el prompt de sistema único con los datos de contexto.
  /// El contexto va dentro del primer mensaje 'system' porque los providers
  /// OpenAI-compatibles esperan que el system prompt sea el primero de la lista.
  String _promptSistema({
    String? contextoCatalogo,
    String? contextoInfo,
  }) {
    final buffer = StringBuffer(_systemPrompt(fechaHoy()));
    if (contextoCatalogo != null && contextoCatalogo.trim().isNotEmpty) {
      buffer.write('\n\nPRODUCTOS DISPONIBLES PARA ESTA CONSULTA:\n');
      buffer.write(contextoCatalogo.trim());
      buffer.write(
        '\nUsá esta información para responder. No inventes productos que no '
        'estén en esta lista.',
      );
    }
    if (contextoInfo != null && contextoInfo.trim().isNotEmpty) {
      buffer.write(
        '\n\nINFORMACIÓN DEL ASISTENTE (documento de referencia del negocio):\n',
      );
      buffer.write(contextoInfo.trim());
      buffer.write(
        '\nUsá esta información para responder sobre políticas, garantía, '
        'envíos y precios.',
      );
    }
    return buffer.toString();
  }

  Future<String> sendMessage(
    String userMessage,
    List<Map<String, String>> chatHistory, {
    String? contextoCatalogo,
    String? contextoInfo,
  }) async {
    final String? apiKey = dotenv.env['GROQ_API_KEY'];

    if (apiKey == null) {
      throw Exception("API Key no configurada en el archivo .env");
    }

    final response = await http
        .post(
          Uri.parse(_apiUrl),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $apiKey",
          },
          body: jsonEncode({
            "model": _modelo,
            "messages": [
              {
                "role": "system",
                "content": _promptSistema(
                  contextoCatalogo: contextoCatalogo,
                  contextoInfo: contextoInfo,
                ),
              },
              ...chatHistory,
              {"role": "user", "content": userMessage}
            ],
            "temperature": 0.7,
            "max_tokens": 500,
          }),
        )
        .timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Error en API Groq: ${response.statusCode} - ${response.body}');
    }
  }
}
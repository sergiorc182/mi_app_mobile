"""VendedorVirtual - Bot de Telegram.

Espejo de la logica de la app Flutter: mismo prompt, mismo catalogo
(assets/catalogo.json), mismo modelo de Groq, sin busqueda web.
Long polling: se ejecuta localmente y escucha mensajes.

Para usarlo:
  1. Crear el bot con @BotFather y copiar el token en el archivo .env
     como TELEGRAM_BOT_TOKEN=...
  2. pip install -r requirements.txt
  3. python bot.py
"""

import json
import os
from datetime import datetime
from pathlib import Path

import requests
from dotenv import load_dotenv
from telegram import Update
from telegram.constants import ChatAction
from telegram.ext import (
    Application,
    CommandHandler,
    ContextTypes,
    MessageHandler,
    filters,
)

PROJECT_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(PROJECT_ROOT / ".env")

GROQ_API_KEY = os.getenv("GROQ_API_KEY", "")
TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN", "")
GROQ_MODELO = os.getenv("GROQ_MODELO", "qwen/qwen3.8-27b")
GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"
MAX_TOKENS = int(os.getenv("GROQ_MAX_TOKENS", "500"))

MESES = [
    "enero", "febrero", "marzo", "abril", "mayo", "junio",
    "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre",
]

_catalogo: list = []
# chat_id -> lista de mensajes {'role': 'user'|'assistant', 'content': ...}
_historial: dict = {}


def fecha_hoy() -> str:
    now = datetime.now()
    return f"{now.day} de {MESES[now.month - 1]} de {now.year}"


def system_prompt() -> str:
    return (
        "Sos VendedorVirtual, un asistente inteligente de compras de electrodomesticos "
        f"y tecnologia. Hoy es {fecha_hoy()}. Tus responsabilidades son: "
        "1) Comprender las necesidades del usuario mediante conversacion. "
        "2) Hacer preguntas especificas para acotar la busqueda. "
        "3) Recomendar productos basandote en la informacion que el backend te "
        "proporcione (catalogo de productos). "
        "4) Mostrar los enlaces de compra cuando esten disponibles. "
        "5) Guiar al usuario en el proceso comercial hasta la confirmacion. "
        "NO inventes productos, precios, stock, URLs ni informacion tecnica: "
        "si el catalogo no lo tiene, decis que no esta disponible o pedis "
        "ajustar la busqueda. "
        "ESTILO DE RESPUESTA: se BREVE y directo, pensado para pantalla de "
        "celular. Respondé en 2 a 4 frases cortas. Usa listas con vinetas si "
        "hay mas de una opcion o dato clave. Sin introducciones tipo 'claro!', "
        "sin despedidas largas ni repeticiones. Lo importante primero: precios, "
        "disponibilidad y enlace si lo hay. Inicia siempre con: 'Que estas "
        "buscando hoy?' Responde siempre en espanol, claro y profesional."
    )


def cargar_catalogo() -> None:
    global _catalogo
    ruta = PROJECT_ROOT / "assets" / "catalogo.json"
    with open(ruta, encoding="utf-8") as f:
        _catalogo = json.load(f)


def _normalizar(texto: str) -> str:
    remplazos = {
        "á": "a", "é": "e", "í": "i", "ó": "o", "ú": "u",
        "ü": "u", "ñ": "n", "Á": "a", "É": "e", "Í": "i",
        "Ó": "o", "Ú": "u", "Ü": "u", "Ñ": "n",
    }
    for a, b in remplazos.items():
        texto = texto.replace(a, b)
    return texto.lower()


def buscar_productos(query: str) -> list:
    q = _normalizar(query)
    return [
        p for p in _catalogo
        if q in _normalizar(p["marca"])
        or q in _normalizar(p["modelo"])
        or q in _normalizar(p["especificacion_clave"])
        or q in _normalizar(p["categoria"])
    ]


def presentar_producto(p: dict) -> str:
    precio = str(round(float(p["precio_usd"])))
    return (
        f"{p['marca']} {p['modelo']} - ${precio} USD\n"
        f"  {p['especificacion_clave']}\n"
        f"  [{p['enlace_compra']}]"
    )


def llamar_groq(messages: list) -> str:
    payload = {
        "model": GROQ_MODELO,
        "messages": messages,
        "temperature": 0.7,
        "max_tokens": MAX_TOKENS,
    }
    resp = requests.post(
        GROQ_URL,
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {GROQ_API_KEY}",
        },
        json=payload,
        timeout=120,
    )
    resp.raise_for_status()
    return resp.json()["choices"][0]["message"]["content"]


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    categorias = sorted({p["categoria"] for p in _catalogo})
    texto = (
        "Hola! Soy VendedorVirtual, tu asistente inteligente de compras.\n\n"
        "Decime que estas buscando, por ejemplo: 'aire acondicionado' o "
        "'telefono'.\n\n"
        f"Categorias disponibles: {', '.join(categorias)}.\n\n"
        "Comandos:\n/nuevo -> empieza una conversacion nueva"
    )
    await update.message.reply_text(texto)


async def nuevo(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    chat_id = update.effective_chat.id
    _historial.pop(chat_id, None)
    await update.message.reply_text("Conversacion nueva. Que estas buscando?")


async def mensaje(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    if not GROQ_API_KEY:
        await update.message.reply_text(
            "Falta configurar GROQ_API_KEY en el archivo .env"
        )
        return

    texto = update.message.text or ""
    chat_id = update.effective_chat.id

    await update.effective_chat.send_action(action=ChatAction.TYPING)

    messages = [{"role": "system", "content": system_prompt()}]

    productos = buscar_productos(texto)
    if productos:
        contexto = "\n".join(presentar_producto(p) for p in productos[:5])
        messages.append(
            {
                "role": "system",
                "content": (
                    "Productos disponibles segun la consulta del usuario:\n"
                    f"{contexto}\n\n"
                    "Usa esta informacion para responder. No inventes productos "
                    "que no esten en esta lista."
                ),
            }
        )

    historial = _historial.setdefault(chat_id, [])
    messages.extend(historial[-10:])
    messages.append({"role": "user", "content": texto})

    try:
        respuesta = llamar_groq(messages)
    except Exception as e:  # noqa: BLE001
        await update.message.reply_text(
            f"Hubo un error consultando la IA. Intenta de nuevo en un momento.\n{e}"
        )
        return

    await update.message.reply_text(respuesta)

    historial.append({"role": "user", "content": texto})
    historial.append({"role": "assistant", "content": respuesta})
    if len(historial) > 12:
        _historial[chat_id] = historial[-12:]


def main() -> None:
    if not TELEGRAM_BOT_TOKEN:
        raise SystemExit(
            "Falta TELEGRAM_BOT_TOKEN en el archivo .env\n"
            "Crea el bot con @BotFather y copia el token en .env"
        )

    cargar_catalogo()
    print(f"VendedorVirtual bot iniciado. Modelo: {GROQ_MODELO}. Esperando mensajes...")

    app = Application.builder().token(TELEGRAM_BOT_TOKEN).build()
    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("nuevo", nuevo))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, mensaje))
    app.run_polling()


if __name__ == "__main__":
    main()
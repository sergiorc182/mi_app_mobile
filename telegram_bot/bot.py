"""VendedorVirtual - Bot de Telegram con IA y Mercado Pago.

Espejo de la lógica de la app Flutter:
- Chat conversacional con Groq AI (Qwen).
- Catálogo local (assets/catalogo.json).
- Checkout Pro de Mercado Pago (generación de links de pago en Sandbox).
- Cierre de compra interactivo (Botones de pago) o "de palabra" (coordinación y pago contra entrega).

Para usarlo:
  1. Configurar las credenciales en .env (GROQ_API_KEY, TELEGRAM_BOT_TOKEN, MERCADOPAGO_ACCESS_TOKEN).
  2. python telegram_bot/bot.py
"""

import json
import logging
import os
import random
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional

# Asegurar codificación UTF-8 en consola de Windows
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

import requests
from dotenv import load_dotenv
from pypdf import PdfReader
from telegram import (
    InlineKeyboardButton,
    InlineKeyboardMarkup,
    Update,
)
from telegram.constants import ChatAction, ParseMode
from telegram.ext import (
    Application,
    CallbackQueryHandler,
    CommandHandler,
    ContextTypes,
    MessageHandler,
    filters,
)

# Cargar variables de entorno
PROJECT_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(PROJECT_ROOT / ".env")

# Importar servicio de Mercado Pago
try:
    from mercadopago_service import (
        crear_preferencia_pago,
        formatear_precio_ars,
        obtener_cotizacion_ars,
    )
except ImportError:
    from telegram_bot.mercadopago_service import (
        crear_preferencia_pago,
        formatear_precio_ars,
        obtener_cotizacion_ars,
    )

logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    level=logging.INFO,
)
logger = logging.getLogger("VendedorVirtual")

GROQ_API_KEY = os.getenv("GROQ_API_KEY", "").strip()
TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN", "").strip()
MERCADOPAGO_ACCESS_TOKEN = os.getenv("MERCADOPAGO_ACCESS_TOKEN", "").strip()
GROQ_MODELO = os.getenv("GROQ_MODELO", "qwen/qwen3.8-27b").strip()
GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"
MAX_TOKENS = int(os.getenv("GROQ_MAX_TOKENS", "500"))

MESES = [
    "enero", "febrero", "marzo", "abril", "mayo", "junio",
    "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre",
]

_catalogo: List[Dict[str, Any]] = []
_info_segmentos: List[str] = []
_historial: Dict[int, List[Dict[str, str]]] = {}
_ultimo_producto: Dict[int, Dict[str, Any]] = {}
_estados: Dict[int, Optional[str]] = {}


def fecha_hoy() -> str:
    now = datetime.now()
    return f"{now.day} de {MESES[now.month - 1]} de {now.year}"


def system_prompt() -> str:
    return (
        "Sos VendedorVirtual, un asistente inteligente de compras de electrodomésticos "
        f"y tecnología. Hoy es {fecha_hoy()}. Tus responsabilidades son: "
        "1) Comprender las necesidades del usuario mediante conversación cordial y ágil. "
        "2) Hacer preguntas específicas para acotar la búsqueda según presupuesto o uso. "
        "3) Recomendar productos basándote estrictamente en el catálogo proporcionado. "
        "4) Si el usuario decide comprar, confirmá su interés y mencionale que puede presionar "
        "el botón de compra en pantalla para abonar con Mercado Pago o coordinar el envío. "
        "5) Guiar al usuario activamente en el proceso comercial hasta la confirmación de la compra. "
        "En cada respuesta, intentá concretar la venta: ofrecer avanzar al siguiente paso "
        "(pasar el enlace de compra, confirmar el producto elegido, resolver dudas de precio o envío). "
        "Si el usuario duda entre opciones, recomendá una concreta y justificá brevemente por qué. "
        "Si el producto que pide no está disponible o no hay stock, decile claramente que no hay stock. "
        "ALCANCE ESTRICTO: tu único tema es la venta de electrodomésticos y tecnología "
        "del catálogo. Si te preguntan algo ajeno a las ventas (clima, deportes, "
        "política, programación, chistes, tareas, temas personales, etc.), no lo "
        "respondas: avisá amablemente que solo podés ayudar con la compra de productos "
        "y redirigí la conversación a qué quiere comprar. No des opiniones ni información "
        "general fuera de las ventas. "
        "NO inventes productos, marcas, precios, stock, URLs ni características fuera del catálogo. "
        "si el catálogo no lo tiene, decís que no está disponible o pedís ajustar la búsqueda. "
        "ESTILO DE RESPUESTA: sé BREVE y directo, pensado para pantalla de celular. "
        "Respondé en 2 a 4 frases cortas. Usá listas con viñetas si hay más de una opción "
        "o dato clave. Sin introducciones tipo '¡claro!', sin despedidas largas ni repeticiones. "
        "Lo importante primero: precios, disponibilidad y enlace si lo hay. "
        "Iniciá siempre con: '¿Qué estás buscando hoy?' Respondé siempre en español, "
        "claro y profesional. Precios en USD y disponibilidad siempre claros."
    )


def _campo_firestore(fields: Dict[str, Any], *nombres: str) -> Any:
    for nombre in nombres:
        if nombre in fields:
            valor = fields[nombre]
            for clave in ("stringValue", "doubleValue", "integerValue", "booleanValue"):
                if clave in valor:
                    return valor[clave]
    return None


def _token_firebase() -> Optional[str]:
    api_key = os.getenv("FIREBASE_API_KEY", "").strip()
    email = os.getenv("FIREBASE_ADMIN_EMAIL", "").strip()
    password = os.getenv("FIREBASE_ADMIN_PASSWORD", "").strip()
    if not (api_key and email and password):
        return None
    try:
        resp = requests.post(
            f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={api_key}",
            json={"email": email, "password": password, "returnSecureToken": True},
            timeout=10,
        )
        if resp.status_code == 200:
            return resp.json().get("idToken")
    except Exception as e:
        logger.warning(f"No se pudo obtener token de Firebase: {e}")
    return None


def cargar_catalogo() -> None:
    global _catalogo
    # 1. Intentar cargar en tiempo real desde Cloud Firestore REST API
    project_id = os.getenv("FIREBASE_PROJECT_ID", "mi-app-mobile-8fd75").strip()
    url = f"https://firestore.googleapis.com/v1/projects/{project_id}/databases/(default)/documents/productos"
    headers = {}
    token = _token_firebase()
    if token:
        headers["Authorization"] = f"Bearer {token}"
    try:
        r = requests.get(url, headers=headers, timeout=5)
        if r.status_code == 200:
            docs = r.json().get("documents", [])
            prods = []
            for d in docs:
                fields = d.get("fields", {})
                precio = _campo_firestore(fields, "precio", "precio_usd", "precioUSD")
                prods.append({
                    "id": _campo_firestore(fields, "id") or d.get("name", "").split("/")[-1],
                    "categoria": _campo_firestore(fields, "categoriaId", "categoria") or "",
                    "marca": _campo_firestore(fields, "marca") or "",
                    "modelo": _campo_firestore(fields, "nombre", "modelo") or "",
                    "especificacion_clave": _campo_firestore(fields, "descripcion", "especificacion_clave", "especificacionClave") or "",
                    "precio_usd": float(precio or 0),
                    "enlace_compra": _campo_firestore(fields, "urlExterna", "enlace_compra", "enlaceCompra") or "",
                })
            if prods:
                _catalogo = [p for p in prods if p.get("marca") or p.get("modelo")]
                logger.info(f"Catálogo en tiempo real sincronizado desde Firestore ({len(_catalogo)} productos)")
                return
        else:
            logger.warning(f"Firestore respondió {r.status_code}. Usando catálogo local.")
    except Exception as e:
        logger.warning(f"No se pudo consultar Firestore en vivo: {e}. Usando catálogo local.")

    # 2. Fallback a catálogo local
    ruta = PROJECT_ROOT / "assets" / "catalogo.json"
    with open(ruta, encoding="utf-8") as f:
        _catalogo = json.load(f)


def cargar_info_pdf() -> None:
    global _info_segmentos
    ruta = PROJECT_ROOT / "assets" / "info.pdf"
    if not ruta.exists():
        logger.warning("No se encontró assets/info.pdf. El bot no usará el documento de referencia.")
        return
    try:
        reader = PdfReader(str(ruta))
        texto = "\n".join((pagina.extract_text() or "") for pagina in reader.pages)
        _info_segmentos = _segmentar_info(texto)
        logger.info(f"Documento de referencia cargado: {len(_info_segmentos)} segmentos.")
    except Exception as e:
        logger.warning(f"No se pudo leer assets/info.pdf: {e}")


def _es_titulo(linea: str) -> bool:
    return not linea.startswith("- ") and not linea.endswith((".", "!", "?", ";", ","))


def _segmentar_info(texto: str) -> List[str]:
    segmentos: List[str] = []
    titulo = ""
    actual = ""

    def cerrar() -> None:
        nonlocal actual
        if actual.strip():
            segmentos.append(actual.strip())
        actual = ""

    for linea_cruda in texto.splitlines():
        linea = linea_cruda.strip()
        if not linea:
            continue
        if linea.startswith("- "):
            cerrar()
            actual = f"{titulo}: {linea}" if titulo else linea
            titulo = ""
        elif _es_titulo(linea):
            cerrar()
            titulo = linea
        elif actual:
            actual = f"{actual} {linea}"
        else:
            segmentos.append(linea)
    cerrar()

    return [s for s in segmentos if len(s) > 10]


def buscar_info(query: str, max_resultados: int = 4) -> List[str]:
    q = re.sub(r"[^a-z0-9\s]", " ", _normalizar(query)).strip()
    if not q or not _info_segmentos:
        return []
    terminos = [t for t in q.split() if len(t) >= 4]

    puntajes = []
    for segmento in _info_segmentos:
        texto = _normalizar(segmento)
        score = 3 if q in texto else 0
        score += sum(1 for t in terminos if t in texto)
        if score > 0:
            puntajes.append((score, segmento))

    puntajes.sort(key=lambda x: x[0], reverse=True)
    return [segmento for _, segmento in puntajes[:max_resultados]]


def _normalizar(texto: str) -> str:
    remplazos = {
        "á": "a", "é": "e", "í": "i", "ó": "o", "ú": "u",
        "ü": "u", "ñ": "n", "Á": "a", "É": "e", "Í": "i",
        "Ó": "o", "Ú": "u", "Ü": "u", "Ñ": "n",
    }
    for a, b in remplazos.items():
        texto = texto.replace(a, b)
    return texto.lower()


def buscar_productos(query: str) -> List[Dict[str, Any]]:
    q = _normalizar(query)
    # Búsqueda por palabras completas y fragmentos
    palabras = [p for p in q.split() if len(p) > 2]
    coincidencias = []

    for prod in _catalogo:
        marca = _normalizar(prod.get("marca", ""))
        modelo = _normalizar(prod.get("modelo", ""))
        espec = _normalizar(prod.get("especificacion_clave", ""))
        cat = _normalizar(prod.get("categoria", ""))
        texto_completo = f"{marca} {modelo} {espec} {cat}"

        if q in texto_completo:
            coincidencias.append(prod)
        elif palabras and any(p in texto_completo for p in palabras):
            coincidencias.append(prod)

    return coincidencias


def presentar_producto(p: Dict[str, Any]) -> str:
    precio_usd = round(float(p["precio_usd"]))
    precio_ars = formatear_precio_ars(float(p["precio_usd"]))
    return (
        f"• {p['marca']} {p['modelo']} - ${precio_usd} USD (~{precio_ars})\n"
        f"  Detalle: {p['especificacion_clave']}"
    )


def llamar_groq(messages: List[Dict[str, str]]) -> str:
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
        timeout=60,
    )
    resp.raise_for_status()
    return resp.json()["choices"][0]["message"]["content"]


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    chat_id = update.effective_chat.id
    _historial.pop(chat_id, None)
    _estados.pop(chat_id, None)

    categorias = sorted({p["categoria"] for p in _catalogo})
    texto = (
        "👋 ¡Hola! Soy *VendedorVirtual*, tu asistente inteligente de compras.\n\n"
        "Te ayudo a encontrar el electrodoméstico o tecnología ideal para vos, "
        "y podés finalizar tu compra directamente por acá.\n\n"
        f"📂 *Categorías disponibles:*\n_{', '.join(categorias)}_\n\n"
        "💬 Contame qué estás buscando (por ejemplo: _'busco un aire acondicionado bajo consumo'_ o _'un smart TV'_)."
    )
    await update.message.reply_text(texto, parse_mode=ParseMode.MARKDOWN)


async def nuevo(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    chat_id = update.effective_chat.id
    _historial.pop(chat_id, None)
    _estados.pop(chat_id, None)
    _ultimo_producto.pop(chat_id, None)
    await update.message.reply_text(
        "🔄 Conversación reiniciada. ¿Qué producto estás buscando hoy?"
    )


async def catalogo_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    categorias = sorted({p["categoria"] for p in _catalogo})
    botones = []
    for cat in categorias:
        botones.append([InlineKeyboardButton(f"📦 {cat}", callback_data=f"cat:{cat}")])

    await update.message.reply_text(
        "Seleccioná una categoría para ver los productos:",
        reply_markup=InlineKeyboardMarkup(botones),
    )


async def generar_mensaje_checkout(
    producto: Dict[str, Any],
    chat_id: int,
) -> tuple[str, InlineKeyboardMarkup]:
    precio_usd = float(producto.get("precio_usd", 0))
    precio_ars = formatear_precio_ars(precio_usd)
    prod_id = producto.get("id", "")
    titulo = f"{producto.get('marca', '')} {producto.get('modelo', '')}"

    # Intentar generar link de Mercado Pago
    link_pago = None
    if MERCADOPAGO_ACCESS_TOKEN:
        try:
            preferencia = crear_preferencia_pago(producto, chat_id=chat_id)
            # Usar sandbox_init_point si estamos en entorno de prueba o init_point
            link_pago = preferencia.get("sandbox_init_point") or preferencia.get("init_point")
        except Exception as e:
            logger.error(f"Error generando preferencia en Mercado Pago: {e}")

    texto = (
        f"🛒 *FINALIZAR COMPRA*\n"
        f"━━━━━━━━━━━━━━━━━━━━━━\n"
        f"📦 *Producto:* {titulo}\n"
        f"📝 *Detalle:* {producto.get('especificacion_clave', '')}\n"
        f"💵 *Precio:* ${precio_usd:,.0f} USD (~{precio_ars})\n"
        f"━━━━━━━━━━━━━━━━━━━━━━\n\n"
        f"Elegí tu método preferido para concretar el pedido:"
    )

    botones = []
    if link_pago:
        botones.append(
            [InlineKeyboardButton("💳 Pagar con Mercado Pago (Sandbox)", url=link_pago)]
        )

    botones.append(
        [InlineKeyboardButton("🤝 Coordinar entrega y pago en efectivo", callback_data=f"coordinar:{prod_id}")]
    )

    return texto, InlineKeyboardMarkup(botones)


async def manejar_callback(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    query = update.callback_query
    await query.answer()
    data = query.data or ""
    chat_id = update.effective_chat.id

    if data.startswith("cat:"):
        categoria = data.split("cat:", 1)[1]
        prods = [p for p in _catalogo if p.get("categoria") == categoria]
        botones = [
            [InlineKeyboardButton(f"Comprar {p['marca']} {p['modelo']} (${p['precio_usd']} USD)", callback_data=f"comprar:{p['id']}")]
            for p in prods[:6]
        ]
        await query.message.reply_text(
            f"Productos en *{categoria}*:",
            parse_mode=ParseMode.MARKDOWN,
            reply_markup=InlineKeyboardMarkup(botones),
        )

    elif data.startswith("comprar:"):
        prod_id = data.split("comprar:", 1)[1]
        prod = next((p for p in _catalogo if p.get("id") == prod_id), None)
        if not prod:
            await query.message.reply_text("Producto no encontrado en el catálogo.")
            return

        _ultimo_producto[chat_id] = prod
        texto, teclado = await generar_mensaje_checkout(prod, chat_id)
        await query.message.reply_text(texto, parse_mode=ParseMode.MARKDOWN, reply_markup=teclado)

    elif data.startswith("coordinar:"):
        prod_id = data.split("coordinar:", 1)[1]
        prod = next((p for p in _catalogo if p.get("id") == prod_id), None)
        if not prod:
            prod = _ultimo_producto.get(chat_id)

        if not prod:
            await query.message.reply_text("Por favor indicame qué producto querés coordinar.")
            return

        _ultimo_producto[chat_id] = prod
        _estados[chat_id] = "esperando_datos_entrega"

        precio_ars = formatear_precio_ars(float(prod['precio_usd']))
        texto = (
            f"📝 *Coordinación de Pedido (Pago contra Entrega)*\n\n"
            f"Producto: *{prod['marca']} {prod['modelo']}*\n"
            f"Monto total: *{precio_ars}* (${prod['precio_usd']} USD)\n\n"
            f"Para reservar y coordinar el despacho, por favor envíame en un solo mensaje tus datos:\n"
            f"1. *Nombre y Apellido*\n"
            f"2. *Teléfono de contacto*\n"
            f"3. *Dirección completa de entrega*"
        )
        await query.message.reply_text(texto, parse_mode=ParseMode.MARKDOWN)


async def mensaje(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    if not GROQ_API_KEY:
        await update.message.reply_text(
            "Falta configurar GROQ_API_KEY en el archivo .env"
        )
        return

    texto_usuario = (update.message.text or "").strip()
    chat_id = update.effective_chat.id

    # 1. ¿El usuario estaba completando datos para cerrar la compra de palabra?
    if _estados.get(chat_id) == "esperando_datos_entrega":
        prod = _ultimo_producto.get(chat_id)
        _estados[chat_id] = None  # Resetear estado

        nro_orden = f"VV-{random.randint(1000, 9999)}"
        precio_ars = formatear_precio_ars(float(prod['precio_usd'])) if prod else "A convenir"
        prod_nombre = f"{prod['marca']} {prod['modelo']}" if prod else "Producto seleccionado"

        mensaje_confirmacion = (
            f"🎉 *¡PEDIDO CONFIRMADO CON ÉXITO!*\n"
            f"━━━━━━━━━━━━━━━━━━━━━━\n"
            f"📋 *Nº de Orden:* `{nro_orden}`\n"
            f"📦 *Producto:* {prod_nombre}\n"
            f"💵 *Monto a abonar al recibir:* {precio_ars}\n\n"
            f"📍 *Datos registrados para la entrega:*\n{texto_usuario}\n"
            f"━━━━━━━━━━━━━━━━━━━━━━\n\n"
            f"✅ Tu pedido ya fue ingresado en nuestro sistema. "
            f"Nos contactaremos a la brevedad para coordinar la franja horaria de entrega. ¡Muchas gracias por tu compra!"
        )
        await update.message.reply_text(mensaje_confirmacion, parse_mode=ParseMode.MARKDOWN)
        return

    # 2. Detección directa de intención de compra
    frase_norm = _normalizar(texto_usuario)
    intencion_compra = any(
        kw in frase_norm for kw in ["quiero comprar", "lo compro", "lo quiero", "como pago", "comprarlo", "hacer el pedido"]
    )

    if intencion_compra and _ultimo_producto.get(chat_id):
        prod = _ultimo_producto[chat_id]
        texto, teclado = await generar_mensaje_checkout(prod, chat_id)
        await update.message.reply_text(texto, parse_mode=ParseMode.MARKDOWN, reply_markup=teclado)
        return

    # 3. Flujo conversacional con Groq e inyección de catálogo
    await update.effective_chat.send_action(action=ChatAction.TYPING)

    messages = [{"role": "system", "content": system_prompt()}]

    productos = buscar_productos(texto_usuario)
    botones_compra = []

    if productos:
        # Guardamos el primer producto relevante como el último discutido
        _ultimo_producto[chat_id] = productos[0]

        contexto = "\n".join(presentar_producto(p) for p in productos[:4])
        messages.append(
            {
                "role": "system",
                "content": (
                    "Productos disponibles según la consulta del usuario:\n"
                    f"{contexto}\n\n"
                    "Usá esta información para responder brevemente y recomendar la mejor opción."
                ),
            }
        )
        # Armar botones de compra rápida para los primeros 2 productos
        for p in productos[:2]:
            botones_compra.append(
                [InlineKeyboardButton(f"💳 Comprar {p['marca']} {p['modelo']} (${p['precio_usd']} USD)", callback_data=f"comprar:{p['id']}")]
            )

    info = buscar_info(texto_usuario)
    if info:
        messages.append(
            {
                "role": "system",
                "content": (
                    "Información del asistente (extraída del documento de referencia):\n"
                    + "\n".join(info)
                    + "\n\nUsá esta información si responde a la consulta del usuario. "
                    "No inventes datos que no estén ahí."
                ),
            }
        )

    historial = _historial.setdefault(chat_id, [])
    messages.extend(historial[-8:])
    messages.append({"role": "user", "content": texto_usuario})

    try:
        respuesta = llamar_groq(messages)
    except Exception as e:
        logger.error(f"Error consultando a Groq: {e}")
        await update.message.reply_text(
            f"Hubo un inconveniente consultando el catálogo con la IA. Por favor, intentá nuevamente en unos segundos.\n({e})"
        )
        return

    reply_markup = InlineKeyboardMarkup(botones_compra) if botones_compra else None
    await update.message.reply_text(respuesta, reply_markup=reply_markup)

    historial.append({"role": "user", "content": texto_usuario})
    historial.append({"role": "assistant", "content": respuesta})
    if len(historial) > 10:
        _historial[chat_id] = historial[-10:]


def main() -> None:
    if not TELEGRAM_BOT_TOKEN:
        print("\n" + "=" * 65)
        print("❌ Falta TELEGRAM_BOT_TOKEN en el archivo .env")
        print("   Para obtenerlo:")
        print("   1. Abrí Telegram y buscá @BotFather")
        print("   2. Escribí /newbot y seguí los pasos")
        print("   3. Copiá el token en .env como TELEGRAM_BOT_TOKEN=...")
        print("=" * 65 + "\n")
        raise SystemExit(1)

    cargar_catalogo()
    cargar_info_pdf()
    print("\n" + "=" * 65)
    print("🚀 VendedorVirtual Bot Iniciado con Éxito")
    print(f"• Modelo IA: {GROQ_MODELO}")
    print(f"• Catálogo: {len(_catalogo)} productos cargados")
    print(f"• Documento de referencia: {len(_info_segmentos)} segmentos")
    print(f"• Mercado Pago: {'Configurado ✅' if MERCADOPAGO_ACCESS_TOKEN else 'No configurado ⚠️'}")
    print("• Esperando mensajes de clientes en Telegram...")
    print("=" * 65 + "\n")

    app = Application.builder().token(TELEGRAM_BOT_TOKEN).build()
    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("nuevo", nuevo))
    app.add_handler(CommandHandler("catalogo", catalogo_cmd))
    app.add_handler(CallbackQueryHandler(manejar_callback))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, mensaje))
    app.run_polling()


if __name__ == "__main__":
    main()

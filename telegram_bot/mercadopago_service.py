"""Servicio de integración con Mercado Pago Checkout Pro.

Crea preferencias de pago (checkout) en Mercado Pago para los productos del catálogo.
Genera enlaces directos de pago para enviar como botones interactivos en Telegram.
"""

import os
from typing import Any, Dict, Optional
import requests

MP_API_URL = "https://api.mercadopago.com/checkout/preferences"


def obtener_cotizacion_ars() -> float:
    try:
        return float(os.getenv("USD_A_ARS_COTIZACION", "1250"))
    except ValueError:
        return 1250.0


def formatear_precio_ars(precio_usd: float) -> str:
    cotizacion = obtener_cotizacion_ars()
    precio_ars = round(precio_usd * cotizacion)
    # Formateo estilo argentino con punto separador de miles
    return f"${precio_ars:,.0f}".replace(",", ".") + " ARS"


def crear_preferencia_pago(
    producto: Dict[str, Any],
    chat_id: Optional[int] = None,
) -> Dict[str, Any]:
    """Crea una preferencia de pago en Mercado Pago y retorna los links de cobro.

    Retorna un diccionario con:
    - init_point: Link oficial de pago
    - sandbox_init_point: Link de sandbox (prueba)
    - id: ID de la preferencia
    - precio_ars: Precio calculado en pesos argentinos
    """
    token = os.getenv("MERCADOPAGO_ACCESS_TOKEN", "").strip()
    if not token:
        raise ValueError("Falta MERCADOPAGO_ACCESS_TOKEN en el archivo .env")

    precio_usd = float(producto.get("precio_usd", 0))
    cotizacion = obtener_cotizacion_ars()
    precio_ars = round(precio_usd * cotizacion, 2)
    titulo = f"{producto.get('marca', '')} {producto.get('modelo', '')}".strip()
    descripcion = producto.get("especificacion_clave", titulo)

    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }

    payload = {
        "items": [
            {
                "id": str(producto.get("id", "PROD-01")),
                "title": titulo,
                "description": descripcion[:250],
                "quantity": 1,
                "unit_price": precio_ars,
                "currency_id": "ARS",
            }
        ],
        "statement_descriptor": "VendedorVirtual",
        "external_reference": f"CHAT_{chat_id}_{producto.get('id', '')}" if chat_id else f"PROD_{producto.get('id', '')}",
        "back_urls": {
            "success": "https://t.me/VendedorVirtualBot",
            "pending": "https://t.me/VendedorVirtualBot",
            "failure": "https://t.me/VendedorVirtualBot",
        },
        "auto_return": "approved",
    }

    resp = requests.post(MP_API_URL, headers=headers, json=payload, timeout=20)

    if resp.status_code not in (200, 201):
        raise RuntimeError(
            f"Error Mercado Pago ({resp.status_code}): {resp.text}"
        )

    data = resp.json()
    return {
        "id": data.get("id"),
        "init_point": data.get("init_point"),
        "sandbox_init_point": data.get("sandbox_init_point") or data.get("init_point"),
        "precio_ars": precio_ars,
        "titulo": titulo,
    }

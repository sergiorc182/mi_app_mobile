"""Script para sembrar el catálogo de assets/catalogo.json en Cloud Firestore.

Usa el esquema vigente de la app: productos/{id} con
nombre, descripcion, marca, categoriaId, precio, moneda, stock, activo,
sku, imagenUrl y urlExterna.

Las credenciales se leen del .env (no van hardcodeadas):
    FIREBASE_API_KEY, FIREBASE_PROJECT_ID, FIREBASE_ADMIN_EMAIL,
    FIREBASE_ADMIN_PASSWORD

Nota: firestore.rules no permite escribir en 'productos' desde el cliente.
Para sembrar el catálogo de verdad usá el Admin SDK:
    python tools/migrar_firestore.py --key serviceAccountKey.json
"""

import json
import os
from pathlib import Path

import requests
from dotenv import load_dotenv

PROJECT_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(PROJECT_ROOT / ".env")

API_KEY = os.getenv("FIREBASE_API_KEY", "").strip()
PROJECT_ID = os.getenv("FIREBASE_PROJECT_ID", "mi-app-mobile-8fd75").strip()
ADMIN_EMAIL = os.getenv("FIREBASE_ADMIN_EMAIL", "").strip()
ADMIN_PASSWORD = os.getenv("FIREBASE_ADMIN_PASSWORD", "").strip()


def obtener_id_token() -> str:
    if not (API_KEY and ADMIN_EMAIL and ADMIN_PASSWORD):
        raise SystemExit(
            "Faltan FIREBASE_API_KEY, FIREBASE_ADMIN_EMAIL o "
            "FIREBASE_ADMIN_PASSWORD en el archivo .env"
        )

    login_url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={API_KEY}"
    payload = {
        "email": ADMIN_EMAIL,
        "password": ADMIN_PASSWORD,
        "returnSecureToken": True,
    }
    resp = requests.post(login_url, json=payload, timeout=10)
    if resp.status_code == 200:
        return resp.json()["idToken"]

    signup_url = f"https://identitytoolkit.googleapis.com/v1/accounts:signUp?key={API_KEY}"
    resp = requests.post(signup_url, json=payload, timeout=10)
    resp.raise_for_status()
    return resp.json()["idToken"]


def _categoria_id(categoria: str) -> str:
    return categoria.strip().lower().replace(" ", "_") if categoria else "general"


def subir_productos():
    token = obtener_id_token()
    ruta_catalogo = PROJECT_ROOT / "assets" / "catalogo.json"

    with open(ruta_catalogo, encoding="utf-8") as f:
        productos = json.load(f)

    subidos = 0
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }

    for prod in productos:
        doc_id = prod.get("id")
        if not doc_id:
            continue

        url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/productos/{doc_id}"

        cuerpo = {
            "fields": {
                "nombre": {"stringValue": str(prod.get("modelo", ""))},
                "descripcion": {
                    "stringValue": str(prod.get("especificacion_clave", ""))
                },
                "marca": {"stringValue": str(prod.get("marca", ""))},
                "categoriaId": {
                    "stringValue": _categoria_id(str(prod.get("categoria", "")))
                },
                "precio": {"doubleValue": float(prod.get("precio_usd", 0) or 0)},
                "moneda": {"stringValue": str(prod.get("moneda", "USD"))},
                "stock": {"integerValue": int(prod.get("stock", 1) or 1)},
                "activo": {"booleanValue": bool(prod.get("activo", True))},
                "sku": {"stringValue": str(prod.get("sku", doc_id))},
                "imagenUrl": {"stringValue": str(prod.get("imagenUrl", ""))},
                "urlExterna": {
                    "stringValue": str(prod.get("enlace_compra", ""))
                },
            }
        }

        r = requests.patch(url, headers=headers, json=cuerpo, timeout=10)
        if r.status_code in (200, 201):
            subidos += 1
            print(
                f"[{subidos}/{len(productos)}] Subido: "
                f"{prod.get('marca')} {prod.get('modelo')}"
            )
        else:
            print(f"Error subiendo {doc_id} ({r.status_code}): {r.text}")

    print(f"\nTotal subidos a Cloud Firestore: {subidos}/{len(productos)}")


if __name__ == "__main__":
    subir_productos()

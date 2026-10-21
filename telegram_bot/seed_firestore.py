"""Script para sembrar el catálogo de assets/catalogo.json en Cloud Firestore."""

import json
from pathlib import Path
import requests

PROJECT_ROOT = Path(__file__).resolve().parent.parent
API_KEY = "AIzaSyD7swUB6yivd9NijkFZhojSd8VQoz5uWjc"
PROJECT_ID = "mi-app-mobile-8fd75"


def obtener_id_token() -> str:
    login_url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={API_KEY}"
    payload = {
        "email": "admin_catalog@vendedorvirtual.com",
        "password": "AdminPassword123!",
        "returnSecureToken": True,
    }
    resp = requests.post(login_url, json=payload, timeout=10)
    if resp.status_code == 200:
        return resp.json()["idToken"]

    # Si no existe, crear
    signup_url = f"https://identitytoolkit.googleapis.com/v1/accounts:signUp?key={API_KEY}"
    resp = requests.post(signup_url, json=payload, timeout=10)
    resp.raise_for_status()
    return resp.json()["idToken"]


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

        body = {
            "fields": {
                "id": {"stringValue": str(prod.get("id", ""))},
                "categoria": {"stringValue": str(prod.get("categoria", ""))},
                "marca": {"stringValue": str(prod.get("marca", ""))},
                "modelo": {"stringValue": str(prod.get("modelo", ""))},
                "especificacion_clave": {
                    "stringValue": str(prod.get("especificacion_clave", ""))
                },
                "precio_usd": {"doubleValue": float(prod.get("precio_usd", 0))},
                "enlace_compra": {"stringValue": str(prod.get("enlace_compra", ""))},
            }
        }

        r = requests.patch(url, headers=headers, json=body, timeout=10)
        if r.status_code in (200, 201):
            subidos += 1
            print(f"[{subidos}/{len(productos)}] Subido: {prod.get('marca')} {prod.get('modelo')}")
        else:
            print(f"Error subiendo {doc_id} ({r.status_code}): {r.text}")

    print(f"\nTotal subidos a Cloud Firestore: {subidos}/{len(productos)}")


if __name__ == "__main__":
    subir_productos()

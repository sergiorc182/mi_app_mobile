"""Migra los datos del esquema viejo de Firestore al esquema definitivo.

Requiere una service account key del proyecto Firebase (Admin SDK).
NO subir la key al repo.

Uso:
    pip install -r tools/requirements_migracion.txt
    python tools/migrar_firestore.py --key serviceAccountKey.json

Que hace:
    - users  -> usuarios        (agrega updatedAt y activo si faltan)
    - users/{uid}/conversaciones -> conversaciones (raiz, con usuarioId/estado/updatedAt)
    - mensajes: fecha -> createdAt, agrega tipo='texto'
    - assets/catalogo.json -> productos (+ categorias derivadas)

Es idempotente: se puede volver a correr sin duplicar datos (usa set/merge).
No borra las colecciones viejas: eso lo decidis vos despues de verificar.
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore

PROJECT_ROOT = Path(__file__).resolve().parent.parent
CATALOGO = PROJECT_ROOT / "assets" / "catalogo.json"


def _ts(valor):
    """Convierte un valor de Firestore a Timestamp, con fallback a ahora."""
    return valor if valor is not None else firestore.SERVER_TIMESTAMP


def migrar_usuarios(db) -> int:
    print("\n[1/5] Migrando usuarios (users -> usuarios)...")
    total = 0
    for doc in db.collection("users").stream():
        data = doc.to_dict() or {}
        data["activo"] = data.get("activo", True)
        if data.get("createdAt") is None:
            data["createdAt"] = firestore.SERVER_TIMESTAMP
        if data.get("updatedAt") is None:
            data["updatedAt"] = data.get("createdAt", firestore.SERVER_TIMESTAMP)

        db.collection("usuarios").document(doc.id).set(data, merge=True)
        total += 1
        print(f"   - usuario {doc.id} migrado")
    print(f"   {total} usuarios migrados.")
    return total


def _migrar_mensajes(db, conversacion_id: str, origen_ref=None) -> int:
    """Migra los mensajes: lee de una coleccion origen y escribe en
    conversaciones/{id}/mensajes (fecha -> createdAt, agrega tipo)."""
    total = 0
    destino = (
        db.collection("conversaciones").document(conversacion_id).collection("mensajes")
    )
    if origen_ref is None:
        origen_ref = destino
    for msg in origen_ref.stream():
        data = msg.to_dict() or {}
        data.setdefault("tipo", "texto")
        if "createdAt" not in data:
            data["createdAt"] = data.get("fecha", firestore.SERVER_TIMESTAMP)
        data.pop("fecha", None)
        data.pop("conversacionId", None)

        destino.document(msg.id).set(data, merge=True)
        total += 1
    return total


def migrar_conversaciones_subcoleccion(db) -> int:
    """Mueve users/{uid}/conversaciones -> conversaciones (raiz)."""
    print("\n[2/5] Migrando conversaciones anidadas bajo users/{uid}...")
    total = 0
    for user in db.collection("users").stream():
        uid = user.id
        sub = db.collection("users").document(uid).collection("conversaciones")
        for conv in sub.stream():
            data = conv.to_dict() or {}
            data["usuarioId"] = data.get("usuarioId", uid)
            data.setdefault("estado", "activa")
            if data.get("createdAt") is None:
                data["createdAt"] = firestore.SERVER_TIMESTAMP
            if data.get("updatedAt") is None:
                data["updatedAt"] = data.get("createdAt", firestore.SERVER_TIMESTAMP)

            # Copia la conversacion y sus mensajes a la coleccion raiz.
            destino = db.collection("conversaciones").document(conv.id)
            destino.set(data, merge=True)
            mensajes = _migrar_mensajes(
                db,
                conv.id,
                sub.document(conv.id).collection("mensajes"),
            )
            total += 1
            print(f"   - conversacion {conv.id} (usuario {uid}, {mensajes} mensajes)")
    print(f"   {total} conversaciones migradas.")
    return total


def migrar_conversaciones_raiz(db) -> int:
    """Normaliza conversaciones que ya estan en la coleccion raiz."""
    print("\n[2b/5] Normalizando conversaciones en la coleccion raiz...")
    total = 0
    for conv in db.collection("conversaciones").stream():
        data = conv.to_dict() or {}
        if data.get("createdAt") is None:
            data["createdAt"] = firestore.SERVER_TIMESTAMP
        if data.get("updatedAt") is None:
            data["updatedAt"] = data.get("createdAt", firestore.SERVER_TIMESTAMP)
        data.setdefault("estado", "activa")
        db.collection("conversaciones").document(conv.id).set(data, merge=True)
        _migrar_mensajes(db, conv.id)
        total += 1
    print(f"   {total} conversaciones normalizadas.")
    return total


def migrar_catalogo(db) -> int:
    print("\n[3/5] Migrando catalogo (assets/catalogo.json -> productos)...")
    if not CATALOGO.exists():
        print(f"   AVISO: no se encontro {CATALOGO}. Se omite.")
        return 0

    data = json.loads(CATALOGO.read_text(encoding="utf-8"))
    categorias_vistas: dict[str, str] = {}
    total = 0
    ahora = firestore.SERVER_TIMESTAMP

    for item in data:
        prod_id = str(item.get("id", "")).strip()
        if not prod_id:
            continue

        categoria = item.get("categoria", item.get("categoriaId", "")).strip()
        categoria_id = categoria.lower().replace(" ", "_") if categoria else "general"
        if categoria and categoria_id not in categorias_vistas:
            categorias_vistas[categoria_id] = categoria

        nombre = item.get("nombre") or item.get("modelo") or ""
        descripcion = item.get("descripcion") or item.get("especificacion_clave") or ""
        url = item.get("urlExterna") or item.get("enlace_compra") or ""
        precio = item.get("precio", item.get("precio_usd", 0))

        documento = {
            "nombre": nombre,
            "descripcion": descripcion,
            "marca": item.get("marca", ""),
            "categoriaId": categoria_id,
            "precio": float(precio or 0),
            "moneda": item.get("moneda", "USD"),
            "stock": int(item.get("stock", 1)),
            "activo": bool(item.get("activo", True)),
            "sku": item.get("sku", prod_id),
            "imagenUrl": item.get("imagenUrl", ""),
            "urlExterna": url,
            "createdAt": ahora,
            "updatedAt": ahora,
        }
        db.collection("productos").document(prod_id).set(documento, merge=True)
        total += 1

    for cat_id, cat_nombre in categorias_vistas.items():
        db.collection("categorias").document(cat_id).set(
            {"nombre": cat_nombre, "descripcion": "", "activo": True},
            merge=True,
        )

    print(f"   {total} productos y {len(categorias_vistas)} categorias migradas.")
    return total


def sembrar_configuracion(db) -> int:
    """Crea configuracion/asistente si no existe (no pisa lo customised)."""
    print("\n[4/5] Sembrando configuracion/asistente...")
    ref = db.collection("configuracion").document("asistente")
    if ref.get().exists:
        print("   ya existe, se conserva sin cambios.")
        return 0
    ref.set(
        {
            "nombreNegocio": "VendedorVirtual",
            "moneda": "USD",
            "mensajeBienvenida": (
                "¡Hola! Soy tu vendedor virtual. Decime qué producto "
                "buscás y te paso el precio y el link de compra."
            ),
            "instruccionesAsistente": (
                "Respondé solo sobre el catálogo de productos y el alcance "
                "del negocio. No inventes precios, stock ni condiciones de venta."
            ),
            "urlWeb": "",
            "urlTelegram": "",
            "catalogoHabilitado": True,
            "comprasHabilitadas": True,
            "updatedAt": firestore.SERVER_TIMESTAMP,
        }
    )
    print("   configuracion/asistente creada.")
    return 1


def main() -> None:
    parser = argparse.ArgumentParser(description="Migra Firestore al esquema nuevo.")
    parser.add_argument(
        "--key",
        required=True,
        help="Ruta al archivo JSON de la service account.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Solo cuenta documentos, sin escribir nada.",
    )
    args = parser.parse_args()

    ruta_key = Path(args.key)
    if not ruta_key.exists():
        raise SystemExit(f"No existe la service account key: {ruta_key}")

    cred = credentials.Certificate(str(ruta_key))
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    if args.dry_run:
        print("DRY RUN: no se escribira nada.")
        print("   users:", len(list(db.collection("users").stream())))
        print("   conversaciones (raiz):", len(list(db.collection("conversaciones").stream())))
        print("   productos:", len(list(db.collection("productos").stream())))
        return

    print("Iniciando migracion...")
    migrar_usuarios(db)
    migrar_conversaciones_subcoleccion(db)
    migrar_conversaciones_raiz(db)
    migrar_catalogo(db)
    sembrar_configuracion(db)

    print(
        "\nMigracion terminada. Verifica en la consola de Firebase antes de "
        "borrar las colecciones viejas (users)."
    )


if __name__ == "__main__":
    main()

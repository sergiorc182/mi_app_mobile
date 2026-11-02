import os
from pathlib import Path

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from mercadopago_service import crear_preferencia_pago

# Cargar .env desde la raíz del proyecto
PROJECT_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(PROJECT_ROOT / ".env")

app = FastAPI(title="VendedorVirtual - MercadoPago API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class ProductoMP(BaseModel):
    id: str
    marca: str
    modelo: str
    especificacion_clave: str = ""
    precio_usd: float


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/crear-preferencia")
def crear_preferencia(data: ProductoMP):
    try:
        producto = data.model_dump()
        resp = crear_preferencia_pago(producto)
        return {
            "id": resp.get("id"),
            "init_point": resp.get("init_point"),
            "sandbox_init_point": resp.get("sandbox_init_point"),
            "precio_ars": resp.get("precio_ars"),
            "titulo": resp.get("titulo"),
        }
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

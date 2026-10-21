"""Verifica la logica de migracion con un Firestore simulado (sin network).

Uso: python tools/test_migracion.py
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import migrar_firestore as m


class FakeSentinel:
    def __repr__(self):
        return "<SERVER_TS>"


class FakeDoc:
    def __init__(self, store, path, doc_id):
        self._store = store
        self._path = path
        self.id = doc_id

    def to_dict(self):
        return dict(self._store.get(self._path, {}))

    def set(self, data, merge=False):
        actual = self._store.setdefault(self._path, {})
        if merge:
            actual.update(data)
        else:
            self._store[self._path] = dict(data)

    def collection(self, nombre):
        return FakeCollection(self._store, f"{self._path}/{nombre}")


class FakeCollection:
    def __init__(self, store, path):
        self._store = store
        self._path = path

    def stream(self):
        prefijo = self._path + "/"
        ids = set()
        for key in self._store:
            if key.startswith(prefijo):
                resto = key[len(prefijo):]
                if "/" not in resto and resto:
                    ids.add(resto)
        return [FakeDoc(self._store, f"{self._path}/{i}", i) for i in sorted(ids)]

    def document(self, doc_id):
        return FakeDoc(self._store, f"{self._path}/{doc_id}", doc_id)


class FakeDB:
    def __init__(self, store):
        self._store = store

    def collection(self, nombre):
        return FakeCollection(self._store, nombre)


def correr():
    store = {
        # usuario viejo (sin activo/updatedAt)
        "users/u1": {
            "nombre": "Ana", "apellido": "Perez", "dni": "123",
            "email": "ana@x.com", "fotoPerfil": "", "createdAt": "T0",
        },
        # conversacion anidada con mensaje viejo (fecha)
        "users/u1/conversaciones/c1": {"titulo": "Aire", "createdAt": "T0"},
        "users/u1/conversaciones/c1/mensajes/m1": {
            "autor": "user", "mensaje": "hola", "fecha": "T0",
        },
    }
    db = FakeDB(store)
    m.firestore.SERVER_TIMESTAMP = FakeSentinel()

    m.migrar_usuarios(db)
    m.migrar_conversaciones_subcoleccion(db)
    m.migrar_catalogo(db)

    ok = True

    def check(cond, msg):
        nonlocal ok
        print(("  OK  " if cond else " FALLA ") + msg)
        ok = ok and cond

    print("\n== usuarios ==")
    u = store.get("usuarios/u1", {})
    check(u.get("nombre") == "Ana", "nombre preservado")
    check(u.get("activo") is True, "activo agregado")
    check("updatedAt" in u, "updatedAt agregado")
    check(u.get("createdAt") == "T0", "createdAt preservado")

    print("\n== conversaciones ==")
    c = store.get("conversaciones/c1", {})
    check(c.get("usuarioId") == "u1", "usuarioId agregado")
    check(c.get("titulo") == "Aire", "titulo preservado")
    check(c.get("estado") == "activa", "estado agregado")
    check("updatedAt" in c, "updatedAt agregado")

    print("\n== mensajes ==")
    msg = store.get("conversaciones/c1/mensajes/m1", {})
    check(msg.get("createdAt") == "T0", "fecha -> createdAt")
    check("fecha" not in msg, "fecha eliminada")
    check(msg.get("tipo") == "texto", "tipo agregado")

    print("\n== productos ==")
    productos = [k for k in store if k.startswith("productos/")]
    check(len(productos) > 0, f"se migraron productos ({len(productos)})")
    if productos:
        p = store[productos[0]]
        for campo in ("nombre", "descripcion", "marca", "categoriaId",
                      "precio", "moneda", "stock", "activo", "sku",
                      "imagenUrl", "urlExterna"):
            check(campo in p, f"campo '{campo}' presente")
    categorias = [k for k in store if k.startswith("categorias/")]
    check(len(categorias) > 0, f"se crearon categorias ({len(categorias)})")

    print("\nRESULTADO:", "TODO OK" if ok else "HAY FALLAS")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(correr())

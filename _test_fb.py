import os, requests, urllib.parse
from dotenv import load_dotenv
from pathlib import Path

ROOT = Path(r"C:\Users\Mateo\Desktop\proyecto seminario\mi_app_mobile")
load_dotenv(ROOT / ".env")

api = os.getenv("FIREBASE_API_KEY", "").strip()
em = os.getenv("FIREBASE_ADMIN_EMAIL", "").strip()
pw = os.getenv("FIREBASE_ADMIN_PASSWORD", "").strip()
pid = os.getenv("FIREBASE_PROJECT_ID", "mi-app-mobile-8fd75").strip()
bucket = os.getenv("FIREBASE_STORAGE_BUCKET") or f"{pid}.appspot.com"

print("Bucket:", bucket)
print("Email:", em)

r = requests.post(
    f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={api}",
    json={"email": em, "password": pw, "returnSecureToken": True},
    timeout=15,
)
print("Auth:", r.status_code)
if r.status_code != 200:
    print(r.text)
    raise SystemExit(1)

tok = r.json().get("idToken")
path = "conocimiento_ia/vendedorVirtual.pdf"
enc = urllib.parse.quote(path, safe="")
url = f"https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{enc}?alt=media"
rr = requests.get(url, headers={"Authorization": f"Bearer {tok}"}, timeout=30)
print("Download:", rr.status_code)
print("Bytes:", len(rr.content))
(ROOT / "assets").mkdir(exist_ok=True)
(ROOT / "assets" / "info.pdf").write_bytes(rr.content)
print("Guardado en assets/info.pdf")

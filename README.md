# VendedorVirtual

VendedorVirtual es un asistente conversacional de compras de electrodomesticos y tecnologia. El proyecto incluye una app movil Flutter para Android y un bot de Telegram. Ambos usan Groq para responder en espanol y pueden consultar un catalogo local o productos publicados en Cloud Firestore.

## Funcionalidades

- Registro e inicio de sesion con Firebase Authentication, recuperacion de contrasena y edicion del perfil.
- Chat con historial de conversaciones y mensajes guardados en Firestore.
- Recomendaciones basadas en el catalogo, con una copia local para uso de respaldo.
- Contexto adicional del negocio a partir de `assets/info.pdf`.
- Bot de Telegram con catalogo, flujo de compra, opciones de pago y coordinacion de entrega.
- Integracion del bot con Mercado Pago Checkout Pro. Sin credenciales de Mercado Pago, el bot puede ofrecer coordinacion y pago en efectivo.
- Reglas de Firestore e indices incluidos en el repositorio.

## Tecnologias

- Flutter y Dart (SDK de Dart `>=3.11.0 <4.0.0`).
- Firebase Authentication y Cloud Firestore.
- Groq API; el modelo predeterminado es `qwen/qwen3.8-27b` y se puede configurar.
- Python para el bot de Telegram y las herramientas de datos.
- Mercado Pago Checkout Pro para el flujo de pago del bot.

## Estado del proyecto

La app Flutter tiene Firebase configurado para Android. Aunque hay carpetas de otras plataformas en el repositorio, `lib/firebase_options.dart` marca iOS como no configurado y Web, Windows, macOS y Linux como no soportados. El checkout de Mercado Pago descrito aqui pertenece al bot de Telegram; la app movil no implementa un checkout propio.

El proyecto depende de servicios y credenciales externos (Firebase, Groq y, para pagos, Mercado Pago). El funcionamiento completo requiere configurar esos servicios y sus reglas antes de distribuir la aplicacion.

## Requisitos

- Flutter instalado y un dispositivo o emulador Android disponible.
- Un proyecto de Firebase con Authentication por correo y contrasena y Cloud Firestore habilitados.
- Una clave de Groq para las respuestas del asistente.
- Python 3.9 o superior para ejecutar el bot.
- Un bot creado con [@BotFather](https://t.me/BotFather) para usar Telegram.
- Credenciales de Mercado Pago si se habilita Checkout Pro.

## Configuracion local

1. Clona el repositorio y entra en su carpeta.
2. Crea el archivo de entorno a partir de la plantilla:

	```powershell
	Copy-Item .env.example .env
	```

3. Completa en `.env` las variables necesarias para el componente que vas a ejecutar. La app carga este archivo al arrancar y requiere `GROQ_API_KEY`; el bot requiere `GROQ_API_KEY` y `TELEGRAM_BOT_TOKEN`. Para el checkout del bot, configura tambien `MERCADOPAGO_ACCESS_TOKEN`.
4. Configura Firebase para Android y verifica que `android/app/google-services.json` corresponda al proyecto utilizado por `lib/firebase_options.dart`. Habilita Email/Password en Firebase Authentication y despliega las reglas e indices de Firestore incluidos en el repositorio.

La plantilla `.env.example` contiene todas las variables disponibles:

| Variable | Uso |
| --- | --- |
| `GROQ_API_KEY` | Clave de Groq, necesaria para generar respuestas. |
| `GROQ_MODELO` | Modelo de Groq; valor predeterminado: `qwen/qwen3.8-27b`. |
| `GROQ_MAX_TOKENS` | Limite configurado por el bot. |
| `TELEGRAM_BOT_TOKEN` | Token del bot, necesario para Telegram. |
| `MERCADOPAGO_ACCESS_TOKEN` | Habilita la creacion de preferencias de pago. |
| `USD_A_ARS_COTIZACION` | Cotizacion usada por el bot; valor predeterminado: `1250`. |
| `FIREBASE_API_KEY`, `FIREBASE_PROJECT_ID`, `FIREBASE_ADMIN_EMAIL`, `FIREBASE_ADMIN_PASSWORD` | Permiten al bot consultar el catalogo en Firestore; si no puede, usa `assets/catalogo.json`. |

No publiques `.env`, tokens ni archivos de cuentas de servicio. La app carga `.env` como asset y llama a Groq directamente desde el dispositivo; por eso, no es seguro incluir una clave privada de Groq en una version publica distribuida. Para produccion, mueve esa llamada a un backend propio y entrega las credenciales por un mecanismo seguro.

## Ejecutar la app Android

Desde la raiz del proyecto:

```powershell
flutter pub get
flutter run
```

Se necesita un emulador o dispositivo Android conectado. La app inicia en la pantalla de acceso; se puede crear una cuenta desde la propia aplicacion.

## Ejecutar el bot de Telegram

Desde la raiz del proyecto, crea un entorno virtual e instala sus dependencias:

```powershell
py -m venv .venv
.\.venv\Scripts\Activate.ps1
py -m pip install -r telegram_bot/requirements.txt
py telegram_bot/bot.py
```

En macOS o Linux, activa el entorno con `source .venv/bin/activate` y ejecuta `python -m pip` y `python telegram_bot/bot.py`.

En Telegram, abre el bot y envia `/start`. El detalle del flujo de compra y las opciones de pago esta en [INSTRUCCIONES_TELEGRAM.txt](INSTRUCCIONES_TELEGRAM.txt).

## Catalogo y datos de Firebase

La app y el bot pueden usar `assets/catalogo.json` como catalogo local. En Firestore, el catalogo se guarda en `productos` y las categorias en `categorias`. El asistente tambien puede usar `assets/info.pdf` como contexto.

Las reglas actuales permiten a usuarios autenticados leer el catalogo, pero no escribir productos, categorias ni configuracion desde el cliente. Para cargar o migrar datos, usa una credencial de Firebase Admin que no este dentro del repositorio:

```powershell
py -m pip install -r tools/requirements_migracion.txt
py tools/migrar_firestore.py --key ruta\a\serviceAccountKey.json --dry-run
py tools/migrar_firestore.py --key ruta\a\serviceAccountKey.json
```

El modo `--dry-run` muestra conteos sin escribir cambios. Revisa los datos en Firebase antes de retirar colecciones antiguas. La siembra directa desde el cliente no esta permitida por las reglas actuales.

Para regenerar el documento de referencia, instala las dependencias indicadas en `tools/requirements_migracion.txt` y ejecuta:

```powershell
py tools/generar_pdf_info.py
```

## Pruebas y analisis

```powershell
flutter test
flutter analyze
```

Las pruebas existentes cubren el inicio de la app, validaciones de registro, utilidades de texto, busqueda del catalogo y lectura del PDF de informacion.

## Estructura

```text
lib/                 App Flutter: vistas, controladores, modelos y Firebase
telegram_bot/        Bot de Telegram e integracion con Mercado Pago
assets/              Catalogo local, documento de referencia e icono
tools/               Migracion de Firestore y generacion del PDF
test/                Pruebas de Flutter
firestore.rules      Reglas de seguridad de Cloud Firestore
firestore.indexes.json Indices de Cloud Firestore
```

## Seguridad

- Mantiene `.env` y las credenciales de servicio fuera de Git.
- Revisa las reglas de Firestore antes de desplegar y concede solo los permisos necesarios.
- No uses credenciales de prueba ni claves privadas dentro de una app distribuida.
- Las operaciones administrativas sobre Firestore deben ejecutarse desde un entorno confiable.

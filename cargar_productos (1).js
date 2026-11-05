/**
 * 
 quiero que adaptes este cargar productos a la base de datos de firestore

 * Carga de catálogo (electrodomésticos y artículos audiovisuales) a Firestore.
 * Pensado para una app en Dart/Flutter: los campos tienen tipos fijos
 * (precio y stock numéricos, tags como lista, specs como mapa).
 *
 * IMPORTANTE: los productos, marcas, precios, stock y especificaciones de este
 * archivo son DATOS DE EJEMPLO para armar y probar el asistente. Reemplazalos
 * por los datos reales de tu catálogo antes de usarlo con clientes.
 *
 * Uso:
 *   npm install firebase-admin
 *   node cargar_productos.js --dry     (solo valida y muestra un resumen)
 *   node cargar_productos.js           (carga en Firestore)
 *
 * Requiere el archivo serviceAccountKey.json en la misma carpeta.
 * No subas ese archivo a GitHub.
 */


const admin = require("firebase-admin");

// Mantiene compatibles las llamadas del catálogo original.
const p = (
  sku,
  nombre,
  marca,
  categoria,
  precio,
  stock,
  descripcion,
  specs = {},
  tags = []
) => ({
  sku,
  nombre,
  marca,
  categoriaId: categoria,
  precio,
  stock,
  descripcion,
  specs,
  tags,
});

// Conservá aquí tu array original completo:
// const productos = [
//   p("CEL001", ...),
//   ...
// ];


const productos = [
  // ---------------- CELULARES ----------------
  p("CEL001", "Smartphone gama media 128 GB", "Motorola", "celulares", 389999, 15,
    "Celular con pantalla grande, buena cámara y batería para todo el día.",
    { pantalla: "6.6 pulgadas", almacenamiento_gb: 128, ram_gb: 6, camara_mp: 50, bateria_mah: 5000 },
    ["smartphone", "android", "gama media"]),
  p("CEL002", "Smartphone gama alta 256 GB", "Samsung", "celulares", 1199999, 8,
    "Celular de gama alta con pantalla AMOLED y cámara principal de alta resolución.",
    { pantalla: "6.7 pulgadas", almacenamiento_gb: 256, ram_gb: 12, camara_mp: 200, bateria_mah: 5000 },
    ["smartphone", "android", "gama alta", "fotografia"]),
  p("CEL003", "Smartphone económico 64 GB", "Xiaomi", "celulares", 219999, 25,
    "Opción accesible para uso diario: redes, mensajes y videos.",
    { pantalla: "6.5 pulgadas", almacenamiento_gb: 64, ram_gb: 4, camara_mp: 50, bateria_mah: 5000 },
    ["smartphone", "android", "economico"]),
  p("CEL004", "Smartphone gama media-alta 256 GB", "Xiaomi", "celulares", 599999, 12,
    "Buen rendimiento para juegos y fotos, con carga rápida.",
    { pantalla: "6.67 pulgadas", almacenamiento_gb: 256, ram_gb: 8, camara_mp: 108, bateria_mah: 5000 },
    ["smartphone", "android", "gaming", "carga rapida"]),
  p("CEL005", "Celular básico dual SIM", "Nokia", "celulares", 59999, 30,
    "Teléfono con teclas, batería de larga duración y uso simple.",
    { pantalla: "2.8 pulgadas", almacenamiento_gb: 0, dual_sim: true },
    ["celular basico", "teclas", "adultos mayores"]),
  p("CEL006", "Smartphone gama media 256 GB", "Samsung", "celulares", 549999, 14,
    "Pantalla fluida, triple cámara y buen espacio de almacenamiento.",
    { pantalla: "6.6 pulgadas", almacenamiento_gb: 256, ram_gb: 8, camara_mp: 50, bateria_mah: 5000 },
    ["smartphone", "android", "gama media"]),

  // ---------------- TELEVISORES ----------------
  p("TV001", "Smart TV LED 32 pulgadas HD", "Philco", "televisores", 259999, 14,
    "Televisor compacto con apps de streaming, ideal para dormitorio o cocina.",
    { pulgadas: 32, resolucion: "HD", smart_tv: true, hdmi: 2 },
    ["tv", "smart tv", "chico"]),
  p("TV002", "Smart TV LED 43 pulgadas Full HD", "Noblex", "televisores", 429999, 10,
    "Imagen Full HD y acceso a plataformas de streaming.",
    { pulgadas: 43, resolucion: "Full HD", smart_tv: true, hdmi: 3 },
    ["tv", "smart tv", "full hd"]),
  p("TV003", "Smart TV 50 pulgadas 4K UHD", "LG", "televisores", 649999, 9,
    "Resolución 4K con sistema webOS y control remoto con comando por voz.",
    { pulgadas: 50, resolucion: "4K UHD", smart_tv: true, sistema: "webOS", hdmi: 3 },
    ["tv", "smart tv", "4k"]),
  p("TV004", "Smart TV 55 pulgadas 4K UHD", "Samsung", "televisores", 749999, 11,
    "Pantalla 4K con sistema Tizen y modo juego.",
    { pulgadas: 55, resolucion: "4K UHD", smart_tv: true, sistema: "Tizen", hdmi: 3 },
    ["tv", "smart tv", "4k"]),
  p("TV005", "Smart TV 65 pulgadas 4K QLED", "Samsung", "televisores", 1299999, 5,
    "Pantalla grande con tecnología QLED para colores intensos, ideal para cine en casa.",
    { pulgadas: 65, resolucion: "4K UHD", tecnologia: "QLED", smart_tv: true, sistema: "Tizen", hdmi: 4 },
    ["tv", "smart tv", "4k", "qled", "cine"]),
  p("TV006", "Smart TV 75 pulgadas 4K UHD", "TCL", "televisores", 1549999, 4,
    "Pantalla de gran tamaño para salas amplias, con Google TV.",
    { pulgadas: 75, resolucion: "4K UHD", smart_tv: true, sistema: "Google TV", hdmi: 3 },
    ["tv", "smart tv", "4k", "gran tamano"]),

  // ---------------- AUDIO ----------------
  p("AUD001", "Auriculares Bluetooth in-ear", "JBL", "audio", 49999, 40,
    "Auriculares inalámbricos livianos con micrófono para llamadas.",
    { tipo: "in-ear", conexion: "Bluetooth", autonomia_horas: 8, microfono: true },
    ["auriculares", "inalambrico", "deporte"]),
  p("AUD002", "Auriculares inalámbricos con cancelación de ruido", "Sony", "audio", 299999, 10,
    "Auriculares over-ear con cancelación activa de ruido y larga autonomía.",
    { tipo: "over-ear", conexion: "Bluetooth", autonomia_horas: 30, cancelacion_ruido: true },
    ["auriculares", "cancelacion de ruido", "viaje"]),
  p("AUD003", "Auriculares gamer con micrófono", "Redragon", "audio", 59999, 18,
    "Auriculares con sonido envolvente y micrófono para juegos online.",
    { tipo: "over-ear", conexion: "USB", microfono: true, luces_led: true },
    ["auriculares", "gamer", "pc"]),
  p("AUD004", "Parlante Bluetooth portátil resistente al agua", "JBL", "audio", 119999, 20,
    "Parlante portátil con buen volumen, resistente al agua y al polvo.",
    { conexion: "Bluetooth", autonomia_horas: 12, resistente_agua: true },
    ["parlante", "portatil", "playa", "outdoor"]),
  p("AUD005", "Soundbar 2.1 con subwoofer inalámbrico", "LG", "audio", 349999, 7,
    "Barra de sonido con subwoofer para mejorar el audio del televisor.",
    { canales: "2.1", potencia_w: 300, conexion: ["HDMI", "Bluetooth", "Óptica"] },
    ["soundbar", "home theater", "tv"]),
  p("AUD006", "Barra de sonido 2.0", "Philips", "audio", 159999, 12,
    "Barra compacta, fácil de instalar, para mejorar el sonido de la TV.",
    { canales: "2.0", potencia_w: 80, conexion: ["HDMI ARC", "Bluetooth"] },
    ["soundbar", "tv", "economico"]),
  p("AUD007", "Torre de sonido Bluetooth 2000 W", "LG", "audio", 499999, 6,
    "Equipo de sonido potente con luces, ideal para reuniones y fiestas.",
    { potencia_w: 2000, conexion: ["Bluetooth", "USB", "Radio FM"], luces_led: true },
    ["torre de sonido", "fiestas", "karaoke"]),

  // ---------------- LAVARROPAS ----------------
  p("LAV001", "Lavarropas carga frontal 8 kg 1000 rpm", "Drean", "lavarropas", 899999, 8,
    "Lavarropas de carga frontal con múltiples programas de lavado.",
    { capacidad_kg: 8, carga: "frontal", rpm: 1000, programas: 15 },
    ["lavarropas", "carga frontal", "familia"]),
  p("LAV002", "Lavarropas carga frontal 9 kg inverter", "LG", "lavarropas", 1199999, 6,
    "Motor inverter, más silencioso y eficiente.",
    { capacidad_kg: 9, carga: "frontal", rpm: 1200, motor: "inverter", eficiencia: "A" },
    ["lavarropas", "inverter", "eficiente"]),
  p("LAV003", "Lavarropas carga superior 10 kg", "Whirlpool", "lavarropas", 999999, 7,
    "Carga superior, cómodo para ropa de uso diario y grandes volúmenes.",
    { capacidad_kg: 10, carga: "superior", rpm: 800 },
    ["lavarropas", "carga superior", "familia numerosa"]),
  p("LAV004", "Lavasecarropas 8/5 kg", "Samsung", "lavarropas", 1499999, 4,
    "Lava y seca en el mismo equipo, ideal para espacios reducidos.",
    { capacidad_lavado_kg: 8, capacidad_secado_kg: 5, carga: "frontal", rpm: 1200 },
    ["lavasecarropas", "secado", "departamento"]),

  // ---------------- HELADERAS Y FREEZERS ----------------
  p("HEL001", "Heladera con freezer 300 litros", "Gafa", "heladeras", 849999, 9,
    "Heladera tradicional con freezer superior, ideal para familias chicas.",
    { capacidad_l: 300, no_frost: false, eficiencia: "A" },
    ["heladera", "freezer", "familia"]),
  p("HEL002", "Heladera No Frost 370 litros", "Whirlpool", "heladeras", 1299999, 6,
    "No Frost: no hay que descongelar, y el frío se distribuye parejo.",
    { capacidad_l: 370, no_frost: true, eficiencia: "A" },
    ["heladera", "no frost"]),
  p("HEL003", "Heladera Side by Side 560 litros", "Samsung", "heladeras", 2399999, 3,
    "Dos puertas, gran capacidad, con dispenser de agua.",
    { capacidad_l: 560, no_frost: true, dispenser_agua: true },
    ["heladera", "side by side", "gran capacidad"]),
  p("HEL004", "Freezer horizontal 200 litros", "Peabody", "heladeras", 699999, 8,
    "Freezer horizontal para almacenar carnes y comida congelada.",
    { capacidad_l: 200, tipo: "horizontal" },
    ["freezer", "congelados"]),

  // ---------------- COCINAS Y HORNOS ----------------
  p("COC001", "Cocina a gas 4 hornallas 56 cm", "Orbis", "cocinas", 649999, 8,
    "Cocina a gas con horno y encendido eléctrico.",
    { hornallas: 4, ancho_cm: 56, combustible: "gas", encendido_electrico: true },
    ["cocina", "gas"]),
  p("COC002", "Cocina multigas 5 hornallas con grill", "Longvie", "cocinas", 899999, 5,
    "Cocina de 5 hornallas con grill eléctrico y luz en el horno.",
    { hornallas: 5, combustible: "gas", grill: true, luz_horno: true },
    ["cocina", "gas", "grill"]),
  p("COC003", "Horno eléctrico 40 litros", "Atma", "cocinas", 129999, 15,
    "Horno de mesa con dos resistencias y temperatura regulable.",
    { capacidad_l: 40, potencia_w: 1500, tipo: "eléctrico" },
    ["horno electrico", "mesada"]),

  // ---------------- MICROONDAS ----------------
  p("MIC001", "Microondas 20 litros", "BGH", "microondas", 139999, 20,
    "Microondas simple con potencia regulable y temporizador.",
    { capacidad_l: 20, potencia_w: 700, grill: false },
    ["microondas", "economico"]),
  p("MIC002", "Microondas 28 litros con grill", "Samsung", "microondas", 249999, 10,
    "Microondas con función grill para gratinar.",
    { capacidad_l: 28, potencia_w: 900, grill: true },
    ["microondas", "grill"]),

  // ---------------- AIRES ACONDICIONADOS ----------------
  p("AIR001", "Aire acondicionado split frío/calor 2250 frigorías", "Surrey", "aires_acondicionados", 749999, 10,
    "Equipo para ambientes chicos, con modo frío y calor.",
    { capacidad_frigorias: 2250, tipo: "split", frio_calor: true, inverter: false, ambiente_m2: "hasta 20" },
    ["aire", "split", "frio calor", "dormitorio"]),
  p("AIR002", "Aire acondicionado split inverter 3000 frigorías", "BGH", "aires_acondicionados", 949999, 8,
    "Tecnología inverter para menor consumo y temperatura más estable.",
    { capacidad_frigorias: 3000, tipo: "split", frio_calor: true, inverter: true, ambiente_m2: "hasta 28" },
    ["aire", "split", "inverter", "ahorro"]),
  p("AIR003", "Aire acondicionado split inverter 4500 frigorías", "LG", "aires_acondicionados", 1399999, 5,
    "Para ambientes amplios, con funcionamiento silencioso.",
    { capacidad_frigorias: 4500, tipo: "split", frio_calor: true, inverter: true, ambiente_m2: "hasta 45" },
    ["aire", "split", "inverter", "living"]),
  p("AIR004", "Aire acondicionado portátil 2500 frigorías", "Kendal", "aires_acondicionados", 699999, 6,
    "Equipo portátil, sin instalación fija, se mueve de una habitación a otra.",
    { capacidad_frigorias: 2500, tipo: "portátil", frio_calor: false },
    ["aire", "portatil", "sin instalacion"]),
  p("AIR005", "Aire acondicionado split inverter 5500 frigorías", "Samsung", "aires_acondicionados", 1799999, 3,
    "Gran potencia para locales o ambientes de gran tamaño.",
    { capacidad_frigorias: 5500, tipo: "split", frio_calor: true, inverter: true, ambiente_m2: "hasta 60" },
    ["aire", "split", "inverter", "local"]),

  // ---------------- VENTILACIÓN Y CALEFACCIÓN ----------------
  p("VEN001", "Ventilador de pie 20 pulgadas", "Liliana", "ventilacion_calefaccion", 79999, 25,
    "Ventilador con tres velocidades y altura regulable.",
    { tipo: "de pie", pulgadas: 20, velocidades: 3 },
    ["ventilador", "verano"]),
  p("VEN002", "Turbo ventilador 18 pulgadas", "Liliana", "ventilacion_calefaccion", 89999, 18,
    "Mayor caudal de aire, ideal para ambientes grandes.",
    { tipo: "turbo", pulgadas: 18, velocidades: 3 },
    ["ventilador", "verano", "potente"]),
  p("VEN003", "Caloventor eléctrico 2000 W", "Liliana", "ventilacion_calefaccion", 59999, 22,
    "Calefacción rápida para ambientes chicos, con termostato.",
    { tipo: "caloventor", potencia_w: 2000, termostato: true },
    ["calefaccion", "invierno", "electrico"]),
  p("VEN004", "Calefactor a gas tiro balanceado 3000 kcal", "Peabody", "ventilacion_calefaccion", 349999, 7,
    "Calefactor de gas con tiro balanceado, seguro para interiores.",
    { tipo: "gas tiro balanceado", potencia_kcal: 3000 },
    ["calefaccion", "invierno", "gas"]),

  // ---------------- PEQUEÑOS ELECTRODOMÉSTICOS ----------------
  p("PEQ001", "Cafetera de filtro 1.5 litros", "Oster", "pequenos_electrodomesticos", 79999, 16,
    "Prepara hasta 12 tazas con función de mantener caliente.",
    { capacidad_l: 1.5, potencia_w: 900, tipo: "filtro" },
    ["cafetera", "desayuno"]),
  p("PEQ002", "Licuadora 1.5 litros 600 W", "Philips", "pequenos_electrodomesticos", 99999, 14,
    "Licuadora con jarra de vidrio y varias velocidades.",
    { capacidad_l: 1.5, potencia_w: 600, jarra: "vidrio" },
    ["licuadora", "batidos"]),
  p("PEQ003", "Freidora de aire 4 litros", "Atma", "pequenos_electrodomesticos", 129999, 20,
    "Cocina con poco o nada de aceite, con temporizador y temperatura regulable.",
    { capacidad_l: 4, potencia_w: 1500, tipo: "freidora de aire" },
    ["freidora", "airfryer", "cocina saludable"]),
  p("PEQ004", "Aspiradora robot con mapeo", "Xiaomi", "pequenos_electrodomesticos", 449999, 6,
    "Aspira y limpia solo, con mapeo del hogar y control desde el celular.",
    { tipo: "robot", app_celular: true, autonomia_min: 120 },
    ["aspiradora", "robot", "hogar inteligente"]),
  p("PEQ005", "Aspiradora de mano inalámbrica", "Electrolux", "pequenos_electrodomesticos", 199999, 9,
    "Liviana y sin cables, práctica para limpiezas rápidas.",
    { tipo: "de mano", inalambrica: true, autonomia_min: 40 },
    ["aspiradora", "inalambrica"]),
  p("PEQ006", "Pava eléctrica 1.7 litros", "Atma", "pequenos_electrodomesticos", 44999, 30,
    "Hierve agua rápido, con corte automático.",
    { capacidad_l: 1.7, potencia_w: 2000, corte_automatico: true },
    ["pava electrica", "mate", "cocina"]),
  p("PEQ007", "Tostadora 2 rebanadas", "Oster", "pequenos_electrodomesticos", 39999, 24,
    "Tostadora con regulación de tostado y bandeja para migas.",
    { rebanadas: 2, potencia_w: 800 },
    ["tostadora", "desayuno"]),

  // ---------------- COMPUTACIÓN ----------------
  p("COM001", "Notebook 15.6 pulgadas Core i5 8 GB 256 GB SSD", "Lenovo", "computacion", 1099999, 7,
    "Notebook para estudio y trabajo diario, con SSD rápido.",
    { pantalla: "15.6 pulgadas", procesador: "Core i5", ram_gb: 8, almacenamiento_gb: 256, tipo_almacenamiento: "SSD" },
    ["notebook", "estudio", "trabajo"]),
  p("COM002", "Notebook 14 pulgadas Ryzen 5 16 GB 512 GB SSD", "HP", "computacion", 1349999, 5,
    "Notebook liviana con buen rendimiento y más memoria.",
    { pantalla: "14 pulgadas", procesador: "Ryzen 5", ram_gb: 16, almacenamiento_gb: 512, tipo_almacenamiento: "SSD" },
    ["notebook", "liviana", "trabajo"]),
  p("COM003", "Tablet 10.4 pulgadas 64 GB", "Samsung", "computacion", 399999, 12,
    "Tablet para series, lectura y clases online.",
    { pantalla: "10.4 pulgadas", almacenamiento_gb: 64, ram_gb: 4, wifi: true },
    ["tablet", "estudio", "entretenimiento"]),
  p("COM004", "Monitor 24 pulgadas Full HD", "LG", "computacion", 189999, 14,
    "Monitor IPS con entrada HDMI, ideal para oficina y estudio.",
    { pulgadas: 24, resolucion: "Full HD", panel: "IPS", hdmi: 1 },
    ["monitor", "oficina", "pc"]),

  // ---------------- WEARABLES ----------------
  p("WEA001", "Smartwatch con GPS", "Xiaomi", "wearables", 149999, 15,
    "Reloj inteligente con GPS, notificaciones y seguimiento de actividad.",
    { gps: true, autonomia_dias: 12, resistente_agua: true },
    ["smartwatch", "deporte", "salud"]),
  p("WEA002", "Pulsera de actividad", "Xiaomi", "wearables", 49999, 35,
    "Pulsera liviana con contador de pasos, sueño y frecuencia cardíaca.",
    { gps: false, autonomia_dias: 14, resistente_agua: true },
    ["pulsera", "deporte", "economica"]),

  // ================= PRODUCTOS AGREGADOS =================

  // ---------------- CELULARES (más modelos) ----------------
  p("CEL007", "Smartphone plegable 256 GB", "Samsung", "celulares", 1899999, 3,
    "Celular plegable con pantalla interna amplia para multitarea.",
    { pantalla: "6.7 pulgadas plegable", almacenamiento_gb: 256, ram_gb: 8, camara_mp: 12, bateria_mah: 3700 },
    ["smartphone", "plegable", "gama alta"]),
  p("CEL008", "Smartphone 5G gama media 256 GB", "Motorola", "celulares", 479999, 13,
    "Conectividad 5G, pantalla fluida y cámara triple.",
    { pantalla: "6.7 pulgadas", almacenamiento_gb: 256, ram_gb: 8, camara_mp: 50, bateria_mah: 5000, red_5g: true },
    ["smartphone", "5g", "gama media"]),
  p("CEL009", "Smartphone gama media 128 GB", "Samsung", "celulares", 349999, 18,
    "Equilibrio entre precio y prestaciones para uso diario.",
    { pantalla: "6.5 pulgadas", almacenamiento_gb: 128, ram_gb: 4, camara_mp: 50, bateria_mah: 5000 },
    ["smartphone", "android", "gama media"]),

  // ---------------- TELEVISORES (más modelos) ----------------
  p("TV007", "Smart TV 43 pulgadas 4K UHD", "Samsung", "televisores", 539999, 12,
    "Resolución 4K en tamaño mediano, ideal para living o dormitorio grande.",
    { pulgadas: 43, resolucion: "4K UHD", smart_tv: true, sistema: "Tizen", hdmi: 3 },
    ["tv", "smart tv", "4k"]),
  p("TV008", "Smart TV 58 pulgadas 4K UHD", "Philips", "televisores", 699999, 8,
    "Pantalla 4K con buena relación precio-tamaño.",
    { pulgadas: 58, resolucion: "4K UHD", smart_tv: true, hdmi: 3 },
    ["tv", "smart tv", "4k"]),
  p("TV009", "Smart TV 32 pulgadas HD Google TV", "TCL", "televisores", 249999, 16,
    "Televisor chico con sistema Google TV y control por voz.",
    { pulgadas: 32, resolucion: "HD", smart_tv: true, sistema: "Google TV", hdmi: 2 },
    ["tv", "smart tv", "chico"]),

  // ---------------- AUDIO (más modelos) ----------------
  p("AUD008", "Auriculares True Wireless con estuche de carga", "Samsung", "audio", 129999, 22,
    "Auriculares sin cables con estuche de carga y micrófono.",
    { tipo: "in-ear", conexion: "Bluetooth", autonomia_horas: 6, estuche_carga: true },
    ["auriculares", "inalambrico", "true wireless"]),
  p("AUD009", "Parlante Bluetooth mediano 20 W", "Sony", "audio", 89999, 17,
    "Parlante de buen volumen para uso en casa o salidas.",
    { conexion: "Bluetooth", potencia_w: 20, autonomia_horas: 15 },
    ["parlante", "portatil"]),
  p("AUD010", "Parlante inteligente con asistente de voz", "Xiaomi", "audio", 79999, 14,
    "Parlante con control por voz para música, alarmas y hogar inteligente.",
    { conexion: ["Wi-Fi", "Bluetooth"], asistente_voz: true },
    ["parlante", "smart", "hogar inteligente"]),
  p("AUD011", "Radio portátil AM/FM", "Philips", "audio", 39999, 20,
    "Radio liviana a pilas o con conexión a corriente.",
    { bandas: ["AM", "FM"], alimentacion: "pilas o 220V" },
    ["radio", "portatil"]),

  // ---------------- LAVARROPAS Y SECARROPAS (más modelos) ----------------
  p("LAV005", "Secarropas centrífugo 5 kg", "Drean", "lavarropas", 199999, 10,
    "Centrífuga para escurrir la ropa rápido y ahorrar tiempo de secado.",
    { capacidad_kg: 5, tipo: "centrífugo" },
    ["secarropas", "centrifuga"]),
  p("LAV006", "Lavarropas carga frontal 7 kg", "Candy", "lavarropas", 799999, 9,
    "Lavarropas compacto para parejas o familias chicas.",
    { capacidad_kg: 7, carga: "frontal", rpm: 1000 },
    ["lavarropas", "carga frontal", "compacto"]),

  // ---------------- LAVAVAJILLAS ----------------
  p("LVJ001", "Lavavajillas 12 cubiertos", "Whirlpool", "lavavajillas", 1099999, 5,
    "Lavavajillas de tamaño estándar con varios programas.",
    { cubiertos: 12, programas: 6, eficiencia: "A" },
    ["lavavajillas", "cocina"]),
  p("LVJ002", "Lavavajillas compacto 8 cubiertos", "Midea", "lavavajillas", 799999, 6,
    "Versión compacta para cocinas pequeñas.",
    { cubiertos: 8, programas: 5 },
    ["lavavajillas", "compacto"]),

  // ---------------- HELADERAS (más modelos) ----------------
  p("HEL005", "Frigobar 90 litros", "Philco", "heladeras", 349999, 12,
    "Heladera chica para oficina, dormitorio o quincho.",
    { capacidad_l: 90, tipo: "frigobar" },
    ["frigobar", "heladera", "compacta"]),
  p("HEL006", "Heladera French Door 500 litros", "LG", "heladeras", 2199999, 3,
    "Puertas dobles superiores y cajón inferior, gran capacidad.",
    { capacidad_l: 500, no_frost: true, tipo: "french door" },
    ["heladera", "french door", "gran capacidad"]),

  // ---------------- COCINAS Y HORNOS (más modelos) ----------------
  p("COC004", "Anafe vitrocerámico 2 zonas", "Atma", "cocinas", 119999, 11,
    "Anafe eléctrico de mesada, fácil de limpiar.",
    { zonas: 2, tipo: "vitrocerámico", potencia_w: 2800 },
    ["anafe", "electrico", "mesada"]),
  p("COC005", "Campana extractora 60 cm", "Whirlpool", "cocinas", 169999, 9,
    "Campana de cocina con tres velocidades y luz.",
    { ancho_cm: 60, velocidades: 3, luz: true },
    ["campana", "cocina"]),
  p("COC006", "Horno eléctrico empotrable 60 litros", "Longvie", "cocinas", 799999, 4,
    "Horno de empotrar con grill y ventilador.",
    { capacidad_l: 60, tipo: "empotrable", grill: true },
    ["horno", "empotrable", "electrico"]),

  // ---------------- AIRES ACONDICIONADOS (más modelos) ----------------
  p("AIR006", "Aire acondicionado split inverter 2250 frigorías", "Surrey", "aires_acondicionados", 849999, 7,
    "Equipo inverter para ambientes chicos, con menor consumo.",
    { capacidad_frigorias: 2250, tipo: "split", frio_calor: true, inverter: true, ambiente_m2: "hasta 20" },
    ["aire", "split", "inverter", "dormitorio"]),

  // ---------------- AGUA CALIENTE Y DISPENSERS ----------------
  p("AGU001", "Termotanque eléctrico 80 litros", "Rheem", "agua_caliente", 399999, 6,
    "Termotanque eléctrico para familias chicas.",
    { capacidad_l: 80, tipo: "eléctrico" },
    ["termotanque", "agua caliente", "electrico"]),
  p("AGU002", "Termotanque a gas 85 litros", "Longvie", "agua_caliente", 449999, 6,
    "Termotanque a gas con buena recuperación.",
    { capacidad_l: 85, tipo: "gas" },
    ["termotanque", "agua caliente", "gas"]),
  p("AGU003", "Calefón a gas 14 litros tiro natural", "Eskabe", "agua_caliente", 329999, 5,
    "Calefón de paso para agua caliente instantánea.",
    { capacidad_l_min: 14, tipo: "gas tiro natural" },
    ["calefon", "agua caliente", "gas"]),
  p("AGU004", "Dispenser de agua frío/calor", "Peabody", "agua_caliente", 169999, 13,
    "Dispenser de bidón con agua fría y caliente.",
    { tipo: "de pie", frio_calor: true },
    ["dispenser", "agua", "oficina"]),

  // ---------------- VENTILACIÓN, CALEFACCIÓN Y CLIMA (más modelos) ----------------
  p("VEN005", "Ventilador de techo con luz", "Liliana", "ventilacion_calefaccion", 129999, 8,
    "Ventilador de techo con luz LED y control remoto.",
    { tipo: "de techo", luz: true, control_remoto: true },
    ["ventilador", "techo", "verano"]),
  p("VEN006", "Humidificador ultrasónico 3 litros", "Atma", "ventilacion_calefaccion", 69999, 15,
    "Humidificador silencioso, útil en invierno con calefacción.",
    { capacidad_l: 3, tipo: "ultrasónico" },
    ["humidificador", "invierno"]),
  p("VEN007", "Purificador de aire con filtro HEPA", "Xiaomi", "ventilacion_calefaccion", 249999, 7,
    "Purificador con filtro HEPA para ambientes medianos.",
    { filtro: "HEPA", ambiente_m2: "hasta 35", app_celular: true },
    ["purificador", "aire", "alergias"]),
  p("VEN008", "Estufa de cuarzo 2 velas", "Liliana", "ventilacion_calefaccion", 49999, 19,
    "Estufa eléctrica de dos velas para ambientes chicos.",
    { tipo: "cuarzo", velas: 2, potencia_w: 1200 },
    ["estufa", "invierno", "electrica"]),
  p("VEN009", "Radiador eléctrico a aceite 11 elementos", "Liliana", "ventilacion_calefaccion", 139999, 9,
    "Calor parejo y seguro, sin consumir oxígeno.",
    { tipo: "radiador a aceite", elementos: 11, potencia_w: 2400 },
    ["radiador", "invierno", "electrico"]),

  // ---------------- PEQUEÑOS ELECTRODOMÉSTICOS (más modelos) ----------------
  p("PEQ008", "Procesadora de alimentos 1000 W", "Philips", "pequenos_electrodomesticos", 179999, 8,
    "Procesadora con varios accesorios para picar, rallar y mezclar.",
    { potencia_w: 1000, capacidad_l: 2 },
    ["procesadora", "cocina"]),
  p("PEQ009", "Batidora de mano 500 W", "Oster", "pequenos_electrodomesticos", 49999, 21,
    "Batidora de mano con vaso medidor.",
    { potencia_w: 500, tipo: "de mano" },
    ["batidora", "cocina"]),
  p("PEQ010", "Sandwichera y panquequera", "Atma", "pequenos_electrodomesticos", 39999, 25,
    "Plancha antiadherente para sándwiches y panqueques.",
    { potencia_w: 750, antiadherente: true },
    ["sandwichera", "desayuno"]),
  p("PEQ011", "Plancha a vapor 2400 W", "Philips", "pequenos_electrodomesticos", 79999, 14,
    "Plancha con golpe de vapor y suela antiadherente.",
    { potencia_w: 2400, vapor: true },
    ["plancha", "ropa"]),
  p("PEQ012", "Cafetera de cápsulas", "Moulinex", "pequenos_electrodomesticos", 169999, 9,
    "Cafetera de cápsulas con presión alta para espresso.",
    { presion_bar: 19, tipo: "cápsulas" },
    ["cafetera", "espresso", "capsulas"]),
  p("PEQ013", "Olla de cocción lenta 5 litros", "Oster", "pequenos_electrodomesticos", 99999, 10,
    "Cocción lenta para guisos y carnes con poco trabajo.",
    { capacidad_l: 5, tipo: "cocción lenta" },
    ["olla electrica", "slow cooker", "cocina"]),
  p("PEQ014", "Arrocera eléctrica 1.8 litros", "Atma", "pequenos_electrodomesticos", 59999, 12,
    "Cocina arroz y mantiene caliente automáticamente.",
    { capacidad_l: 1.8, funcion_mantener_calor: true },
    ["arrocera", "cocina"]),

  // ---------------- CUIDADO PERSONAL ----------------
  p("CPE001", "Secador de pelo 2200 W", "Philips", "cuidado_personal", 59999, 20,
    "Secador con difusor y varias temperaturas.",
    { potencia_w: 2200, temperaturas: 3, difusor: true },
    ["secador", "pelo"]),
  p("CPE002", "Afeitadora eléctrica recargable", "Philips", "cuidado_personal", 89999, 13,
    "Afeitadora recargable con cabezal flotante.",
    { recargable: true, uso_humedo_seco: true },
    ["afeitadora", "cuidado personal"]),
  p("CPE003", "Planchita de pelo cerámica", "Philips", "cuidado_personal", 49999, 16,
    "Placas de cerámica con temperatura regulable.",
    { placas: "cerámica", temperatura_max_c: 210 },
    ["planchita", "pelo"]),

  // ---------------- COMPUTACIÓN (más modelos) ----------------
  p("COM005", "Notebook gamer 15.6 pulgadas con placa dedicada", "ASUS", "computacion", 2199999, 3,
    "Notebook para juegos con placa de video dedicada y pantalla de alta tasa de refresco.",
    { pantalla: "15.6 pulgadas", ram_gb: 16, almacenamiento_gb: 512, tipo_almacenamiento: "SSD", placa_video: "dedicada", hz: 144 },
    ["notebook", "gamer", "juegos"]),
  p("COM006", "Notebook 15.6 pulgadas Core i7 16 GB 512 GB SSD", "Dell", "computacion", 1699999, 4,
    "Notebook potente para trabajo y multitarea.",
    { pantalla: "15.6 pulgadas", procesador: "Core i7", ram_gb: 16, almacenamiento_gb: 512, tipo_almacenamiento: "SSD" },
    ["notebook", "trabajo", "potente"]),
  p("COM007", "Monitor gamer 27 pulgadas 165 Hz", "Samsung", "computacion", 429999, 6,
    "Monitor curvo con alta tasa de refresco para juegos.",
    { pulgadas: 27, hz: 165, resolucion: "Quad HD", hdmi: 2 },
    ["monitor", "gamer", "165hz"]),
  p("COM008", "Impresora multifunción WiFi tinta continua", "Epson", "computacion", 329999, 8,
    "Imprime, escanea y copia, con tanque de tinta de bajo costo por página.",
    { funciones: ["imprimir", "escanear", "copiar"], wifi: true, sistema: "tinta continua" },
    ["impresora", "multifuncion", "oficina"]),
  p("COM009", "Router WiFi 6 doble banda", "TP-Link", "redes", 99999, 15,
    "Router de alta velocidad para varios dispositivos conectados.",
    { wifi: "WiFi 6", bandas: "doble banda", puertos_lan: 4 },
    ["router", "wifi", "internet"]),
  p("COM010", "Combo teclado y mouse inalámbricos", "Logitech", "accesorios", 49999, 30,
    "Teclado y mouse sin cables con receptor USB.",
    { conexion: "inalámbrico USB", incluye: ["teclado", "mouse"] },
    ["teclado", "mouse", "oficina"]),
  p("COM011", "Webcam Full HD 1080p", "Logitech", "accesorios", 69999, 18,
    "Cámara web con micrófono integrado para videollamadas.",
    { resolucion: "1080p", microfono: true, conexion: "USB" },
    ["webcam", "videollamadas", "teletrabajo"]),
  p("COM012", "Disco SSD externo 1 TB", "Samsung", "accesorios", 149999, 12,
    "Almacenamiento externo rápido y portátil.",
    { capacidad_tb: 1, tipo: "SSD", conexion: "USB-C" },
    ["ssd", "almacenamiento", "backup"]),
  p("COM013", "Pendrive 128 GB USB 3.2", "Kingston", "accesorios", 14999, 40,
    "Pendrive de alta velocidad para transportar archivos.",
    { capacidad_gb: 128, conexion: "USB 3.2" },
    ["pendrive", "almacenamiento"]),

  // ---------------- GAMING ----------------
  p("GAM001", "Consola de videojuegos 1 TB", "Sony", "gaming", 1299999, 5,
    "Consola de última generación con almacenamiento interno rápido.",
    { almacenamiento_tb: 1, resolucion_max: "4K", control_inalambrico: true },
    ["consola", "videojuegos", "gaming"]),
  p("GAM002", "Joystick inalámbrico", "Microsoft", "gaming", 129999, 14,
    "Control inalámbrico compatible con consola y PC.",
    { conexion: ["Bluetooth", "USB"], compatible: ["consola", "PC"] },
    ["joystick", "control", "gaming"]),
  p("GAM003", "Silla gamer ergonómica", "Redragon", "gaming", 249999, 7,
    "Silla reclinable con soporte lumbar y apoyabrazos regulables.",
    { reclinable: true, soporte_lumbar: true, peso_max_kg: 120 },
    ["silla", "gamer", "escritorio"]),
  p("GAM004", "Teclado mecánico gamer retroiluminado", "Redragon", "gaming", 69999, 15,
    "Teclado mecánico con luces RGB y switches táctiles.",
    { tipo: "mecánico", retroiluminado: true, conexion: "USB" },
    ["teclado", "mecanico", "gamer"]),

  // ---------------- CÁMARAS Y DOMÓTICA ----------------
  p("CAM001", "Cámara de seguridad WiFi interior 1080p", "Xiaomi", "camaras_seguridad", 49999, 20,
    "Cámara giratoria con visión nocturna y control desde el celular.",
    { resolucion: "1080p", vision_nocturna: true, app_celular: true, uso: "interior" },
    ["camara", "seguridad", "wifi"]),
  p("CAM002", "Cámara de seguridad WiFi exterior", "TP-Link", "camaras_seguridad", 79999, 11,
    "Cámara resistente a la intemperie con visión nocturna.",
    { resolucion: "2K", vision_nocturna: true, resistente_agua: true, uso: "exterior" },
    ["camara", "seguridad", "exterior"]),
  p("DOM001", "Foco inteligente WiFi RGB", "Xiaomi", "domotica", 14999, 40,
    "Foco LED de colores controlable desde el celular o por voz.",
    { wifi: true, color: "RGB", control_voz: true },
    ["foco", "hogar inteligente", "luz"]),
  p("DOM002", "Enchufe inteligente WiFi", "TP-Link", "domotica", 12999, 45,
    "Enciende y apaga aparatos desde el celular.",
    { wifi: true, app_celular: true },
    ["enchufe", "hogar inteligente"]),
  p("DOM003", "Timbre con cámara WiFi", "Xiaomi", "domotica", 89999, 9,
    "Timbre que muestra quién llama en el celular.",
    { wifi: true, camara: true, audio_bidireccional: true },
    ["timbre", "hogar inteligente", "seguridad"]),

  // ---------------- WEARABLES (más modelos) ----------------
  p("WEA003", "Smartwatch gama alta con GPS", "Samsung", "wearables", 399999, 6,
    "Reloj inteligente con pantalla AMOLED, GPS y seguimiento de salud.",
    { gps: true, autonomia_dias: 2, resistente_agua: true, pantalla: "AMOLED" },
    ["smartwatch", "salud", "deporte"]),

  // ---------------- ACCESORIOS ----------------
  p("ACC001", "Cargador rápido 65 W USB-C", "Xiaomi", "accesorios", 29999, 35,
    "Cargador de carga rápida compatible con celulares y notebooks.",
    { potencia_w: 65, conexion: "USB-C" },
    ["cargador", "carga rapida"]),
  p("ACC002", "Power bank 20000 mAh", "Xiaomi", "accesorios", 39999, 28,
    "Batería externa para cargar el celular varias veces.",
    { capacidad_mah: 20000, puertos: 2 },
    ["power bank", "bateria externa"]),
  p("ACC003", "Soporte de TV inclinable 32 a 65 pulgadas", "Sin marca", "accesorios", 19999, 30,
    "Soporte de pared con inclinación regulable.",
    { pulgadas_min: 32, pulgadas_max: 65, tipo: "inclinable" },
    ["soporte tv", "pared"]),
  p("ACC004", "Cable HDMI 2.1 de 2 metros", "Sin marca", "accesorios", 9999, 60,
    "Cable de alta velocidad compatible con 4K.",
    { version: "HDMI 2.1", largo_m: 2 },
    ["cable", "hdmi", "4k"]),
  p("ACC005", "Funda y vidrio templado para celular", "Sin marca", "accesorios", 7999, 80,
    "Kit de protección para pantalla y cuerpo del celular.",
    { incluye: ["funda", "vidrio templado"] },
    ["funda", "proteccion", "celular"]),
];

// ---------------- VALIDACIÓN ----------------
function validar(lista) {
  const errores = [];
  const vistos = new Set();
  for (const x of lista) {
    if (!x.sku || !x.nombre || !x.categoriaId) errores.push(`Faltan datos básicos en: ${JSON.stringify(x.sku)}`);
    if (vistos.has(x.sku)) errores.push(`SKU repetido: ${x.sku}`);
    vistos.add(x.sku);
    if (typeof x.precio !== "number" || isNaN(x.precio) || x.precio <= 0) errores.push(`Precio inválido en ${x.sku}`);
    if (!Number.isInteger(x.stock) || x.stock < 0) errores.push(`Stock inválido en ${x.sku}`);
    if (x.categoriaId && !/^[a-z0-9_]+$/.test(x.categoriaId)) errores.push(`Categoría con formato inválido en ${x.sku}: ${x.categoriaId}`);
    if (typeof x.specs !== "object" || x.specs === null || Array.isArray(x.specs)) errores.push(`specs debe ser un objeto en ${x.sku}`);
    if (!Array.isArray(x.tags)) errores.push(`tags debe ser una lista en ${x.sku}`);
  }
  return errores;
}

function resumen(lista) {
  const porCategoria = {};
  for (const x of lista) porCategoria[x.categoriaId] = (porCategoria[x.categoriaId] || 0) + 1;
  console.log(`Total de productos: ${lista.length}`);
  console.table(porCategoria);
}

// ---------------- EJECUCIÓN ----------------
async function main() {
  const errores = validar(productos);
  if (errores.length > 0) {
    console.error("Se encontraron errores, no se cargó nada:");
    errores.forEach((e) => console.error(" - " + e));
    process.exit(1);
  }

  resumen(productos);

  if (process.argv.includes("--dry")) {
    console.log("Modo prueba (--dry): no se cargó nada en Firestore.");
    return;
  }

  const serviceAccount = require("./serviceAccountKey.json");
  admin.initializeApp({
    credential: admin.cert(serviceAccount),
  });
  const db = require("firebase-admin/firestore").getFirestore();

  const writer = db.bulkWriter();
  for (const prod of productos) {
    // El SKU es el ID del documento: si lo corrés de nuevo, actualiza en vez de duplicar
    writer.set(db.collection("productos").doc(prod.sku), {
      ...prod,
      nombreBusqueda: prod.nombre.toLowerCase(), // útil para buscar sin distinguir mayúsculas
      activo: true,                              // permite ocultar un producto sin borrarlo
      imagenUrl: "",                             // completá con la URL real de la foto
      actualizado: require("firebase-admin/firestore").FieldValue.serverTimestamp(),
    });
  }
  await writer.close();

  console.log(`${productos.length} productos cargados en la colección "productos".`);
}

main().catch((err) => {
  console.error("Error durante la carga:", err);
  process.exit(1);
});

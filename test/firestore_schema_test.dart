import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app_mobile/modelo/carrito.dart';
import 'package:mi_app_mobile/modelo/categoria.dart';
import 'package:mi_app_mobile/modelo/configuracion.dart';
import 'package:mi_app_mobile/modelo/conversacion.dart';
import 'package:mi_app_mobile/modelo/documento.dart';
import 'package:mi_app_mobile/modelo/mensaje.dart';
import 'package:mi_app_mobile/modelo/pedido.dart';
import 'package:mi_app_mobile/modelo/producto.dart';
import 'package:mi_app_mobile/modelo/usuario.dart';

void main() {
  group('COLECCIÓN 1: usuarios/{uid}', () {
    test('Serialización y deserialización correcta según el esquema', () {
      final now = DateTime(2026, 10, 25, 20, 0, 0);
      final raw = {
        'nombre': 'Juan',
        'apellido': 'Pérez',
        'dni': '12345678', // DNI como texto
        'email': 'juan@ejemplo.com',
        'fotoPerfil': 'https://storage.googleapis.com/perfil.jpg',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'activo': true,
      };

      final usuario = Usuario.fromFirestore(raw, 'UID_123');

      expect(usuario.id, 'UID_123');
      expect(usuario.nombre, 'Juan');
      expect(usuario.apellido, 'Pérez');
      expect(usuario.dni, isA<String>());
      expect(usuario.dni, '12345678');
      expect(usuario.email, 'juan@ejemplo.com');
      expect(usuario.fotoPerfil, 'https://storage.googleapis.com/perfil.jpg');
      expect(usuario.activo, true);

      final map = usuario.toFirestore();
      expect(map['dni'], isA<String>());
      expect(map.containsKey('password'), false);
      expect(map.containsKey('contrasena'), false);
    });

    test('DNI numérico en origen se convierte a texto', () {
      final raw = {
        'nombre': 'Ana',
        'apellido': 'García',
        'dni': 98765432, // Viene como número
        'email': 'ana@ejemplo.com',
        'fotoPerfil': '',
        'activo': true,
      };

      final usuario = Usuario.fromFirestore(raw, 'UID_456');
      expect(usuario.dni, '98765432');
      expect(usuario.dni, isA<String>());
    });
  });

  group('COLECCIÓN 2: productos/{pid}', () {
    test('Serialización con campos obligatorios y opcionales', () {
      final now = DateTime(2026, 10, 25, 12, 0, 0);
      final raw = {
        'nombre': 'Smart TV 55',
        'descripcion': '4K UHD, HDR10',
        'marca': 'Samsung',
        'categoriaId': 'electronica',
        'precio': 750000.5,
        'moneda': 'ARS',
        'stock': 15,
        'activo': true,
        'sku': 'SAMS-55-4K',
        'imagenUrl': 'https://ejemplo.com/tv.jpg',
        'urlExterna': 'https://ejemplo.com/comprar',
        'storagePath': 'productos/tv55.png',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      final prod = Producto.fromFirestore(raw, 'PID_001');

      expect(prod.id, 'PID_001');
      expect(prod.nombre, 'Smart TV 55');
      expect(prod.precio, 750000.5);
      expect(prod.moneda, 'ARS');
      expect(prod.stock, 15);
      expect(prod.stock, isA<int>());
      expect(prod.storagePath, 'productos/tv55.png');

      final map = prod.toFirestore();
      expect(map['categoriaId'], 'electronica');
      expect(map['precio'], 750000.5);
      expect(map['storagePath'], 'productos/tv55.png');
    });

    test('Valores por defecto ante datos incompletos', () {
      final prod = Producto.fromFirestore({}, 'PID_VACIO');
      expect(prod.nombre, '');
      expect(prod.precio, 0.0);
      expect(prod.stock, 0);
      expect(prod.moneda, 'ARS');
      expect(prod.activo, true);
    });
  });

  group('COLECCIÓN 3: categorias/{categoriaId}', () {
    test('Mapea correctamente id legible y campos', () {
      final raw = {
        'nombre': 'Electrónica',
        'descripcion': 'Televisores, audio y video',
        'activo': true,
      };

      final cat = Categoria.fromFirestore(raw, 'electronica');
      expect(cat.id, 'electronica');
      expect(cat.nombre, 'Electrónica');
      expect(cat.activo, true);

      final map = cat.toFirestore();
      expect(map['nombre'], 'Electrónica');
      expect(map.containsKey('createdAt'), false);
    });
  });

  group('COLECCIÓN 4: conversaciones/{cid} y mensajes', () {
    test('Conversación y subcolección de mensajes', () {
      final now = DateTime(2026, 10, 25, 10, 0, 0);
      final convRaw = {
        'usuarioId': 'UID_123',
        'titulo': 'Consulta sobre TV',
        'estado': 'activa',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      final conv = Conversacion.fromFirestore(convRaw, 'CID_789');
      expect(conv.usuarioId, 'UID_123');
      expect(conv.titulo, 'Consulta sobre TV');

      final msgRaw = {
        'autor': 'user',
        'mensaje': '¿Tienen stock del Samsung 55?',
        'createdAt': Timestamp.fromDate(now),
        'tipo': 'texto',
        'productoId': 'PID_001',
      };

      final msg = Mensaje.fromFirestore(msgRaw, 'MID_001');
      expect(msg.autor, 'user');
      expect(msg.mensaje, '¿Tienen stock del Samsung 55?');
      expect(msg.productoId, 'PID_001');

      final msgMap = msg.toFirestore();
      expect(msgMap['autor'], 'user');
      expect(msgMap['tipo'], 'texto');
    });
  });

  group('COLECCIÓN 5: carritos/{uid} y subcolección items/{productoId}', () {
    test('Carrito y sus items con docId igual a productoId', () {
      final now = DateTime(2026, 10, 25, 11, 0, 0);
      final itemRaw = {
        'cantidad': 2,
        'addedAt': Timestamp.fromDate(now),
      };

      final item = ItemCarrito.fromFirestore(itemRaw, 'PID_001');
      expect(item.productoId, 'PID_001');
      expect(item.cantidad, 2);

      final itemMap = item.toFirestore();
      expect(itemMap['cantidad'], 2);
      // No contiene campos duplicados como nombre o precio
      expect(itemMap.containsKey('nombre'), false);
      expect(itemMap.containsKey('precio'), false);

      final carritoRaw = {
        'estado': 'activo',
        'moneda': 'ARS',
        'updatedAt': Timestamp.fromDate(now),
      };

      final carrito = Carrito.fromFirestore(
        carritoRaw,
        'UID_123',
        items: [item],
      );

      expect(carrito.id, 'UID_123');
      expect(carrito.estado, 'activo');
      expect(carrito.moneda, 'ARS');
      expect(carrito.items.length, 1);
      expect(carrito.items.first.productoId, 'PID_001');
    });

    test('Fuerza cantidad positiva si viene inválida', () {
      final item = ItemCarrito.fromFirestore({'cantidad': -5}, 'PID_NEGATIVO');
      expect(item.cantidad, 1);
    });
  });

  group('COLECCIÓN 6: pedidos/{pedidoId}', () {
    test('Pedido con array de items histórico', () {
      final now = DateTime(2026, 10, 25, 15, 0, 0);
      final raw = {
        'usuarioId': 'UID_123',
        'estado': 'pendiente',
        'moneda': 'ARS',
        'subtotal': 1500000.0,
        'costoEnvio': 10000.0,
        'total': 1510000.0,
        'metodoPago': 'mercadopago',
        'estadoPago': 'pendiente',
        'pagoReferencia': 'MP-REF-9988',
        'telegramChatId': '123456789',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'items': [
          {
            'productoId': 'PID_001',
            'nombre': 'Smart TV 55',
            'sku': 'SAMS-55-4K',
            'precioUnitario': 750000.0,
            'cantidad': 2,
          }
        ],
      };

      final pedido = Pedido.fromFirestore(raw, 'PED_12345');

      expect(pedido.id, 'PED_12345');
      expect(pedido.usuarioId, 'UID_123');
      expect(pedido.subtotal, 1500000.0);
      expect(pedido.total, 1510000.0);
      expect(pedido.moneda, 'ARS');
      expect(pedido.telegramChatId, '123456789');
      expect(pedido.pagoReferencia, 'MP-REF-9988');
      expect(pedido.items.length, 1);
      expect(pedido.items.first.sku, 'SAMS-55-4K');
      expect(pedido.items.first.precioUnitario, 750000.0);

      final map = pedido.toFirestore();
      expect(map['total'], 1510000.0);
      expect(map['telegramChatId'], '123456789');
      expect((map['items'] as List).length, 1);
    });
  });

  group('COLECCIÓN 7: documentos/{documentoId}', () {
    test('Documento con metadata de Storage', () {
      final now = DateTime(2026, 10, 25, 16, 0, 0);
      final raw = {
        'nombre': 'Catalogo2026.pdf',
        'storagePath': 'documentos/catalogo_2026.pdf',
        'contentType': 'application/pdf',
        'estado': 'activo',
        'createdAt': Timestamp.fromDate(now),
        'usuarioId': 'UID_123',
        'negocioId': 'TIENDA_CENTRAL',
      };

      final doc = Documento.fromFirestore(raw, 'DOC_001');

      expect(doc.id, 'DOC_001');
      expect(doc.nombre, 'Catalogo2026.pdf');
      expect(doc.storagePath, 'documentos/catalogo_2026.pdf');
      expect(doc.contentType, 'application/pdf');
      expect(doc.usuarioId, 'UID_123');
      expect(doc.negocioId, 'TIENDA_CENTRAL');

      final map = doc.toFirestore();
      expect(map['storagePath'], 'documentos/catalogo_2026.pdf');
      expect(map['usuarioId'], 'UID_123');
    });
  });

  group('COLECCIÓN 8: configuracion/asistente', () {
    test('Ruta fija configuracion/asistente y campos definidos', () {
      final now = DateTime(2026, 10, 25, 17, 0, 0);
      final raw = {
        'nombreNegocio': 'Mi Tienda Oficial',
        'moneda': 'ARS',
        'mensajeBienvenida': '¡Hola! ¿En qué te ayudo hoy?',
        'instruccionesAsistente': 'Ayudá al cliente con electrodomésticos.',
        'urlWeb': 'https://mitienda.com',
        'urlTelegram': 'https://t.me/mitienda_bot',
        'catalogoHabilitado': true,
        'comprasHabilitadas': false,
        'updatedAt': Timestamp.fromDate(now),
      };

      final config = Configuracion.fromFirestore(raw);

      expect(config.nombreNegocio, 'Mi Tienda Oficial');
      expect(config.moneda, 'ARS');
      expect(config.catalogoHabilitado, true);
      expect(config.comprasHabilitadas, false);
      expect(config.urlTelegram, 'https://t.me/mitienda_bot');

      final map = config.toFirestore();
      expect(map['moneda'], 'ARS');
      expect(map['comprasHabilitadas'], false);
    });
  });
}

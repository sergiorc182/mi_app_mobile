import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app_mobile/controlador/registro_controller.dart';

void main() {
  group('RegistroController.validarDatos', () {
    test('rechaza contraseñas cortas', () {
      final error = RegistroController.validarDatos(
        nombre: 'Ana',
        apellido: 'Pérez',
        dni: '12345678',
        email: 'ana@test.com',
        password: '12345',
        confirmarPassword: '12345',
      );

      expect(error, 'La contraseña debe tener al menos 6 caracteres.');
    });

    test('rechaza contraseñas que no coinciden', () {
      final error = RegistroController.validarDatos(
        nombre: 'Ana',
        apellido: 'Pérez',
        dni: '12345678',
        email: 'ana@test.com',
        password: '123456',
        confirmarPassword: '654321',
      );

      expect(error, 'Las contraseñas no coinciden.');
    });

    test('acepta datos válidos', () {
      final error = RegistroController.validarDatos(
        nombre: 'Ana',
        apellido: 'Pérez',
        dni: '12345678',
        email: 'ana@test.com',
        password: '123456',
        confirmarPassword: '123456',
      );

      expect(error, isNull);
    });
  });
}

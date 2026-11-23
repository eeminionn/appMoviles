import 'package:app_moviles/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Valida los campos vacíos antes de iniciar sesión', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresa tu correo electrónico'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Permite mostrar y volver a ocultar la contraseña', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    final campoPassword = find.byType(TextFormField).at(1);
    final entradaPassword = find.descendant(
      of: campoPassword,
      matching: find.byType(TextField),
    );

    await tester.enterText(campoPassword, 'claveDePrueba');
    expect(tester.widget<TextField>(entradaPassword).obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pump();

    expect(tester.widget<TextField>(entradaPassword).obscureText, isFalse);
    expect(
      tester.widget<TextField>(entradaPassword).controller!.text,
      'claveDePrueba',
    );

    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();

    expect(tester.widget<TextField>(entradaPassword).obscureText, isTrue);
    expect(
      tester.widget<TextField>(entradaPassword).controller!.text,
      'claveDePrueba',
    );
  });

  testWidgets('El registro exige nombre, apellido y una edad válida', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.tap(find.widgetWithText(TextButton, 'Crear cuenta'));
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(5));
    final crear = find.widgetWithText(FilledButton, 'Crear cuenta');
    await tester.ensureVisible(crear);
    await tester.tap(crear);
    await tester.pumpAndSettle();
    expect(find.text('Este campo es obligatorio'), findsNWidgets(2));
    expect(find.text('Ingresa una edad entre 1 y 120 años'), findsOneWidget);

    final edad = find.byType(TextFormField).at(2);
    for (final valor in ['0', '121']) {
      await tester.ensureVisible(edad);
      await tester.enterText(edad, valor);
      await tester.ensureVisible(crear);
      await tester.tap(crear);
      await tester.pumpAndSettle();
      expect(find.text('Ingresa una edad entre 1 y 120 años'), findsOneWidget);
    }
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

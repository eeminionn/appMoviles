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
}

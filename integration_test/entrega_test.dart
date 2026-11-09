import 'package:app_moviles/firebase_options.dart';
import 'package:app_moviles/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _hostLocal = '10.0.2.2';
const _plazo = Duration(seconds: 20);
const _servidor = GetOptions(source: Source.server);
const _capturas = bool.fromEnvironment('CAPTURAS');

void main() {
  // Nunca ejecutar esta prueba contra el proyecto remoto.
  if (!const bool.fromEnvironment('PRUEBA_LOCAL')) {
    throw StateError(
      'Ejecuta esta prueba con --dart-define=PRUEBA_LOCAL=true.',
    );
  }
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    throw StateError('Esta prueba usa la red local del emulador Android.');
  }

  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;
  FirebaseAuth? authLocal;
  late FirebaseFirestore firestore;

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final auth = FirebaseAuth.instance;
    await auth.useAuthEmulator(_hostLocal, 9099, automaticHostMapping: false);
    firestore = FirebaseFirestore.instance;
    firestore.useFirestoreEmulator(
      _hostLocal,
      8080,
      automaticHostMapping: false,
    );
    authLocal = auth;
    await auth.signOut();
  });

  tearDownAll(() async {
    final auth = authLocal;
    if (auth != null) await auth.signOut();
  });

  testWidgets('Entrega Android: direcciones, soporte y viaje de demostración', (
    tester,
  ) async {
    // Inyectar el teclado de pruebas sin cambiar los canales de Firebase.
    tester.testTextInput.register();
    addTearDown(tester.testTextInput.unregister);

    await tester.pumpWidget(const MainApp());
    if (_capturas) {
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
    }
    final correo =
        'pasajero-${DateTime.now().microsecondsSinceEpoch}@example.test';
    await _tocar(tester, find.widgetWithText(TextButton, 'Crear cuenta'));
    await _escribir(tester, find.byType(TextFormField).first, correo);
    await _escribir(
      tester,
      find.byType(TextFormField).last,
      'SoloPruebaLocal26',
    );
    await _tocar(tester, _boton('Crear cuenta'));
    await _esperar(tester, find.byTooltip('Abrir menú'));
    await _capturar(tester, 'inicio');
    final usuario = authLocal!.currentUser!;
    expect(usuario.email, correo);

    final datos = firestore.collection('usuarios').doc(usuario.uid);
    await _probarDirecciones(tester, datos);
    await _probarSoporte(tester, datos);
    await _probarViaje(tester, datos);

    await _tocar(tester, _destinoNavegacion('Perfil'));
    await _tocar(tester, find.text('Cerrar sesión'));
    await _esperar(tester, _boton('Iniciar sesión'));
    expect(authLocal!.currentUser, isNull);
  });
}

Future<void> _probarDirecciones(
  WidgetTester tester,
  DocumentReference<Map<String, dynamic>> usuario,
) async {
  const primeraDireccion = 'Calle Ficticia 10';
  const nuevaDireccion = 'Calle Ficticia 20';
  final domicilio = usuario.collection('direcciones').doc('domicilio');

  await _abrirMenu(tester, 'Mis direcciones');
  await _tocar(tester, find.text('Guardar como domicilio'));
  await _escribir(tester, find.byType(TextFormField), primeraDireccion);
  await _tocar(tester, _boton('Ver en el mapa'));
  await _capturar(tester, 'guardar-direccion');
  await _tocar(tester, _boton('Guardar'));
  await _esperar(tester, find.widgetWithText(ListTile, primeraDireccion));

  final creada = (await domicilio.get(_servidor).timeout(_plazo)).data()!;
  expect(creada['direccion'], primeraDireccion);
  expect(creada['nombre'], 'Domicilio');
  expect(creada['tipo'], 'Domicilio');
  expect(creada['creadoEn'], isA<Timestamp>());

  await _tocar(tester, find.text('Domicilio'));
  await _escribir(tester, find.byType(TextFormField), nuevaDireccion);
  await _tocar(tester, _boton('Ver en el mapa'));
  await _tocar(tester, _boton('Guardar'));
  await _esperar(tester, find.widgetWithText(ListTile, nuevaDireccion));

  final editada = (await domicilio.get(_servidor).timeout(_plazo)).data()!;
  expect(editada['direccion'], nuevaDireccion);
  expect(editada['creadoEn'], creada['creadoEn']);

  await _tocar(tester, find.text('Domicilio'));
  await _tocar(tester, find.text('Eliminar dirección'));
  await _tocar(tester, find.widgetWithText(TextButton, 'Eliminar'));
  await _esperar(tester, find.text('Guardar como domicilio'));
  expect((await domicilio.get(_servidor).timeout(_plazo)).exists, isFalse);
  await _volver(tester);
}

Future<void> _probarSoporte(
  WidgetTester tester,
  DocumentReference<Map<String, dynamic>> usuario,
) async {
  const mensaje = 'Quiero probar el historial de mensajes de demostración.';

  await _abrirMenu(tester, 'Soporte');
  await _tocar(tester, find.widgetWithText(ListTile, 'Ciudad'));
  await _tocar(tester, find.text('Mi perfil'));
  await _tocar(tester, find.text('Comunicación'));
  expect(find.textContaining('Abre Mensajes'), findsOneWidget);
  await _capturar(tester, 'comunicacion');
  await _tocar(tester, _boton('Registrar consulta de prueba'));
  await _escribir(tester, find.byType(TextFormField), mensaje);
  await _tocar(tester, _boton('Guardar consulta'));
  await _esperar(tester, find.text('Consulta de prueba guardada'));
  await _tocar(tester, find.text('Mis consultas'));
  await _esperar(tester, find.text(mensaje));

  final consulta =
      (await usuario.collection('consultas').get(_servidor).timeout(_plazo))
          .docs
          .single
          .data();
  expect(consulta['tema'], 'Comunicación');
  expect(consulta['mensaje'], mensaje);
  expect(consulta['creadoEn'], isA<Timestamp>());

  // Mis consultas → Comunicación → Ciudad → Temas → Inicio.
  for (var i = 0; i < 4; i++) {
    await _volver(tester);
  }
  await _esperar(tester, find.byTooltip('Abrir menú'));
}

Future<void> _probarViaje(
  WidgetTester tester,
  DocumentReference<Map<String, dynamic>> usuario,
) async {
  const destino = 'Destino de prueba';
  const mensaje = 'Estoy en el punto de encuentro de la demo.';

  await _tocar(tester, find.text('Buscar destino'));
  await _escribir(tester, find.byType(TextFormField).at(1), destino);
  await _tocar(tester, _boton('Continuar a tarifa'));
  await _tocar(tester, _boton('Continuar a método de pago'));
  await _tocar(tester, find.text('PagoRUT'));
  await _tocar(tester, _boton('Solicitar viaje'));
  await _tocar(tester, _boton('Ver ofertas'));
  await _capturar(tester, 'ofertas');
  await _tocar(tester, find.text('Aceptar oferta de Conductor A'));
  await _tocar(tester, _boton('Iniciar viaje demo'));
  await _tocar(tester, _boton('Completar viaje demo'));
  await _tocar(
    tester,
    find.byWidgetPredicate(
      (widget) =>
          widget is IconButton &&
          widget.tooltip == 'Calificar con 5 estrellas' &&
          widget.onPressed != null,
    ),
  );
  await _esperar(tester, find.text('Tu calificación: 5 de 5'));
  await usuario.firestore.waitForPendingWrites().timeout(_plazo);

  final viaje =
      (await usuario.collection('viajes').get(_servidor).timeout(_plazo))
          .docs
          .single;
  expect(viaje.data()['destino'], destino);
  expect(viaje.data()['pago'], 'PagoRUT');
  expect(viaje.data()['conductor'], 'Conductor A');
  expect(viaje.data()['estado'], 'completado');
  expect(viaje.data()['calificacion'], 5);
  expect(viaje.data()['creadoEn'], isA<Timestamp>());

  // El aviso de calificación se desvanece antes de abrir el chat.
  await tester.pump(const Duration(seconds: 5));
  await tester.pump(const Duration(milliseconds: 300));
  await _tocar(
    tester,
    find.ancestor(
      of: find.text('Chat de demo'),
      matching: find.byWidgetPredicate((widget) => widget is TextButton),
    ),
  );
  await _escribir(tester, find.byType(TextField), mensaje);
  await _tocar(tester, find.byTooltip('Guardar mensaje'));
  await _esperar(tester, find.widgetWithText(Card, mensaje));
  await usuario.firestore.waitForPendingWrites().timeout(_plazo);
  final chat =
      (await usuario.collection('mensajes').get(_servidor).timeout(_plazo))
          .docs
          .single
          .data();
  expect(chat['viajeId'], viaje.id);
  expect(chat['texto'], mensaje);

  await _volver(tester);
  await _volver(tester);
  await _tocar(tester, _destinoNavegacion('Actividad'));
  await _esperar(tester, find.text(destino));
  await _tocar(tester, find.widgetWithText(ChoiceChip, 'Completado'));
  await _escribir(tester, find.byType(TextField), 'SIN COINCIDENCIA');
  await _esperar(tester, find.text('No hay viajes para esta búsqueda.'));
  await _escribir(tester, find.byType(TextField), destino.toUpperCase());
  await _esperar(tester, find.widgetWithText(ListTile, destino));
}

Finder _boton(String texto) => find.ancestor(
  of: find.text(texto),
  matching: find.byWidgetPredicate(
    (widget) => widget is FilledButton && widget.onPressed != null,
  ),
);

Finder _destinoNavegacion(String texto) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(texto));

Future<void> _capturar(WidgetTester tester, String nombre) async {
  if (!_capturas) return;
  await tester.pump(const Duration(milliseconds: 350));
  await IntegrationTestWidgetsFlutterBinding.instance.takeScreenshot(nombre);
}

Future<void> _esperar(WidgetTester tester, Finder objetivo) async {
  final reloj = Stopwatch()..start();
  while (objetivo.evaluate().isEmpty && reloj.elapsed < _plazo) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(objetivo, findsWidgets);
}

Future<void> _tocar(WidgetTester tester, Finder objetivo) async {
  final reloj = Stopwatch()..start();
  final visible = objetivo.hitTestable();
  while (visible.evaluate().isEmpty && reloj.elapsed < _plazo) {
    if (objetivo.evaluate().isNotEmpty) {
      await Scrollable.ensureVisible(
        tester.element(objetivo.first),
        alignment: .45,
      );
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(visible, findsWidgets);
  await tester.tap(visible.first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
}

Future<void> _escribir(WidgetTester tester, Finder campo, String texto) async {
  await _esperar(tester, campo);
  await tester.ensureVisible(campo);
  await tester.pump();
  await tester.enterText(campo, texto);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
}

Future<void> _abrirMenu(WidgetTester tester, String opcion) async {
  await _tocar(tester, find.byTooltip('Abrir menú'));
  final fila = find.descendant(
    of: find.byType(Drawer),
    matching: find.text(opcion),
  );
  if (fila.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      fila,
      160,
      scrollable: find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(Scrollable),
      ),
    );
  }
  await _tocar(tester, fila);
}

Future<void> _volver(WidgetTester tester) =>
    _tocar(tester, find.byType(BackButton));

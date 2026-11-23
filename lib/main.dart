import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'auth/auth_gate.dart';
import 'configuracion_mapa.dart';
import 'firebase_options.dart';
import 'theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configurarGoogleMaps();
  runApp(MainApp(inicio: iniciarFirebase()));
}

Future<void> iniciarFirebase() async {
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    Future<void>.delayed(const Duration(milliseconds: 650)),
  ]);
}

class MainApp extends StatelessWidget {
  const MainApp({super.key, this.inicio});

  final Future<void>? inicio;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // El tema se comparte en todas las pantallas.
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        overscroll: false,
      ),
      title: 'InDrive',
      theme: AppTheme.tema,
      home: inicio == null ? const AuthGate() : InicioApp(inicio: inicio!),
    );
  }
}

class InicioApp extends StatefulWidget {
  const InicioApp({super.key, required this.inicio});

  final Future<void> inicio;

  @override
  State<InicioApp> createState() => _InicioAppState();
}

class _InicioAppState extends State<InicioApp> {
  late Future<void> inicio = widget.inicio;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: inicio,
      builder: (context, estado) {
        if (estado.connectionState == ConnectionState.done &&
            !estado.hasError) {
          return const AuthGate();
        }
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/imagenes/logo.png',
                  width: AppSpacing.spacing72,
                  height: AppSpacing.spacing72,
                  semanticLabel: 'InDrive',
                ),
                const SizedBox(height: AppSpacing.spacing24),
                if (estado.hasError) ...[
                  const Text('No pudimos abrir InDrive.'),
                  TextButton(
                    onPressed: () => setState(() => inicio = iniciarFirebase()),
                    child: const Text('Reintentar'),
                  ),
                ] else
                  const CircularProgressIndicator(
                    semanticsLabel: 'Cargando InDrive',
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

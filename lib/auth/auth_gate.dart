import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../personas.dart';
import '../views/home_screen.dart';
import '../views/perfil_persona_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Escuchar los cambios de autenticación
      stream: FirebaseAuth.instance.authStateChanges(),

      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text(
                'No se pudo comprobar la sesión. Vuelve a abrir la app.',
              ),
            ),
          );
        }

        // Esperar mientras Firebase comprueba la sesión
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Mostrar la pantalla principal si existe una sesión
        if (snapshot.hasData) {
          final usuario = snapshot.data!;
          return ValueListenableBuilder<bool>(
            valueListenable: registroEnCurso,
            builder: (context, guardando, _) => guardando
                ? const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  )
                : _PerfilGate(key: ValueKey(usuario.uid), usuario: usuario),
          );
        }

        // Mostrar el login si no existe una sesión
        return const LoginScreen();
      },
    );
  }
}

class _PerfilGate extends StatefulWidget {
  const _PerfilGate({super.key, required this.usuario});

  final User usuario;

  @override
  State<_PerfilGate> createState() => _PerfilGateState();
}

class _PerfilGateState extends State<_PerfilGate> {
  late Stream<DocumentSnapshot<Map<String, dynamic>>> cambios = persona(
    widget.usuario.uid,
  ).snapshots();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: cambios,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Mi cuenta')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No pudimos cargar tu perfil.'),
                  FilledButton(
                    onPressed: () => setState(() {
                      cambios = persona(widget.usuario.uid).snapshots();
                    }),
                    child: const Text('Reintentar'),
                  ),
                  TextButton(
                    onPressed: () async {
                      try {
                        await FirebaseAuth.instance.signOut();
                      } on FirebaseAuthException {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No pudimos cerrar la sesión.'),
                          ),
                        );
                      }
                    },
                    child: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final datos = snapshot.data!.data();
        if (!perfilCompleto(datos)) {
          return PerfilPersonaScreen(
            usuario: widget.usuario,
            datos: datos,
            completar: true,
          );
        }
        return HomeScreen(
          key: ValueKey(widget.usuario.uid),
          usuario: widget.usuario,
        );
      },
    );
  }
}

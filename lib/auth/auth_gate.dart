import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../views/home_screen.dart';
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
          return HomeScreen(key: ValueKey(usuario.uid), usuario: usuario);
        }

        // Mostrar el login si no existe una sesión
        return const LoginScreen();
      },
    );
  }
}

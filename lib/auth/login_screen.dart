import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../theme/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Inicializar Google una sola vez antes de iniciar sesión.
  static final Future<void> inicializacionGoogle = GoogleSignIn.instance
      .initialize();

  final correoController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool cargando = false;
  bool mostrarPassword = false;
  bool registro = false;

  void avisar(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  // Iniciar sesión con correo y contraseña
  Future<void> iniciarSesionCorreo() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => cargando = true);

    try {
      final correo = correoController.text.trim();
      final password = passwordController.text;
      if (registro) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: correo,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: correo,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      avisar(switch (e.code) {
        'email-already-in-use' => 'Ya hay una cuenta con ese correo.',
        'network-request-failed' => 'Revisa tu conexión e intenta de nuevo.',
        'invalid-email' => 'Escribe un correo válido.',
        'weak-password' => 'Usa al menos 6 caracteres.',
        'invalid-credential' ||
        'user-not-found' ||
        'wrong-password' => 'Revisa el correo y la contraseña.',
        _ => 'No se pudo acceder. Intenta nuevamente.',
      });
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  Future<void> recuperarPassword() async {
    final correo = correoController.text.trim();
    if (!correo.contains('@')) {
      avisar('Escribe tu correo para recuperar la contraseña.');
      return;
    }
    setState(() => cargando = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: correo);
      if (mounted) avisar('Si la cuenta existe, revisa tu correo.');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      avisar(
        e.code == 'user-not-found'
            ? 'Si la cuenta existe, revisa tu correo.'
            : 'No se pudo solicitar la recuperación.',
      );
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  // Iniciar sesión con Google
  Future<void> iniciarSesionGoogle() async {
    setState(() => cargando = true);

    try {
      await inicializacionGoogle;

      final googleUser = await GoogleSignIn.instance.authenticate();

      final googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (!mounted) return;

      if (e.code != GoogleSignInExceptionCode.canceled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al ingresar con Google: $e')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error de Firebase: ${e.code}')));
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo iniciar sesión con Google. Intenta nuevamente.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  @override
  void dispose() {
    correoController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('InDrive')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.spacing24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Image.asset(
                    'assets/imagenes/logo.png',
                    width: AppSpacing.spacing64,
                    height: AppSpacing.spacing64,
                    semanticLabel: 'InDrive',
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing16),
                Text(
                  registro ? 'Crea tu cuenta' : 'Bienvenido',
                  style: textos.headlineLarge,
                ),
                const SizedBox(height: AppSpacing.spacing8),
                const Text('Viajes de demostración'),

                const SizedBox(height: AppSpacing.spacing24),

                // Correo electrónico
                TextFormField(
                  controller: correoController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Ingresa tu correo electrónico';
                    }
                    if (!valor.contains('@')) return 'Escribe un correo válido';
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.spacing16),

                // Contraseña
                TextFormField(
                  controller: passwordController,
                  obscureText: !mostrarPassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          mostrarPassword = !mostrarPassword;
                        });
                      },
                      icon: Icon(
                        mostrarPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.isEmpty) {
                      return 'Ingresa tu contraseña';
                    }
                    if (registro && valor.length < 6) {
                      return 'Usa al menos 6 caracteres';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.spacing24),

                // Ingresar con correo
                FilledButton(
                  onPressed: cargando ? null : iniciarSesionCorreo,
                  child: Text(registro ? 'Crear cuenta' : 'Iniciar sesión'),
                ),

                const SizedBox(height: AppSpacing.spacing16),

                // Ingresar con Google
                OutlinedButton.icon(
                  onPressed: cargando ? null : iniciarSesionGoogle,
                  icon: const Icon(Icons.account_circle_outlined),
                  label: const Text('Continuar con Google'),
                ),

                TextButton(
                  onPressed: cargando
                      ? null
                      : () => setState(() => registro = !registro),
                  child: Text(registro ? 'Ya tengo cuenta' : 'Crear cuenta'),
                ),
                if (!registro)
                  TextButton(
                    onPressed: cargando ? null : recuperarPassword,
                    child: const Text('Olvidé mi contraseña'),
                  ),

                if (cargando) ...[
                  const SizedBox(height: AppSpacing.spacing16),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

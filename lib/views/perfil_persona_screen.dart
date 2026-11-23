import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../personas.dart';
import '../theme/theme.dart';

class PerfilPersonaScreen extends StatefulWidget {
  const PerfilPersonaScreen({
    super.key,
    required this.usuario,
    this.datos,
    this.completar = false,
  });

  final User usuario;
  final Map<String, dynamic>? datos;
  final bool completar;

  @override
  State<PerfilPersonaScreen> createState() => _PerfilPersonaScreenState();
}

class _PerfilPersonaScreenState extends State<PerfilPersonaScreen> {
  final formulario = GlobalKey<FormState>();
  late final inicial =
      widget.datos ??
      (borradorRegistro?['correo'] == widget.usuario.email
          ? borradorRegistro
          : null) ??
      <String, dynamic>{};
  late final nombre = TextEditingController(
    text: inicial['nombre'] as String? ?? widget.usuario.displayName ?? '',
  );
  late final apellido = TextEditingController(
    text: inicial['apellido'] as String? ?? '',
  );
  late final edad = TextEditingController(
    text: inicial['edad']?.toString() ?? '',
  );
  bool guardando = false;

  @override
  void dispose() {
    nombre.dispose();
    apellido.dispose();
    edad.dispose();
    super.dispose();
  }

  Future<void> guardar() async {
    if (guardando || formulario.currentState?.validate() != true) return;
    FocusScope.of(context).unfocus();
    setState(() => guardando = true);
    try {
      await guardarPersona(
        widget.usuario,
        nombre: nombre.text,
        apellido: apellido.text,
        edad: int.parse(edad.text),
      );
      borradorRegistro = null;
      if (!mounted) return;
      if (!widget.completar) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos guardar el perfil. Inténtalo de nuevo.'),
        ),
      );
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  Future<void> salir() async {
    try {
      await FirebaseAuth.instance.signOut();
      borradorRegistro = null;
    } on FirebaseAuthException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos cerrar la sesión.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !guardando,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.completar ? 'Completa tu perfil' : 'Editar perfil',
          ),
        ),
        body: Form(
          key: formulario,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.spacing20),
            children: [
              if (widget.completar) ...[
                const Text('Guarda tus datos para personalizar tu cuenta.'),
                const SizedBox(height: AppSpacing.spacing16),
              ],
              TextFormField(
                controller: nombre,
                enabled: !guardando,
                maxLength: 60,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.givenName],
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: validarNombrePersona,
              ),
              const SizedBox(height: AppSpacing.spacing8),
              TextFormField(
                controller: apellido,
                enabled: !guardando,
                maxLength: 60,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.familyName],
                decoration: const InputDecoration(labelText: 'Apellido'),
                validator: validarNombrePersona,
              ),
              const SizedBox(height: AppSpacing.spacing8),
              TextFormField(
                controller: edad,
                enabled: !guardando,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 3,
                decoration: const InputDecoration(labelText: 'Edad'),
                validator: validarEdadPersona,
              ),
              const SizedBox(height: AppSpacing.spacing8),
              TextFormField(
                initialValue: widget.usuario.email ?? '',
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                ),
              ),
              const SizedBox(height: AppSpacing.spacing24),
              FilledButton(
                onPressed: guardando ? null : guardar,
                child: Text(
                  widget.completar ? 'Guardar y continuar' : 'Guardar cambios',
                ),
              ),
              if (guardando) const LinearProgressIndicator(),
              if (widget.completar)
                TextButton(
                  onPressed: guardando ? null : salir,
                  child: const Text('Cerrar sesión'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// Mantener el registro en espera hasta guardar también el perfil.
final registroEnCurso = ValueNotifier(false);
Map<String, dynamic>? borradorRegistro;

DocumentReference<Map<String, dynamic>> persona(String uid) =>
    FirebaseFirestore.instance.collection('personas').doc(uid);

String? validarNombrePersona(String? valor) {
  final texto = (valor ?? '').trim();
  if (texto.isEmpty) return 'Este campo es obligatorio';
  if (texto.length > 60) return 'Usa hasta 60 caracteres';
  return null;
}

String? validarEdadPersona(String? valor) {
  final edad = int.tryParse((valor ?? '').trim());
  return edad == null || edad < 1 || edad > 120
      ? 'Ingresa una edad entre 1 y 120 años'
      : null;
}

bool perfilCompleto(Map<String, dynamic>? datos) {
  if (datos == null) return false;
  final nombre = datos['nombre'];
  final apellido = datos['apellido'];
  final edad = datos['edad'];
  return nombre is String &&
      validarNombrePersona(nombre) == null &&
      apellido is String &&
      validarNombrePersona(apellido) == null &&
      edad is int &&
      edad >= 1 &&
      edad <= 120 &&
      datos['correo'] is String;
}

Future<void> guardarPersona(
  User usuario, {
  required String nombre,
  required String apellido,
  required int edad,
}) async {
  final referencia = persona(usuario.uid);
  await referencia.firestore.runTransaction((transaccion) async {
    final actual = await transaccion.get(referencia);
    transaccion.set(referencia, {
      'nombre': nombre.trim(),
      'apellido': apellido.trim(),
      'edad': edad,
      'correo': usuario.email,
      'creadoEn': actual.data()?['creadoEn'] ?? FieldValue.serverTimestamp(),
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
  });
}

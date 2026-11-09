import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../busqueda_direcciones.dart';
import '../busquedas_recientes.dart';
import '../theme/theme.dart';

Future<void> registrarBusqueda(
  BuildContext context,
  String uid,
  String consulta, [
  DireccionEncontrada? resultado,
]) async {
  final mensajes = ScaffoldMessenger.of(context);
  try {
    await guardarBusqueda(uid, consulta, resultado);
  } on FirebaseException {
    if (!mensajes.mounted) return;
    mensajes.showSnackBar(
      const SnackBar(content: Text('No pudimos guardar la búsqueda reciente.')),
    );
  }
}

Future<DireccionEncontrada?> mostrarResultadosDireccion(
  BuildContext context,
  String uid,
  String texto,
) async {
  final consulta = texto.trim();
  if (consulta.length < 2 || consulta.length > 120) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ingresa una dirección para buscar.')),
    );
    return null;
  }

  FocusScope.of(context).unfocus();
  return showModalBottomSheet<DireccionEncontrada>(
    context: context,
    showDragHandle: true,
    builder: (_) => _ResultadosDireccion(uid: uid, consulta: consulta),
  );
}

class _ResultadosDireccion extends StatefulWidget {
  const _ResultadosDireccion({required this.uid, required this.consulta});

  final String uid;
  final String consulta;

  @override
  State<_ResultadosDireccion> createState() => _ResultadosDireccionState();
}

class _ResultadosDireccionState extends State<_ResultadosDireccion> {
  late Future<List<DireccionEncontrada>> resultados = buscar();

  Future<List<DireccionEncontrada>> buscar() async {
    final opciones = await buscarDirecciones(widget.consulta);
    if (opciones.isNotEmpty && mounted) {
      unawaited(registrarBusqueda(context, widget.uid, widget.consulta));
    }
    return opciones;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<DireccionEncontrada>>(
        future: resultados,
        builder: (context, snapshot) {
          final opciones = snapshot.data ?? [];
          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.spacing16,
              0,
              AppSpacing.spacing16,
              AppSpacing.spacing16,
            ),
            children: [
              Text(
                'Resultados de búsqueda',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(widget.consulta),
              const SizedBox(height: AppSpacing.spacing12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator()
              else if (snapshot.hasError) ...[
                const Text('No pudimos consultar direcciones.'),
                TextButton(
                  onPressed: () => setState(() => resultados = buscar()),
                  child: const Text('Reintentar'),
                ),
              ] else if (opciones.isEmpty)
                const Text(
                  'No encontramos resultados. Prueba con calle, número y comuna.',
                )
              else
                for (final opcion in opciones)
                  ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(opcion.direccion),
                    onTap: () {
                      unawaited(
                        registrarBusqueda(
                          context,
                          widget.uid,
                          widget.consulta,
                          opcion,
                        ),
                      );
                      Navigator.of(context).pop(opcion);
                    },
                  ),
            ],
          );
        },
      ),
    );
  }
}

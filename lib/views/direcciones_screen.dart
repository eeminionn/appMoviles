import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../busquedas_recientes.dart';
import '../datos.dart';
import '../theme/theme.dart';
import 'buscador_direcciones.dart';
import 'componentes.dart';

class DireccionesScreen extends StatefulWidget {
  const DireccionesScreen({super.key, required this.uid});

  final String uid;

  @override
  State<DireccionesScreen> createState() => _DireccionesScreenState();
}

class _DireccionesScreenState extends State<DireccionesScreen> {
  late final direcciones = FirebaseFirestore.instance
      .collection('usuarios')
      .doc(widget.uid)
      .collection('direcciones');
  late final cambios = direcciones.orderBy('creadoEn').snapshots();

  Future<void> abrirFormulario(
    String tipo, [
    QueryDocumentSnapshot<Map<String, dynamic>>? documento,
  ]) async {
    final resultado = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => _FormularioDireccion(
          uid: widget.uid,
          tipo: tipo,
          direcciones: direcciones,
          documento: documento,
        ),
      ),
    );

    if (!mounted || resultado == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(resultado)));
  }

  Widget filaDireccion(
    String tipo,
    IconData icono, [
    QueryDocumentSnapshot<Map<String, dynamic>>? documento,
  ]) {
    final datos = documento?.data();
    final nombre =
        datos?['nombre'] as String? ??
        (tipo == 'Otro' ? tipo : 'Guardar como ${tipo.toLowerCase()}');
    final direccion = datos?['direccion'] as String?;

    return ListTile(
      leading: Icon(icono, color: AppColors.secundario),
      title: Text(nombre),
      subtitle: direccion == null ? null : Text(direccion),
      trailing: tipo == 'Otro' && documento == null
          ? null
          : Icon(
              documento == null ? Icons.chevron_right : Icons.edit_outlined,
              color: AppColors.secundario,
            ),
      onTap: () => abrirFormulario(tipo, documento),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis direcciones')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: cambios,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('No pudimos cargar tus direcciones.'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          QueryDocumentSnapshot<Map<String, dynamic>>? domicilio;
          QueryDocumentSnapshot<Map<String, dynamic>>? trabajo;
          final otras = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          for (final documento in snapshot.data!.docs) {
            if (documento.id == 'domicilio') {
              domicilio = documento;
            } else if (documento.id == 'trabajo') {
              trabajo = documento;
            } else {
              otras.add(documento);
            }
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.spacing20,
              AppSpacing.spacing32,
              AppSpacing.spacing20,
              AppSpacing.spacing24,
            ),
            children: [
              filaDireccion('Domicilio', Icons.home_outlined, domicilio),
              filaDireccion('Trabajo', Icons.folder_outlined, trabajo),
              for (final otra in otras)
                filaDireccion('Otro', Icons.place_outlined, otra),
              filaDireccion('Otro', Icons.add),
            ],
          );
        },
      ),
    );
  }
}

class _FormularioDireccion extends StatefulWidget {
  const _FormularioDireccion({
    required this.uid,
    required this.tipo,
    required this.direcciones,
    this.documento,
  });

  final String uid;
  final String tipo;
  final CollectionReference<Map<String, dynamic>> direcciones;
  final QueryDocumentSnapshot<Map<String, dynamic>>? documento;

  @override
  State<_FormularioDireccion> createState() => _FormularioDireccionState();
}

class _FormularioDireccionState extends State<_FormularioDireccion> {
  final formKey = GlobalKey<FormState>();
  late final nombreController = TextEditingController(
    text: widget.documento?.data()['nombre'] as String? ?? '',
  );
  late final direccionController = TextEditingController(
    text: widget.documento?.data()['direccion'] as String? ?? '',
  );
  late LatLng? punto = leerPunto(widget.documento?.data()['punto']);
  bool confirmando = false;
  bool guardando = false;

  @override
  void dispose() {
    nombreController.dispose();
    direccionController.dispose();
    super.dispose();
  }

  void confirmarDireccion() {
    if (!formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => confirmando = true);
  }

  Future<void> buscarDireccion() async {
    final resultado = await mostrarResultadosDireccion(
      context,
      widget.uid,
      direccionController.text,
    );
    if (!mounted || resultado == null) return;
    setState(() {
      direccionController.text = resultado.direccion;
      punto = resultado.punto;
    });
  }

  Future<void> guardarDireccion() async {
    setState(() => guardando = true);
    final datos = <String, dynamic>{
      'nombre': widget.tipo == 'Otro'
          ? nombreController.text.trim()
          : widget.tipo,
      'direccion': direccionController.text.trim(),
      'tipo': widget.tipo,
      if (punto != null)
        'punto': guardarPunto(punto!)
      else if (widget.documento != null)
        'punto': FieldValue.delete(),
    };

    try {
      if (widget.documento != null) {
        await widget.documento!.reference.update(datos);
      } else {
        final nueva = {...datos, 'creadoEn': FieldValue.serverTimestamp()};
        if (widget.tipo == 'Otro') {
          await widget.direcciones.add(nueva);
        } else {
          await widget.direcciones.doc(widget.tipo.toLowerCase()).set(nueva);
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop('Dirección guardada');
    } on FirebaseException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos guardar la dirección.')),
      );
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  Future<void> eliminarDireccion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar dirección'),
        content: const Text(
          '¿Quieres quitar esta dirección de tus lugares guardados?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (!mounted || confirmar != true) return;

    setState(() => guardando = true);
    try {
      await widget.documento!.reference.delete();
      if (!mounted) return;
      Navigator.of(context).pop('Dirección eliminada');
    } on FirebaseException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos eliminar la dirección.')),
      );
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final coincidencias = lugares.entries.where(
      (lugar) =>
          coincide('${lugar.key} ${lugar.value}', direccionController.text),
    );

    return PopScope<String>(
      canPop: !guardando && !confirmando,
      onPopInvokedWithResult: (salio, _) {
        if (!salio && confirmando && !guardando) {
          setState(() => confirmando = false);
        }
      },
      child: confirmando
          ? Scaffold(
              body: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Stack(
                    children: [
                      MapaViaje(
                        altura: AppSize.mapaTarifa + AppSpacing.spacing12,
                        destino: direccionController.text.trim(),
                        puntoDestino: punto,
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.spacing12),
                          child: IconButton.filledTonal(
                            onPressed: guardando
                                ? null
                                : () => setState(() => confirmando = false),
                            icon: const Icon(Icons.arrow_back),
                            tooltip: 'Volver',
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: AppSize.mapaTarifa),
                        child: PanelMapa(
                          mostrarGuia: false,
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.spacing20),
                            child: Column(
                              children: [
                                Text(
                                  widget.tipo == 'Otro'
                                      ? 'Guardar dirección'
                                      : 'Guardar como ${widget.tipo.toLowerCase()}',
                                  style: textos.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.spacing16),
                                TextFormField(
                                  controller: direccionController,
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Dirección',
                                    prefixIcon: Icon(Icons.place_outlined),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.spacing24),
                                FilledButton(
                                  onPressed: guardando
                                      ? null
                                      : guardarDireccion,
                                  child: const Text('Guardar'),
                                ),
                                if (guardando) const LinearProgressIndicator(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : Scaffold(
              appBar: AppBar(
                title: Text(
                  widget.documento == null
                      ? 'Ingresar dirección'
                      : 'Editar dirección',
                ),
              ),
              body: Form(
                key: formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.spacing20),
                  children: [
                    if (widget.tipo == 'Otro') ...[
                      TextFormField(
                        controller: nombreController,
                        enabled: !guardando,
                        maxLength: 40,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del lugar',
                        ),
                        validator: (valor) => (valor ?? '').trim().length < 2
                            ? 'Ingresa un nombre para el lugar'
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.spacing8),
                    ],
                    TextFormField(
                      controller: direccionController,
                      enabled: !guardando,
                      maxLength: 120,
                      decoration: const InputDecoration(
                        labelText: 'Buscar dirección',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (_) => setState(() => punto = null),
                      validator: (valor) => (valor ?? '').trim().length < 2
                          ? 'Ingresa una dirección'
                          : null,
                      textInputAction: TextInputAction.search,
                      onFieldSubmitted: (_) => buscarDireccion(),
                    ),
                    OutlinedButton.icon(
                      onPressed: guardando ? null : buscarDireccion,
                      icon: const Icon(Icons.search),
                      label: const Text('Buscar dirección'),
                    ),
                    for (final lugar in coincidencias)
                      ListTile(
                        leading: const Icon(Icons.place_outlined),
                        title: Text(lugar.key),
                        subtitle: Text(lugar.value),
                        onTap: guardando
                            ? null
                            : () {
                                direccionController.text =
                                    '${lugar.key}, ${lugar.value}';
                                punto = null;
                                if (nombreController.text.trim().isEmpty) {
                                  nombreController.text = lugar.key;
                                }
                                confirmarDireccion();
                              },
                      ),
                    const SizedBox(height: AppSpacing.spacing16),
                    FilledButton(
                      onPressed: guardando ? null : confirmarDireccion,
                      child: const Text('Ver en el mapa'),
                    ),
                    if (widget.documento != null)
                      TextButton(
                        onPressed: guardando ? null : eliminarDireccion,
                        child: const Text('Eliminar dirección'),
                      ),
                    if (guardando) const LinearProgressIndicator(),
                  ],
                ),
              ),
            ),
    );
  }
}

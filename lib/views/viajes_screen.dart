import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../datos.dart';
import '../theme/theme.dart';
import 'componentes.dart';
import 'mensajes_screen.dart';
import 'seguridad_screen.dart';

const _tarifaMinima = 1000;
const _tarifaMaxima = 200000;
const _tarifaRecomendada = 2000;
const _tarifaComfort = 4700;
const _esperaOferta = Duration(seconds: 3);
const _conductoresDemo = {
  'Conductor A': (minutos: 7, vehiculo: 'Bronco', patente: 'DEMO-A'),
  'Conductor B': (minutos: 9, vehiculo: 'Bronco', patente: 'DEMO-B'),
};

enum _DecisionOferta { conductorA, conductorB, cancelar }

String _claveLugar(String texto) {
  String limpiar(String valor) =>
      normalizar(valor).replaceAll(RegExp(r'[^a-z0-9ñ]+'), ' ').trim();

  final clave = limpiar(texto);
  for (final lugar in lugares.entries) {
    final nombre = limpiar(lugar.key);
    final direccion = limpiar(lugar.value);
    if (clave == nombre ||
        clave == direccion ||
        clave == '$nombre $direccion') {
      return nombre;
    }
    if (clave.startsWith('$nombre ') &&
        direccion.startsWith('${clave.substring(nombre.length + 1)} ')) {
      return nombre;
    }
  }
  return clave;
}

Widget _panelViaje(Widget child, {bool mostrarGuia = true}) => PanelMapa(
  mostrarGuia: mostrarGuia,
  child: Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.spacing16,
      AppSpacing.spacing8,
      AppSpacing.spacing16,
      AppSpacing.spacing24,
    ),
    child: child,
  ),
);

CollectionReference<Map<String, dynamic>> _viajes(String uid) =>
    FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('viajes');

const _estados = <String, String>{
  'buscando': 'Buscando',
  'confirmado': 'Confirmado',
  'en curso': 'En curso',
  'completado': 'Completado',
  'cancelado': 'Cancelado',
};

bool _cerrado(String estado) => estado == 'completado' || estado == 'cancelado';

IconData _iconoServicio(String servicio) => switch (servicio) {
  'Moto' => Icons.two_wheeler_outlined,
  'Interurbano' => Icons.directions_bus_outlined,
  'Entregas' => Icons.inventory_2_outlined,
  'Fletes' => Icons.local_shipping_outlined,
  _ => Icons.directions_car_outlined,
};

String _fecha(dynamic valor) {
  if (valor is! Timestamp) return 'Fecha pendiente';
  final fecha = valor.toDate();
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  return '$dia/$mes/${fecha.year}';
}

void _aviso(BuildContext context, String mensaje) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
}

Future<bool> _confirmar(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  required String accion,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(titulo),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(accion),
            ),
          ],
        ),
      ) ??
      false;
}

Future<int?> _pedirTarifa(BuildContext context, int actual) {
  final formulario = GlobalKey<FormState>();
  var monto = actual;
  return showModalBottomSheet<int>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.spacing24,
        AppSpacing.spacing8,
        AppSpacing.spacing24,
        MediaQuery.viewInsetsOf(sheetContext).bottom + AppSpacing.spacing24,
      ),
      child: Form(
        key: formulario,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Otro monto',
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.spacing16),
            TextFormField(
              initialValue: actual.toString(),
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Tarifa en pesos chilenos',
                prefixText: r'$ ',
              ),
              validator: (valor) {
                final numero = int.tryParse(valor ?? '');
                if (numero == null ||
                    numero < _tarifaMinima ||
                    numero > _tarifaMaxima) {
                  return 'Ingresa entre ${clp(_tarifaMinima)} y ${clp(_tarifaMaxima)}.';
                }
                return null;
              },
              onSaved: (valor) => monto = int.parse(valor!),
            ),
            const SizedBox(height: AppSpacing.spacing16),
            FilledButton(
              onPressed: () {
                final estado = formulario.currentState!;
                if (!estado.validate()) return;
                estado.save();
                Navigator.pop(sheetContext, monto);
              },
              child: const Text('Usar monto'),
            ),
          ],
        ),
      ),
    ),
  );
}

class NuevoViajeScreen extends StatefulWidget {
  const NuevoViajeScreen({
    super.key,
    required this.uid,
    this.servicioInicial = 'Ciudad',
    this.destinoInicial = '',
  });

  final String uid;
  final String servicioInicial;
  final String destinoInicial;

  @override
  State<NuevoViajeScreen> createState() => _NuevoViajeScreenState();
}

class _NuevoViajeScreenState extends State<NuevoViajeScreen> {
  final formKey = GlobalKey<FormState>();
  final origen = TextEditingController(
    text: 'Universidad del Desarrollo, Av. Plaza',
  );
  late final destino = TextEditingController(text: widget.destinoInicial);
  late final direcciones = FirebaseFirestore.instance
      .collection('usuarios')
      .doc(widget.uid)
      .collection('direcciones')
      .snapshots();

  late String servicio = servicios.contains(widget.servicioInicial)
      ? widget.servicioInicial
      : 'Ciudad';
  String? pago;
  int tarifa = _tarifaRecomendada;
  int paso = 0;
  bool buscaOrigen = false;
  bool filtroSugerencias = false;
  bool guardando = false;

  @override
  void dispose() {
    origen.dispose();
    destino.dispose();
    super.dispose();
  }

  void continuar() {
    if (paso == 0 && formKey.currentState?.validate() != true) return;
    FocusScope.of(context).unfocus();
    setState(() => paso++);
  }

  Future<void> otroMonto() async {
    final monto = await _pedirTarifa(context, tarifa);
    if (monto != null && mounted) setState(() => tarifa = monto);
  }

  Future<void> solicitar() async {
    if (pago == null || guardando) return;
    setState(() => guardando = true);
    try {
      final doc = await _viajes(widget.uid).add({
        'origen': origen.text.trim(),
        'destino': destino.text.trim(),
        'servicio': servicio,
        'pago': pago!,
        'tarifa': tarifa,
        'autoAceptar': false,
        'estado': 'buscando',
        'conductor': '',
        'calificacion': 0,
        'creadoEn': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => DetalleViajeScreen(uid: widget.uid, id: doc.id),
        ),
      );
    } catch (_) {
      if (mounted) _aviso(context, 'No se pudo guardar la solicitud.');
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  String? validarDireccion(String? valor) {
    final largo = (valor ?? '').trim().length;
    return largo < 2 || largo > 120
        ? 'Ingresa una dirección entre 2 y 120 caracteres.'
        : null;
  }

  String? validarDestino(String? valor) {
    final error = validarDireccion(valor);
    if (error != null) return error;
    if (_claveLugar(origen.text) == _claveLugar(valor!)) {
      return 'El destino debe ser distinto del origen.';
    }
    return null;
  }

  Widget selectorServicio() {
    return Wrap(
      spacing: AppSpacing.spacing8,
      runSpacing: AppSpacing.spacing4,
      children: [
        for (final opcion in servicios)
          ChoiceChip(
            avatar: Icon(_iconoServicio(opcion), size: AppSpacing.spacing16),
            label: Text(opcion),
            selected: servicio == opcion,
            onSelected: (_) => setState(() => servicio = opcion),
          ),
      ],
    );
  }

  Widget sugerencias() {
    final campo = buscaOrigen ? origen : destino;
    final consulta = filtroSugerencias ? campo.text.trim() : '';
    final texto = Theme.of(context).textTheme;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: direcciones,
      builder: (context, snapshot) {
        final guardadas = <MapEntry<String, String>>[
          for (final doc in snapshot.data?.docs ?? [])
            MapEntry(
              doc.data()['nombre'] as String? ?? 'Dirección guardada',
              doc.data()['direccion'] as String? ?? '',
            ),
        ];
        final opciones = <(String, String, bool)>[
          for (final item in guardadas)
            if (item.value.isNotEmpty &&
                coincide('${item.key} ${item.value}', consulta))
              (item.key, item.value, true),
          for (final item in lugares.entries)
            if (coincide('${item.key} ${item.value}', consulta))
              (item.key, item.value, false),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              buscaOrigen ? 'Sugerencias de origen' : 'Sugerencias de destino',
              style: texto.titleSmall,
            ),
            if (snapshot.hasError)
              const Text('No se pudieron cargar tus direcciones guardadas.')
            else if (snapshot.connectionState == ConnectionState.waiting)
              const LinearProgressIndicator(),
            if (opciones.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing8),
                child: Text('Puedes usar la dirección que escribiste.'),
              ),
            for (final (nombre, direccion, guardada) in opciones.take(4))
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(
                  guardada ? Icons.bookmark_border : Icons.location_on_outlined,
                  color: AppColors.verdeOscuro,
                ),
                title: Text(nombre),
                subtitle: nombre == direccion ? null : Text(direccion),
                onTap: () {
                  final etiqueta = direccion.isEmpty || nombre == direccion
                      ? nombre
                      : '$nombre, $direccion';
                  setState(() {
                    campo.text = etiqueta.length <= 120 ? etiqueta : direccion;
                  });
                  FocusScope.of(context).unfocus();
                },
              ),
          ],
        );
      },
    );
  }

  Widget formularioRuta() {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          selectorServicio(),
          const SizedBox(height: AppSpacing.spacing16),
          TextFormField(
            controller: origen,
            textInputAction: TextInputAction.next,
            maxLength: 120,
            validator: validarDireccion,
            onTap: () => setState(() {
              if (!buscaOrigen) filtroSugerencias = false;
              buscaOrigen = true;
            }),
            onChanged: (_) => setState(() {
              buscaOrigen = true;
              filtroSugerencias = true;
            }),
            decoration: const InputDecoration(
              labelText: 'Origen',
              prefixIcon: Icon(Icons.trip_origin),
              counterText: '',
            ),
          ),
          const SizedBox(height: AppSpacing.spacing8),
          TextFormField(
            controller: destino,
            maxLength: 120,
            validator: validarDestino,
            onTap: () => setState(() {
              if (buscaOrigen) filtroSugerencias = false;
              buscaOrigen = false;
            }),
            onChanged: (_) => setState(() {
              buscaOrigen = false;
              filtroSugerencias = true;
            }),
            decoration: const InputDecoration(
              labelText: 'Buscar destino',
              prefixIcon: Icon(Icons.search),
              counterText: '',
            ),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          sugerencias(),
          const SizedBox(height: AppSpacing.spacing16),
          FilledButton(
            onPressed: continuar,
            child: const Text('Continuar a tarifa'),
          ),
        ],
      ),
    );
  }

  Widget opcionTarifa(String nombre, int monto) {
    return Card(
      color: tarifa == monto ? AppColors.seleccion : null,
      child: ListTile(
        leading: Icon(_iconoServicio(servicio), color: AppColors.verdeOscuro),
        title: Text(clp(monto)),
        subtitle: Text(nombre),
        trailing: Icon(
          tarifa == monto
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
        ),
        onTap: () => setState(() => tarifa = monto),
      ),
    );
  }

  Widget formularioTarifa() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        opcionTarifa('Tarifa recomendada', _tarifaRecomendada),
        opcionTarifa('Comfort', _tarifaComfort),
        OutlinedButton.icon(
          onPressed: otroMonto,
          icon: const Icon(Icons.edit_outlined),
          label: Text('Otro monto · ${clp(tarifa)}'),
        ),
        const SizedBox(height: AppSpacing.spacing16),
        FilledButton(
          onPressed: continuar,
          child: const Text('Continuar a método de pago'),
        ),
      ],
    );
  }

  Widget formularioPago() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final opcion in pagos)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              opcion == 'Efectivo'
                  ? Icons.payments_outlined
                  : Icons.account_balance_wallet_outlined,
              color: AppColors.verdeOscuro,
            ),
            title: Text(opcion),
            trailing: Icon(
              pago == opcion ? Icons.check_box : Icons.check_box_outline_blank,
              color: AppColors.verdeOscuro,
            ),
            selected: pago == opcion,
            onTap: guardando ? null : () => setState(() => pago = opcion),
          ),
        const SizedBox(height: AppSpacing.spacing16),
        const Text('Viaje de demostración. No se realizará ningún cobro.'),
        const SizedBox(height: AppSpacing.spacing8),
        FilledButton(
          onPressed: pago == null || guardando ? null : solicitar,
          child: Text(guardando ? 'Guardando…' : 'Solicitar viaje'),
        ),
        if (guardando) const LinearProgressIndicator(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: paso == 0 && !guardando,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && paso > 0 && !guardando) setState(() => paso--);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(switch (paso) {
            0 => 'Pedir un viaje',
            1 => 'Elige una tarifa',
            _ => 'Método de pago',
          }),
        ),
        body: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            if (paso < 2)
              MapaViaje(
                altura: paso == 0 ? AppSize.mapaInicio : AppSize.mapaTarifa,
                conRuta: paso == 1,
              ),
            _panelViaje(mostrarGuia: paso < 2, switch (paso) {
              0 => formularioRuta(),
              1 => formularioTarifa(),
              _ => formularioPago(),
            }),
          ],
        ),
      ),
    );
  }
}

class ActividadScreen extends StatefulWidget {
  const ActividadScreen({super.key, required this.uid});

  final String uid;

  @override
  State<ActividadScreen> createState() => _ActividadScreenState();
}

class _ActividadScreenState extends State<ActividadScreen> {
  late final viajes = _viajes(
    widget.uid,
  ).orderBy('creadoEn', descending: true).snapshots();

  String busqueda = '';
  String filtro = '';
  String? eliminando;

  Future<void> borrar(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    if (eliminando != null) return;
    final confirmado = await _confirmar(
      context,
      titulo: 'Eliminar viaje',
      mensaje: '¿Quieres quitar este viaje cerrado de tu actividad?',
      accion: 'Eliminar',
    );
    if (!confirmado || !mounted || eliminando != null) return;
    setState(() => eliminando = doc.id);
    try {
      await doc.reference.delete();
      if (mounted) _aviso(context, 'Viaje eliminado.');
    } catch (_) {
      if (mounted) _aviso(context, 'No se pudo eliminar el viaje.');
    } finally {
      if (mounted) setState(() => eliminando = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.spacing16,
              AppSpacing.spacing16,
              AppSpacing.spacing16,
              AppSpacing.spacing8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Actividad',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.spacing12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Buscar viajes',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (valor) => setState(() => busqueda = valor.trim()),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing16,
            ),
            child: Row(
              children: [
                for (final item in {'': 'Todos', ..._estados}.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.spacing8),
                    child: ChoiceChip(
                      label: Text(item.value),
                      selected: filtro == item.key,
                      onSelected: (_) => setState(() => filtro = item.key),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: viajes,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('No se pudo cargar tu actividad.'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final documentos = snapshot.data!.docs;
                if (documentos.isEmpty) {
                  return const Center(child: Text('Todavía no tienes viajes.'));
                }
                final visibles = documentos.where((doc) {
                  final d = doc.data();
                  return (filtro.isEmpty || d['estado'] == filtro) &&
                      coincide(
                        '${d['origen']} ${d['destino']} ${d['servicio']} '
                        '${_estados[d['estado']]} ${d['pago']} ${d['conductor']}',
                        busqueda,
                      );
                }).toList();
                if (visibles.isEmpty) {
                  return const Center(
                    child: Text('No hay viajes para esta búsqueda.'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.spacing16),
                  itemCount: visibles.length,
                  itemBuilder: (context, index) {
                    final doc = visibles[index];
                    final d = doc.data();
                    final estado = d['estado'] as String? ?? '';
                    final servicio = d['servicio'] as String? ?? 'Ciudad';
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          _iconoServicio(servicio),
                          color: AppColors.verdeOscuro,
                        ),
                        title: Text(d['destino'] as String? ?? 'Viaje'),
                        subtitle: Text(
                          '${_estados[estado] ?? estado} · ${clp(d['tarifa'] as int? ?? 0)}\n'
                          '$servicio · ${_fecha(d['creadoEn'])}',
                        ),
                        isThreeLine: true,
                        trailing: _cerrado(estado)
                            ? IconButton(
                                tooltip: 'Eliminar viaje',
                                onPressed: eliminando == null
                                    ? () => borrar(doc)
                                    : null,
                                icon: const Icon(Icons.delete_outline),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                DetalleViajeScreen(uid: widget.uid, id: doc.id),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DetalleViajeScreen extends StatefulWidget {
  const DetalleViajeScreen({super.key, required this.uid, required this.id});

  final String uid;
  final String id;

  @override
  State<DetalleViajeScreen> createState() => _DetalleViajeScreenState();
}

class _DetalleViajeScreenState extends State<DetalleViajeScreen> {
  late final documento = _viajes(widget.uid).doc(widget.id);
  late final viaje = documento.snapshots();
  Timer? esperaAuto;
  int? tarifaAuto;
  bool operando = false;
  bool dialogoAbierto = false;

  @override
  void dispose() {
    esperaAuto?.cancel();
    super.dispose();
  }

  Future<void> actualizar(Map<String, dynamic> datos, {String? aviso}) async {
    if (operando) return;
    setState(() => operando = true);
    try {
      await documento.update(datos);
      if (mounted && aviso != null) _aviso(context, aviso);
    } catch (_) {
      if (mounted) _aviso(context, 'No se pudo actualizar el viaje.');
    } finally {
      if (mounted) setState(() => operando = false);
    }
  }

  void pausarAuto() {
    dialogoAbierto = true;
    esperaAuto?.cancel();
    tarifaAuto = null;
  }

  Future<void> cancelar() async {
    if (operando || dialogoAbierto) return;
    pausarAuto();
    final confirma = await _confirmar(
      context,
      titulo: 'Cancelar viaje',
      mensaje: '¿Quieres cancelar esta solicitud de demostración?',
      accion: 'Cancelar viaje',
    );
    if (!mounted) return;
    setState(() => dialogoAbierto = false);
    if (confirma) {
      await actualizar({'estado': 'cancelado'}, aviso: 'Viaje cancelado.');
    }
  }

  Future<void> otroMonto(int actual) async {
    if (operando || dialogoAbierto) return;
    pausarAuto();
    final monto = await _pedirTarifa(context, actual);
    if (!mounted) return;
    setState(() => dialogoAbierto = false);
    if (monto != null) {
      await actualizar({'tarifa': monto}, aviso: 'Tarifa actualizada.');
    }
  }

  void programarAuto({required bool activa, required int tarifa}) {
    if (!activa) {
      esperaAuto?.cancel();
      esperaAuto = null;
      tarifaAuto = null;
      return;
    }
    if (dialogoAbierto || operando || tarifaAuto == tarifa) return;
    esperaAuto?.cancel();
    tarifaAuto = tarifa;
    esperaAuto = Timer(_esperaOferta, () => aceptarAutomaticamente(tarifa));
  }

  Future<void> aceptarAutomaticamente(int tarifa) async {
    if (!mounted) return;
    if (operando) {
      tarifaAuto = null;
      return;
    }
    setState(() => operando = true);
    try {
      // Releer la solicitud para no confirmar tras una cancelación o cambio de tarifa.
      final aceptada = await FirebaseFirestore.instance.runTransaction((
        tx,
      ) async {
        final datos = (await tx.get(documento)).data();
        if (datos == null ||
            datos['estado'] != 'buscando' ||
            datos['autoAceptar'] != true ||
            datos['tarifa'] != tarifa) {
          return false;
        }
        tx.update(documento, {
          'estado': 'confirmado',
          'conductor': 'Conductor A',
          'tarifa': tarifa,
        });
        return true;
      });
      if (mounted && aceptada) {
        _aviso(context, 'Oferta demo aceptada automáticamente.');
      }
    } catch (_) {
      if (mounted) {
        _aviso(context, 'No se pudo aceptar la oferta automáticamente.');
      }
    } finally {
      if (mounted) setState(() => operando = false);
    }
  }

  Widget oferta(String conductor, int monto, VoidCallback aceptar) {
    final demo = _conductoresDemo[conductor]!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${clp(monto)} · ${demo.minutos} min',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(conductor),
              subtitle: Text('${demo.vehiculo} · ${demo.patente}'),
              onTap: aceptar,
            ),
            OutlinedButton(
              onPressed: aceptar,
              child: Text('Aceptar oferta de $conductor'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> verOfertas(int tarifa) async {
    if (operando || dialogoAbierto) return;
    pausarAuto();
    final otraOferta = (tarifa + 200).clamp(_tarifaMinima, _tarifaMaxima);
    final decision = await showDialog<_DecisionOferta>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        insetPadding: const EdgeInsets.all(AppSpacing.spacing16),
        title: const Text('Ofertas de ejemplo'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            oferta(
              'Conductor A',
              tarifa,
              () => Navigator.pop(dialogContext, _DecisionOferta.conductorA),
            ),
            oferta(
              'Conductor B',
              otraOferta,
              () => Navigator.pop(dialogContext, _DecisionOferta.conductorB),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, _DecisionOferta.cancelar),
            child: const Text('Cancelar viaje'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => dialogoAbierto = false);
    if (decision == null) return;
    if (decision == _DecisionOferta.cancelar) {
      await cancelar();
      return;
    }
    final esPrimera = decision == _DecisionOferta.conductorA;
    await actualizar({
      'estado': 'confirmado',
      'conductor': esPrimera ? 'Conductor A' : 'Conductor B',
      'tarifa': esPrimera ? tarifa : otraOferta,
    });
  }

  List<Widget> negociacion(int tarifa, bool autoAceptar) {
    return [
      Card(
        color: AppColors.seleccion,
        child: ListTile(
          title: Text(clp(tarifa)),
          subtitle: const Text('Tarifa propuesta'),
          trailing: TextButton(
            onPressed: operando ? null : () => otroMonto(tarifa),
            child: const Text('Otro monto'),
          ),
        ),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Aceptar automáticamente'),
        subtitle: const Text(
          'Confirma la primera oferta demo que respete tu tarifa.',
        ),
        value: autoAceptar,
        onChanged: operando
            ? null
            : (valor) => actualizar({'autoAceptar': valor}),
      ),
      const SizedBox(height: AppSpacing.spacing8),
      FilledButton(
        onPressed: operando ? null : () => verOfertas(tarifa),
        child: const Text('Ver ofertas'),
      ),
    ];
  }

  List<Widget> accionesViaje(String estado, int calificacion) => [
    if (estado == 'confirmado')
      FilledButton(
        onPressed: operando ? null : () => actualizar({'estado': 'en curso'}),
        child: const Text('Iniciar viaje demo'),
      ),
    if (estado == 'en curso')
      FilledButton(
        onPressed: operando ? null : () => actualizar({'estado': 'completado'}),
        child: const Text('Completar viaje demo'),
      ),
    if (!_cerrado(estado))
      OutlinedButton(
        onPressed: operando ? null : cancelar,
        child: const Text('Cancelar viaje'),
      ),
    if (estado == 'completado') ...[
      const SizedBox(height: AppSpacing.spacing8),
      Text(
        calificacion == 0
            ? 'Califica tu viaje'
            : 'Tu calificación: $calificacion de 5',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      Wrap(
        children: [
          for (var i = 1; i <= 5; i++)
            IconButton(
              tooltip: 'Calificar con $i ${i == 1 ? 'estrella' : 'estrellas'}',
              onPressed: operando
                  ? null
                  : () => actualizar({
                      'calificacion': i,
                    }, aviso: 'Calificación guardada.'),
              icon: Icon(
                i <= calificacion ? Icons.star : Icons.star_border,
                color: AppColors.verdeOscuro,
              ),
            ),
        ],
      ),
    ],
  ];

  Future<void> copiarResumen(Map<String, dynamic> datos) async {
    final estado = datos['estado'] as String? ?? '';
    final conductor = datos['conductor'] as String? ?? '';
    final resumen = [
      'InDrive · Viaje de demostración',
      'Origen: ${datos['origen']}',
      'Destino: ${datos['destino']}',
      'Estado: ${_estados[estado] ?? estado}',
      if (conductor.isNotEmpty) 'Conductor demo: $conductor',
    ].join('\n');
    try {
      await Clipboard.setData(ClipboardData(text: resumen));
      if (mounted) _aviso(context, 'Resumen copiado.');
    } catch (_) {
      if (mounted) _aviso(context, 'No se pudo copiar el resumen.');
    }
  }

  Widget detalle(Map<String, dynamic> datos) {
    final estado = datos['estado'] as String? ?? '';
    final tarifa = datos['tarifa'] as int? ?? 0;
    final autoAceptar = datos['autoAceptar'] as bool? ?? false;
    final conductor = datos['conductor'] as String? ?? '';
    final demo = _conductoresDemo[conductor];
    final servicio = datos['servicio'] as String? ?? 'Ciudad';
    programarAuto(activa: estado == 'buscando' && autoAceptar, tarifa: tarifa);

    return ListView(
      children: [
        MapaViaje(
          altura: estado == 'buscando'
              ? AppSize.mapaNegociacion
              : AppSize.mapaConfirmacion,
          conRuta: true,
        ),
        _panelViaje(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _estados[estado] ?? estado,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Text('Demostración · Sin conductor ni cobro reales'),
              if (operando) const LinearProgressIndicator(),
              const SizedBox(height: AppSpacing.spacing12),
              if (estado == 'buscando') ...negociacion(tarifa, autoAceptar),
              if (demo != null)
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_outline),
                    ),
                    title: Text(conductor),
                    subtitle: Text(
                      estado == 'confirmado'
                          ? 'Llegada estimada: ${demo.minutos} min · ${demo.vehiculo} · ${demo.patente}'
                          : '${demo.vehiculo} · ${demo.patente}',
                    ),
                    isThreeLine: estado == 'confirmado',
                  ),
                ),
              const SizedBox(height: AppSpacing.spacing8),
              ...accionesViaje(estado, datos['calificacion'] as int? ?? 0),
              const Divider(),
              Text(
                'Resumen del viaje',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.trip_origin),
                title: Text(datos['origen'] as String? ?? ''),
                subtitle: const Text('Origen'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.location_on_outlined),
                title: Text(datos['destino'] as String? ?? ''),
                subtitle: const Text('Destino'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(_iconoServicio(servicio)),
                title: Text('$servicio · ${clp(tarifa)}'),
                subtitle: Text(
                  '${datos['pago']} · ${_fecha(datos['creadoEn'])}',
                ),
              ),
              const SizedBox(height: AppSpacing.spacing8),
              Wrap(
                spacing: AppSpacing.spacing8,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SeguridadScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.shield_outlined),
                    label: const Text('Seguridad'),
                  ),
                  TextButton.icon(
                    onPressed: () => copiarResumen(datos),
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Copiar resumen'),
                  ),
                  if (conductor.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ChatViajeScreen(
                            uid: widget.uid,
                            viajeId: widget.id,
                            conductor: conductor,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Chat de demo'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del viaje')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: viaje,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('No se pudo cargar el viaje.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final datos = snapshot.data!.data();
          if (datos == null) {
            return const Center(
              child: Text('Este viaje ya no está disponible.'),
            );
          }
          return detalle(datos);
        },
      ),
    );
  }
}

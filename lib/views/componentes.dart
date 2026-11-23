import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../mapa.dart';
import '../theme/theme.dart';

class MapaViaje extends StatefulWidget {
  const MapaViaje({
    super.key,
    this.altura = AppSize.mapaInicio,
    this.abrirMenu,
    this.origen,
    this.destino,
    this.puntoOrigen,
    this.puntoDestino,
  });

  final double altura;
  final VoidCallback? abrirMenu;
  final String? origen;
  final String? destino;
  final LatLng? puntoOrigen;
  final LatLng? puntoDestino;

  @override
  State<MapaViaje> createState() => _MapaViajeState();
}

class _MapaViajeState extends State<MapaViaje> {
  gmaps.GoogleMapController? controlador;
  gmaps.BitmapDescriptor? iconoUdd;
  LatLng? origen;
  LatLng? destino;
  List<LatLng> ruta = const [];
  int consulta = 0;
  String? estado;

  gmaps.LatLng coordenada(LatLng punto) =>
      gmaps.LatLng(punto.latitude, punto.longitude);

  @override
  void initState() {
    super.initState();
    prepararPuntoAzul();
    cargarLugares();
  }

  @override
  void didUpdateWidget(MapaViaje anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.origen != widget.origen ||
        anterior.destino != widget.destino ||
        anterior.puntoOrigen != widget.puntoOrigen ||
        anterior.puntoDestino != widget.puntoDestino) {
      cargarLugares();
    } else if (anterior.altura != widget.altura) {
      ajustarVista();
    }
  }

  @override
  void dispose() {
    controlador?.dispose();
    super.dispose();
  }

  Future<void> prepararPuntoAzul() async {
    // El punto representa siempre el campus, sin consultar el dispositivo.
    final dibujo = ui.PictureRecorder();
    final lienzo = Canvas(dibujo);
    lienzo.drawCircle(
      const Offset(36, 36),
      34,
      Paint()..color = Colors.black12,
    );
    lienzo.drawCircle(
      const Offset(36, 36),
      30,
      Paint()..color = AppColors.blanco,
    );
    lienzo.drawCircle(
      const Offset(36, 36),
      23,
      Paint()..color = AppColors.azul,
    );
    final grabado = dibujo.endRecording();
    final imagen = await grabado.toImage(72, 72);
    grabado.dispose();
    final bytes = await imagen.toByteData(format: ui.ImageByteFormat.png);
    imagen.dispose();
    if (!mounted || bytes == null) return;
    setState(() {
      iconoUdd = gmaps.BitmapDescriptor.bytes(
        bytes.buffer.asUint8List(),
        width: 24,
        height: 24,
      );
    });
  }

  Future<void> cargarLugares() async {
    final solicitud = ++consulta;
    final textoOrigen = widget.origen?.trim() ?? '';
    final textoDestino = widget.destino?.trim() ?? '';
    origen = null;
    destino = null;
    ruta = const [];
    if (textoOrigen.isEmpty && textoDestino.isEmpty) {
      estado = null;
      ajustarVista();
      return;
    }
    estado = 'Ubicando direcciones…';

    final puntos = await Future.wait([
      widget.puntoOrigen == null
          ? buscarPunto(textoOrigen)
          : Future.value(widget.puntoOrigen),
      widget.puntoDestino == null
          ? buscarPunto(textoDestino)
          : Future.value(widget.puntoDestino),
    ]);
    if (!mounted || consulta != solicitud) return;
    final inicio = puntos[0];
    final fin = puntos[1];
    final faltaOrigen = textoOrigen.isNotEmpty && inicio == null;
    final faltaDestino = textoDestino.isNotEmpty && fin == null;
    setState(() {
      origen = inicio;
      destino = fin;
      estado = switch ((faltaOrigen, faltaDestino)) {
        (true, true) => 'No pudimos ubicar las direcciones.',
        (true, false) => 'No pudimos ubicar el origen.',
        (false, true) =>
          widget.origen == null
              ? 'No pudimos ubicar esta dirección.'
              : 'No pudimos ubicar el destino.',
        _ when inicio != null && fin != null && inicio == fin =>
          'Elige dos puntos distintos para ver la ruta.',
        _ when inicio != null && fin != null => 'Calculando ruta…',
        _ => null,
      };
    });
    ajustarVista();

    if (inicio == null || fin == null || inicio == fin) return;
    final recorrido = await buscarRuta(inicio, fin);
    if (!mounted || consulta != solicitud) return;
    setState(() {
      ruta = recorrido;
      estado = ruta.isEmpty ? 'No pudimos calcular la ruta.' : null;
    });
    ajustarVista();
  }

  void ajustarVista() {
    if (controlador == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) centrarMapa();
    });
  }

  Future<void> moverCamara(gmaps.CameraUpdate vista) async {
    final mapa = controlador;
    if (mapa == null || !mounted) return;
    try {
      await mapa.moveCamera(vista);
    } catch (_) {
      // Una pantalla cerrada puede terminar de recibir el movimiento pendiente.
    }
  }

  void centrarEnLaUdd() {
    moverCamara(gmaps.CameraUpdate.newLatLngZoom(coordenada(centroMapa), 15.5));
  }

  void centrarMapa() {
    final inicio = origen;
    final fin = destino;
    if (inicio != null && fin != null && inicio != fin) {
      final puntos = [inicio, fin, ...ruta];
      final sur = puntos.map((p) => p.latitude).reduce(math.min);
      final norte = puntos.map((p) => p.latitude).reduce(math.max);
      final oeste = puntos.map((p) => p.longitude).reduce(math.min);
      final este = puntos.map((p) => p.longitude).reduce(math.max);
      moverCamara(
        gmaps.CameraUpdate.newLatLngBounds(
          gmaps.LatLngBounds(
            southwest: gmaps.LatLng(sur, oeste),
            northeast: gmaps.LatLng(norte, este),
          ),
          36,
        ),
      );
    } else {
      moverCamara(
        gmaps.CameraUpdate.newLatLngZoom(
          coordenada(inicio ?? fin ?? centroMapa),
          15.5,
        ),
      );
    }
  }

  Widget enlaceMapa(String titulo, String enlace) {
    return TextButton(
      onPressed: () async {
        final abierto = await launchUrl(
          Uri.parse(enlace),
          mode: LaunchMode.externalApplication,
        );
        if (!abierto && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No pudimos abrir el enlace.')),
          );
        }
      },
      child: Text(titulo),
    );
  }

  void informacionMapa() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Información del mapa'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Google Maps muestra las calles y los lugares del mapa.',
            ),
            TextButton(
              onPressed: () => showLicensePage(
                context: dialogContext,
                applicationName: 'InDrive',
              ),
              child: const Text('Licencias de Google Maps'),
            ),
            const Text(
              'Las direcciones y los recorridos consultan datos de OpenStreetMap. '
              'Las rutas se calculan con OSRM en el servidor de FOSSGIS.',
            ),
            enlaceMapa(
              '© OpenStreetMap',
              'https://www.openstreetmap.org/copyright',
            ),
            enlaceMapa(
              'OSRM · FOSSGIS',
              'https://routing.openstreetmap.de/about.html',
            ),
            enlaceMapa(
              'Informar un problema del mapa',
              'https://www.openstreetmap.org/fixthemap',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inicio = origen;
    final fin = destino;
    final icono = iconoUdd;
    final aviso = estado;
    final recorrido = ruta.map(coordenada).toList();
    return SizedBox(
      height: widget.altura,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (icono == null)
            const Center(child: CircularProgressIndicator())
          else
            gmaps.GoogleMap(
              initialCameraPosition: gmaps.CameraPosition(
                target: coordenada(centroMapa),
                zoom: 15.5,
              ),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 68),
              minMaxZoomPreference: const gmaps.MinMaxZoomPreference(3, 19),
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              rotateGesturesEnabled: false,
              gestureRecognizers: {
                Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer(),
                ),
              },
              onMapCreated: (mapa) {
                if (!mounted) {
                  mapa.dispose();
                  return;
                }
                controlador = mapa;
                if (origen != null || destino != null) ajustarVista();
              },
              markers: {
                gmaps.Marker(
                  markerId: const gmaps.MarkerId('udd'),
                  position: coordenada(centroMapa),
                  icon: icono,
                  anchor: const Offset(.5, .5),
                  infoWindow: const gmaps.InfoWindow(
                    title: 'Universidad del Desarrollo',
                  ),
                ),
                if (inicio != null)
                  gmaps.Marker(
                    markerId: const gmaps.MarkerId('origen'),
                    position: coordenada(inicio),
                    icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                      gmaps.BitmapDescriptor.hueGreen,
                    ),
                    infoWindow: gmaps.InfoWindow(
                      title: 'Origen',
                      snippet: widget.origen,
                    ),
                  ),
                if (fin != null)
                  gmaps.Marker(
                    markerId: const gmaps.MarkerId('destino'),
                    position: coordenada(fin),
                    infoWindow: gmaps.InfoWindow(
                      title: 'Destino',
                      snippet: widget.destino,
                    ),
                  ),
              },
              polylines: {
                if (recorrido.isNotEmpty) ...[
                  gmaps.Polyline(
                    polylineId: const gmaps.PolylineId('borde-ruta'),
                    points: recorrido,
                    color: AppColors.blanco,
                    width: 8,
                  ),
                  gmaps.Polyline(
                    polylineId: const gmaps.PolylineId('ruta'),
                    points: recorrido,
                    color: AppColors.verdeOscuro,
                    width: 5,
                    zIndex: 1,
                  ),
                ],
              },
            ),
          if (widget.abrirMenu != null)
            Positioned(
              top: AppSpacing.spacing12,
              left: AppSpacing.spacing12,
              child: botonMapa('Abrir menú', Icons.menu, widget.abrirMenu!),
            ),
          Positioned(
            bottom: AppSpacing.spacing20,
            right: AppSpacing.spacing12,
            child: botonMapa(
              'Centrar en la UDD',
              Icons.school_outlined,
              centrarEnLaUdd,
            ),
          ),
          if (widget.origen != null || widget.destino != null)
            Positioned(
              bottom: AppSpacing.spacing72,
              right: AppSpacing.spacing12,
              child: botonMapa(
                'Centrar mapa',
                Icons.center_focus_strong_outlined,
                centrarMapa,
              ),
            ),
          Positioned(
            bottom: AppSpacing.spacing20,
            left: AppSpacing.spacing12,
            child: botonMapa(
              'Información del mapa',
              Icons.info_outline,
              informacionMapa,
            ),
          ),
          if (aviso != null)
            Positioned(
              left: AppSpacing.spacing12,
              right: AppSpacing.spacing12,
              top: AppSpacing.spacing12,
              child: Center(
                child: Material(
                  color: AppColors.blanco,
                  borderRadius: BorderRadius.circular(AppRadius.boton),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.spacing8),
                    child: Text(
                      aviso,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget botonMapa(String nombre, IconData icono, VoidCallback tocar) {
    return Material(
      color: AppColors.blanco,
      elevation: AppSize.elevacionMapa,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: nombre,
        icon: Icon(icono, color: AppColors.verdeOscuro),
        onPressed: tocar,
      ),
    );
  }
}

class PanelMapa extends StatelessWidget {
  const PanelMapa({super.key, required this.child, this.mostrarGuia = true});

  final Widget child;
  final bool mostrarGuia;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.blanco,
      elevation: AppSize.elevacionHoja,
      shadowColor: AppColors.sombra,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.hoja),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: mostrarGuia ? AppSpacing.spacing16 : 0,
            ),
            child: child,
          ),
          if (mostrarGuia)
            Positioned(
              top: AppSpacing.spacing8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: AppSize.guia,
                  height: AppSize.grosorGuia,
                  decoration: BoxDecoration(
                    color: AppColors.contorno,
                    borderRadius: BorderRadius.circular(AppRadius.barra),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

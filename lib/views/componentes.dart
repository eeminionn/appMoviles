import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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
  });

  final double altura;
  final VoidCallback? abrirMenu;
  final String? origen;
  final String? destino;

  @override
  State<MapaViaje> createState() => _MapaViajeState();
}

class _MapaViajeState extends State<MapaViaje> {
  final controlador = MapController();
  final teselas = NetworkTileProvider();
  LatLng? origen;
  LatLng? destino;
  List<LatLng> ruta = const [];
  int consulta = 0;
  bool mapaListo = false;
  String? estado;

  @override
  void initState() {
    super.initState();
    cargarLugares();
  }

  @override
  void didUpdateWidget(MapaViaje anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.origen != widget.origen ||
        anterior.destino != widget.destino) {
      cargarLugares();
    } else if (anterior.altura != widget.altura) {
      ajustarVista();
    }
  }

  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
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
      buscarPunto(textoOrigen),
      buscarPunto(textoDestino),
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && mapaListo) centrarMapa();
    });
  }

  void centrarMapa() {
    final inicio = origen;
    final fin = destino;
    if (inicio != null && fin != null && inicio != fin) {
      controlador.fitCamera(
        CameraFit.coordinates(
          coordinates: [inicio, fin, ...ruta],
          padding: const EdgeInsets.fromLTRB(38, 35, 38, 62),
          maxZoom: 17,
        ),
      );
    } else {
      controlador.move(inicio ?? fin ?? centroMapa, 15.5);
    }
  }

  Marker pin(LatLng punto, IconData icono, Color color, String etiqueta) {
    return Marker(
      point: punto,
      width: 42,
      height: 42,
      child: Tooltip(
        message: etiqueta,
        child: CircleAvatar(
          backgroundColor: AppColors.blanco,
          child: Icon(icono, color: color),
        ),
      ),
    );
  }

  Widget enlaceMapa(String titulo, String enlace) {
    return TextButton(
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: Theme.of(context).textTheme.labelSmall,
      ),
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

  @override
  Widget build(BuildContext context) {
    final inicio = origen;
    final fin = destino;
    final aviso = estado;
    return SizedBox(
      height: widget.altura,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FlutterMap(
            mapController: controlador,
            options: MapOptions(
              initialCenter: centroMapa,
              initialZoom: 15.5,
              minZoom: 3,
              maxZoom: 19,
              backgroundColor: AppColors.suave,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onMapReady: () {
                mapaListo = true;
                ajustarVista();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: const String.fromEnvironment(
                  'URL_TESELAS',
                  defaultValue:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                userAgentPackageName: 'com.example.app_moviles',
                tileProvider: teselas,
                panBuffer: 0,
                maxNativeZoom: 19,
              ),
              if (ruta.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: ruta,
                      strokeWidth: 5,
                      color: AppColors.verdeOscuro,
                      borderStrokeWidth: 2,
                      borderColor: AppColors.blanco,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (inicio != null)
                    pin(
                      inicio,
                      Icons.trip_origin,
                      AppColors.verdeOscuro,
                      'Origen',
                    ),
                  if (fin != null)
                    pin(
                      fin,
                      Icons.place,
                      AppColors.texto,
                      widget.origen == null ? 'Dirección' : 'Destino',
                    ),
                ],
              ),
            ],
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
              'Centrar mapa',
              Icons.near_me_outlined,
              centrarMapa,
            ),
          ),
          Positioned(
            bottom: AppSpacing.spacing20,
            left: AppSpacing.spacing8,
            right: AppSpacing.spacing72,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Material(
                color: AppColors.blanco,
                borderRadius: BorderRadius.circular(AppRadius.boton),
                child: Wrap(
                  children: [
                    enlaceMapa(
                      '© OpenStreetMap',
                      'https://www.openstreetmap.org/copyright',
                    ),
                    if (ruta.isNotEmpty)
                      enlaceMapa(
                        'OSRM · FOSSGIS',
                        'https://routing.openstreetmap.de/about.html',
                      ),
                    enlaceMapa(
                      'Corregir mapa',
                      'https://www.openstreetmap.org/fixthemap',
                    ),
                  ],
                ),
              ),
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

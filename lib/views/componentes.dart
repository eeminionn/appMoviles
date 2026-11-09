import 'package:flutter/material.dart';

import '../theme/theme.dart';

class MapaViaje extends StatefulWidget {
  const MapaViaje({
    super.key,
    this.altura = AppSize.mapaInicio,
    this.abrirMenu,
    this.conRuta = false,
  });

  final double altura;
  final VoidCallback? abrirMenu;
  final bool conRuta;

  @override
  State<MapaViaje> createState() => _MapaViajeState();
}

class _MapaViajeState extends State<MapaViaje> {
  final posicion = TransformationController();

  @override
  void dispose() {
    posicion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.altura,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Mapa del referente, se puede acercar y mover.
          InteractiveViewer(
            transformationController: posicion,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/imagenes/mapa.png',
                  fit: BoxFit.cover,
                  semanticLabel: 'Mapa de referencia del sector UDD',
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.spacing8),
                    decoration: BoxDecoration(
                      color: AppColors.texto,
                      borderRadius: BorderRadius.circular(AppRadius.boton),
                    ),
                    child: Icon(
                      widget.conRuta
                          ? Icons.route_outlined
                          : Icons.location_on_outlined,
                      color: AppColors.blanco,
                      size: AppSize.icono,
                    ),
                  ),
                ),
              ],
            ),
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
              () => posicion.value = Matrix4.identity(),
            ),
          ),
          Positioned(
            bottom: AppSpacing.spacing20,
            left: AppSpacing.spacing12,
            child: Material(
              color: AppColors.blanco,
              borderRadius: BorderRadius.circular(AppRadius.boton),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacing8,
                  vertical: AppSpacing.spacing4,
                ),
                child: Text(
                  'Mapa de referencia',
                  style: Theme.of(context).textTheme.labelSmall,
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

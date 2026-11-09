import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'componentes.dart';
import 'direcciones_screen.dart';
import 'mensajes_screen.dart';
import 'seguridad_screen.dart';
import 'soporte_screen.dart';
import 'viajes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.usuario});

  final User usuario;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final pantalla = GlobalKey<ScaffoldState>();
  int pestana = 0;

  String get uid => widget.usuario.uid;

  void abrir(Widget vista) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => vista));
  }

  void nuevoViaje({String servicio = 'Ciudad', String destino = ''}) {
    abrir(
      NuevoViajeScreen(
        uid: uid,
        servicioInicial: servicio,
        destinoInicial: destino,
      ),
    );
  }

  void irA(int indice) => setState(() => pestana = indice);

  Future<void> salir() async {
    try {
      await FirebaseAuth.instance.signOut();
    } on FirebaseAuthException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cerrar la sesión.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: pantalla,
      drawer: menu(),
      body: switch (pestana) {
        1 => ActividadScreen(uid: uid),
        2 => MensajesScreen(uid: uid),
        3 => perfil(),
        _ => inicio(),
      },
      // Aquí va la barra fija.
      bottomNavigationBar: NavigationBar(
        selectedIndex: pestana,
        onDestinationSelected: irA,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Inicio',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'Actividad'),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Mensajes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget inicio() {
    final textos = Theme.of(context).textTheme;
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, medidas) {
          final altoMapa = math.min(
            AppSize.mapaInicio * medidas.maxWidth / AppSize.anchoReferencia,
            medidas.maxHeight * AppSize.proporcionMapa,
          );
          return Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: MapaViaje(
                  altura: altoMapa,
                  abrirMenu: () => pantalla.currentState?.openDrawer(),
                ),
              ),
              Positioned.fill(
                top: altoMapa - AppSpacing.spacing8,
                child: PanelMapa(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.spacing20,
                      AppSpacing.spacing12,
                      AppSpacing.spacing20,
                      AppSpacing.spacing16,
                    ),
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.tarjeta),
                        onTap: () => nuevoViaje(),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: AppSpacing.spacing8,
                            ),
                          ),
                          child: Text(
                            'Buscar destino',
                            style: textos.bodyMedium,
                          ),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.verdeClaro,
                          child: Icon(Icons.location_on_outlined),
                        ),
                        title: const Text('Metro Salvador'),
                        subtitle: const Text('Providencia, Santiago'),
                        onTap: () => nuevoViaje(destino: 'Metro Salvador'),
                      ),
                      const Divider(),
                      const SizedBox(height: AppSpacing.spacing12),
                      Row(
                        children: [
                          tarjeta(
                            'Ciudad',
                            'Dentro de la ciudad',
                            Icons.directions_car_outlined,
                            true,
                          ),
                          const SizedBox(width: AppSpacing.spacing16),
                          tarjeta(
                            'Entregas',
                            'Envía un paquete',
                            Icons.inventory_2_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.spacing12),
                      Row(
                        children: [
                          tarjeta(
                            'Fletes',
                            'Mueve tu carga',
                            Icons.local_shipping_outlined,
                          ),
                          const SizedBox(width: AppSpacing.spacing16),
                          tarjeta(
                            'Interurbano',
                            'Entre ciudades',
                            Icons.directions_bus_outlined,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget tarjeta(
    String titulo,
    String bajada,
    IconData icono, [
    bool destacada = false,
  ]) {
    final textos = Theme.of(context).textTheme;
    final color = destacada ? AppColors.blanco : AppColors.texto;
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        color: destacada ? AppColors.verde : AppColors.verdeClaro,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => nuevoViaje(servicio: titulo),
          child: SizedBox(
            height: AppSize.tarjeta,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: textos.titleSmall?.copyWith(color: color),
                  ),
                  const SizedBox(height: AppSpacing.spacing4),
                  Text(bajada, style: textos.bodySmall?.copyWith(color: color)),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(
                      icono,
                      size: AppSpacing.spacing40,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget menu() {
    return Drawer(
      width: MediaQuery.sizeOf(context).width * AppSize.anchoMenu,
      backgroundColor: AppColors.blanco,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.spacing12),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: 'Cerrar menú',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => pantalla.currentState?.closeDrawer(),
              ),
            ),
            const SizedBox(height: AppSpacing.spacing24),
            opcion(Icons.directions_car_outlined, 'Ciudad', () => nuevoViaje()),
            opcion(Icons.history, 'Historial de solicitudes', () => irA(1)),
            opcion(
              Icons.inventory_2_outlined,
              'Entregas',
              () => nuevoViaje(servicio: 'Entregas'),
            ),
            opcion(
              Icons.directions_bus_outlined,
              'Ciudad a ciudad',
              () => nuevoViaje(servicio: 'Interurbano'),
            ),
            opcion(
              Icons.local_shipping_outlined,
              'Fletes',
              () => nuevoViaje(servicio: 'Fletes'),
            ),
            opcion(
              Icons.bookmark_border,
              'Mis direcciones',
              () => abrir(DireccionesScreen(uid: uid)),
            ),
            opcion(
              Icons.notifications_none,
              'Notificaciones',
              () => abrir(notificaciones()),
            ),
            opcion(
              Icons.shield_outlined,
              'Seguridad',
              () => abrir(const SeguridadScreen()),
            ),
            opcion(Icons.settings_outlined, 'Configuración', () => irA(3)),
            opcion(
              Icons.help_outline,
              'Ayuda',
              () => abrir(SoporteScreen(uid: uid)),
            ),
            opcion(
              Icons.support_agent,
              'Soporte',
              () => abrir(SoporteScreen(uid: uid)),
            ),
          ],
        ),
      ),
    );
  }

  Widget opcion(IconData icono, String titulo, VoidCallback tocar) {
    return ListTile(
      leading: Icon(icono),
      title: Text(titulo),
      onTap: () {
        pantalla.currentState?.closeDrawer();
        tocar();
      },
    );
  }

  Widget notificaciones() {
    final viajes = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('viajes')
        .orderBy('creadoEn', descending: true)
        .limit(20)
        .snapshots();
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: StreamBuilder(
        stream: viajes,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('No se pudieron cargar las novedades.'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final novedades = snapshot.data!.docs;
          if (novedades.isEmpty) {
            return const Center(
              child: Text('Aquí verás el estado de tus viajes.'),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.spacing12),
            children: [
              for (final viaje in novedades)
                ListTile(
                  leading: const Icon(Icons.notifications_none),
                  title: Text(viaje.data()['destino'] as String),
                  subtitle: Text('Estado: ${viaje.data()['estado']}'),
                  onTap: () =>
                      abrir(DetalleViajeScreen(uid: uid, id: viaje.id)),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget perfil() {
    final nombre = widget.usuario.displayName ?? 'Mi cuenta';
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.spacing20),
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(nombre),
            subtitle: Text(widget.usuario.email ?? ''),
          ),
          const Divider(),
          opcion(
            Icons.bookmark_border,
            'Mis direcciones',
            () => abrir(DireccionesScreen(uid: uid)),
          ),
          opcion(
            Icons.shield_outlined,
            'Centro de seguridad',
            () => abrir(const SeguridadScreen()),
          ),
          opcion(
            Icons.support_agent,
            'Ayuda y soporte',
            () => abrir(SoporteScreen(uid: uid)),
          ),
          const SizedBox(height: AppSpacing.spacing24),
          OutlinedButton.icon(
            onPressed: salir,
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}

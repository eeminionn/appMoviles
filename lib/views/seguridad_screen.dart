import 'package:flutter/material.dart';

import '../theme/theme.dart';

class SeguridadScreen extends StatelessWidget {
  const SeguridadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Centro de seguridad')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.spacing20),
        children: [
          Text(
            'Antes de viajar',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.spacing12),
          const Text(
            'Consulta estos consejos desde el menú o desde el detalle de tu viaje.',
          ),
          const SizedBox(height: AppSpacing.spacing16),
          const Card(
            child: ExpansionTile(
              leading: Icon(Icons.directions_car_outlined),
              title: Text('Verifica tu vehículo'),
              childrenPadding: EdgeInsets.all(AppSpacing.spacing16),
              children: [
                Text(
                  'Antes de subir, comprueba que el vehículo y la patente coincidan con los datos que acordaste.',
                ),
              ],
            ),
          ),
          const Card(
            child: ExpansionTile(
              leading: Icon(Icons.share_outlined),
              title: Text('Comparte los datos del viaje'),
              childrenPadding: EdgeInsets.all(AppSpacing.spacing16),
              children: [
                Text(
                  'Avisa a alguien de confianza el origen, el destino y tu hora estimada de llegada.',
                ),
              ],
            ),
          ),
          const Card(
            child: ExpansionTile(
              leading: Icon(Icons.lock_outline),
              title: Text('Cuida tus datos'),
              childrenPadding: EdgeInsets.all(AppSpacing.spacing16),
              children: [
                Text(
                  'Evita compartir contraseñas, códigos de verificación o datos bancarios.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

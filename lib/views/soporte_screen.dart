import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/theme.dart';

const temasSoporte = <String, Map<String, String>>{
  'Ciudad': {
    'Servicio estándar':
        'Indica el origen y el destino, revisa la tarifa y elige una oferta antes de confirmar. Puedes revisar el estado de la solicitud en Actividad.',
    'Seguridad':
        'Antes de salir, revisa los consejos del Centro de seguridad desde el menú.',
    'Preguntas':
        'Si quieres cambiar el monto, usa Otro monto mientras la solicitud está buscando ofertas. Si la solicitud ya fue aceptada, puedes cancelarla y hacer una nueva.',
  },
  'Interciudad': {
    'Planificar el viaje':
        'Verifica el origen y el destino antes de confirmar. Puedes copiar el resumen del viaje desde Actividad para compartirlo con una persona de confianza.',
    'Equipaje':
        'Antes de salir, considera el número de maletas y el espacio que vas a necesitar.',
  },
  'Fletes': {
    'Preparar la carga':
        'Mide la carga y verifica que quepa por los accesos de origen y destino. Puedes seleccionar Fletes al organizar un viaje.',
    'Entregas':
        'Para organizar el traslado de un paquete pequeño, selecciona Entregas e indica dónde quieres retirarlo y dejarlo.',
  },
  'Otro': {
    'Pagos':
        'Puedes elegir un medio de pago al solicitar un viaje. La selección y el monto quedan guardados en el resumen de Actividad.',
    'Direcciones guardadas':
        'Abre Mis direcciones desde el menú para guardar domicilio, trabajo u otro lugar. Usa el lápiz para editar o eliminar un lugar.',
  },
};

const articulosPerfil = <String, String>{
  'Seguridad de la cuenta':
      'Usa una contraseña distinta para cada servicio. Cierra sesión desde Perfil si usas un equipo compartido.',
  'Datos de seguridad':
      'Al guardar una consulta, evita incluir contraseñas, códigos de verificación o datos bancarios.',
  'Comunicación':
      'Abre Mensajes para consultar las notas que guardaste sobre un viaje. Si encuentras un problema, puedes describirlo y guardar la consulta en tu cuenta.',
  'Otro':
      'En Perfil puedes revisar la sesión actual. Para cambiar una contraseña olvidada, usa la opción de recuperación en la pantalla de inicio de sesión.',
};

class SoporteScreen extends StatelessWidget {
  const SoporteScreen({super.key, required this.uid});

  final String uid;

  CollectionReference<Map<String, dynamic>> get consultas => FirebaseFirestore
      .instance
      .collection('usuarios')
      .doc(uid)
      .collection('consultas');

  void abrirConsultas(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => _MisConsultasScreen(consultas: consultas),
      ),
    );
  }

  Future<void> registrarConsulta(BuildContext context, String tema) async {
    final guardada = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      builder: (context) =>
          _FormularioConsulta(tema: tema, consultas: consultas),
    );
    if (!context.mounted || guardada != true) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Consulta guardada')));
  }

  Widget fila(String titulo, VoidCallback alTocar) => ListTile(
    title: Text(titulo),
    trailing: const Icon(Icons.chevron_right, color: AppColors.secundario),
    onTap: alTocar,
  );

  void abrirArticulo(BuildContext context, String titulo, String contenido) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) {
          final textos = Theme.of(context).textTheme;
          return Scaffold(
            appBar: AppBar(title: const Text('Soporte')),
            body: ListView(
              padding: const EdgeInsets.all(AppSpacing.spacing24),
              children: [
                Text(titulo, style: textos.titleLarge),
                const SizedBox(height: AppSpacing.spacing16),
                Text(contenido, style: textos.bodyLarge),
                const SizedBox(height: AppSpacing.spacing32),
                FilledButton(
                  onPressed: () => registrarConsulta(context, titulo),
                  child: const Text('Registrar consulta'),
                ),
                TextButton(
                  onPressed: () => abrirConsultas(context),
                  child: const Text('Mis consultas'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void abrirTema(BuildContext context, String tema) {
    final articulos = temasSoporte[tema]!;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Soporte')),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.spacing24),
            children: [
              Text(tema, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.spacing24),
              for (final articulo in articulos.entries) ...[
                fila(
                  articulo.key,
                  () => abrirArticulo(context, articulo.key, articulo.value),
                ),
                if (tema == 'Ciudad' && articulo.key == 'Servicio estándar')
                  ExpansionTile(
                    title: const Text('Mi perfil'),
                    collapsedIconColor: AppColors.secundario,
                    childrenPadding: const EdgeInsets.only(
                      left: AppSpacing.spacing20,
                    ),
                    children: [
                      Material(
                        color: AppColors.verdeClaro,
                        child: Column(
                          children: [
                            for (final perfil in articulosPerfil.entries)
                              fila(
                                perfil.key,
                                () => abrirArticulo(
                                  context,
                                  perfil.key,
                                  perfil.value,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Soporte')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.spacing24),
        children: [
          Text('Temas', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.spacing24),
          for (final tema in temasSoporte.keys)
            fila(tema, () => abrirTema(context, tema)),
          const SizedBox(height: AppSpacing.spacing24),
          const Divider(),
          fila('Mis consultas', () => abrirConsultas(context)),
        ],
      ),
    );
  }
}

class _FormularioConsulta extends StatefulWidget {
  const _FormularioConsulta({required this.tema, required this.consultas});

  final String tema;
  final CollectionReference<Map<String, dynamic>> consultas;

  @override
  State<_FormularioConsulta> createState() => _FormularioConsultaState();
}

class _FormularioConsultaState extends State<_FormularioConsulta> {
  final formKey = GlobalKey<FormState>();
  final mensajeController = TextEditingController();
  bool guardando = false;
  String? error;

  @override
  void dispose() {
    mensajeController.dispose();
    super.dispose();
  }

  Future<void> guardarConsulta() async {
    if (!formKey.currentState!.validate()) return;
    setState(() {
      guardando = true;
      error = null;
    });
    try {
      await widget.consultas.add({
        'tema': widget.tema,
        'mensaje': mensajeController.text.trim(),
        'creadoEn': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FirebaseException {
      if (!mounted) return;
      setState(() => error = 'No pudimos guardar la consulta.');
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return PopScope<bool>(
      canPop: !guardando,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.spacing24,
          AppSpacing.spacing24,
          AppSpacing.spacing24,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.spacing24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.tema, style: tema.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.spacing8),
              const Text('Describe tu consulta sin incluir datos personales.'),
              const SizedBox(height: AppSpacing.spacing16),
              TextFormField(
                controller: mensajeController,
                enabled: !guardando,
                maxLength: 400,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Mensaje'),
                validator: (valor) => (valor ?? '').trim().length < 4
                    ? 'Escribe un mensaje de al menos 4 caracteres'
                    : null,
              ),
              FilledButton(
                onPressed: guardando ? null : guardarConsulta,
                child: const Text('Guardar consulta'),
              ),
              TextButton(
                onPressed: guardando ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              if (guardando) const LinearProgressIndicator(),
              if (error != null)
                Text(
                  error!,
                  style: tema.textTheme.bodyMedium?.copyWith(
                    color: tema.colorScheme.error,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MisConsultasScreen extends StatefulWidget {
  const _MisConsultasScreen({required this.consultas});

  final CollectionReference<Map<String, dynamic>> consultas;

  @override
  State<_MisConsultasScreen> createState() => _MisConsultasScreenState();
}

class _MisConsultasScreenState extends State<_MisConsultasScreen> {
  late final cambios = widget.consultas
      .orderBy('creadoEn', descending: true)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis consultas')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: cambios,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('No pudimos cargar tus consultas.'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final documentos = snapshot.data!.docs;
          if (documentos.isEmpty) {
            return const Center(child: Text('Aún no tienes consultas.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.spacing20),
            itemCount: documentos.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, indice) {
              final datos = documentos[indice].data();
              return ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: Text(datos['tema'] as String? ?? ''),
                subtitle: Text(datos['mensaje'] as String? ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}

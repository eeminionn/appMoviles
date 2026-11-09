import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/theme.dart';

class MensajesScreen extends StatelessWidget {
  const MensajesScreen({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final viajes = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('viajes');
    return Scaffold(
      appBar: AppBar(title: const Text('Mensajes')),
      body: StreamBuilder(
        stream: viajes.orderBy('creadoEn', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('No se pudieron cargar las conversaciones.'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final chats = snapshot.data!.docs
              .where(
                (doc) => (doc.data()['conductor'] as String? ?? '').isNotEmpty,
              )
              .toList();
          if (chats.isEmpty) {
            return const Center(
              child: Text('Acepta una oferta para abrir el chat del viaje.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.spacing16),
            itemCount: chats.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, i) {
              final viaje = chats[i];
              final datos = viaje.data();
              final conductor = datos['conductor'] as String;
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(conductor),
                subtitle: Text(datos['destino'] as String),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ChatViajeScreen(
                      uid: uid,
                      viajeId: viaje.id,
                      conductor: conductor,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ChatViajeScreen extends StatefulWidget {
  const ChatViajeScreen({
    super.key,
    required this.uid,
    required this.viajeId,
    required this.conductor,
  });

  final String uid;
  final String viajeId;
  final String conductor;

  @override
  State<ChatViajeScreen> createState() => _ChatViajeScreenState();
}

class _ChatViajeScreenState extends State<ChatViajeScreen> {
  final controlador = TextEditingController();
  late final mensajes = FirebaseFirestore.instance
      .collection('usuarios')
      .doc(widget.uid)
      .collection('mensajes');
  late final viaje = FirebaseFirestore.instance
      .collection('usuarios')
      .doc(widget.uid)
      .collection('viajes')
      .doc(widget.viajeId)
      .snapshots();
  late final lista = mensajes
      .where('viajeId', isEqualTo: widget.viajeId)
      .snapshots();
  bool enviando = false;

  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  Future<void> guardarMensaje() async {
    final texto = controlador.text.trim();
    if (texto.isEmpty || enviando) return;
    setState(() => enviando = true);
    try {
      await mensajes.add({
        'viajeId': widget.viajeId,
        'texto': texto,
        'creadoEn': FieldValue.serverTimestamp(),
      });
      if (mounted) controlador.clear();
    } on FirebaseException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el mensaje.')),
      );
    } finally {
      if (mounted) setState(() => enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.conductor)),
      body: StreamBuilder(
        stream: viaje,
        builder: (context, estado) {
          if (estado.hasError) {
            return const Center(child: Text('No se pudo abrir el chat.'));
          }
          if (!estado.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!estado.data!.exists) {
            return const Center(
              child: Text('Este viaje ya no está en tu historial.'),
            );
          }
          return SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.spacing16),
                  child: Text(
                    'Chat de demostración. Los mensajes quedan en tu cuenta.',
                  ),
                ),
                Expanded(
                  child: StreamBuilder(
                    stream: lista,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('No se pudieron cargar los mensajes.'),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = [...snapshot.data!.docs]
                        ..sort((a, b) {
                          final fechaA = a.data()['creadoEn'] as Timestamp?;
                          final fechaB = b.data()['creadoEn'] as Timestamp?;
                          return (fechaB?.millisecondsSinceEpoch ?? 0)
                              .compareTo(fechaA?.millisecondsSinceEpoch ?? 0);
                        });
                      if (docs.isEmpty) {
                        return const Center(
                          child: Text('Aún no hay mensajes.'),
                        );
                      }
                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(AppSpacing.spacing16),
                        itemCount: docs.length,
                        itemBuilder: (context, i) => Align(
                          alignment: Alignment.centerRight,
                          child: Card(
                            color: AppColors.seleccion,
                            child: Padding(
                              padding: const EdgeInsets.all(
                                AppSpacing.spacing12,
                              ),
                              child: Text(docs[i].data()['texto'] as String),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.spacing12),
                  child: TextField(
                    controller: controlador,
                    readOnly: enviando,
                    maxLength: 280,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => guardarMensaje(),
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje',
                      counterText: '',
                      suffixIcon: IconButton(
                        tooltip: 'Guardar mensaje',
                        onPressed: enviando ? null : guardarMensaje,
                        icon: const Icon(Icons.send_outlined),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

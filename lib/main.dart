import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App móviles',
      home: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: const Icon(Icons.menu),
          title: const Text('Creaciones'),
          actions: const [Icon(Icons.more_vert), SizedBox(width: 16)],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cajas para las dos pestañas de arriba.
                Row(
                  children: [
                    Expanded(child: Container(height: 40, color: Colors.black)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(height: 40, color: Color(0xFFD9D9D9)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Espacio del buscador.
                Container(
                  width: double.infinity,
                  height: 48,
                  color: Color(0xFFEDEDED),
                ),
                const SizedBox(height: 28),

                // Caja donde va el título de las categorías.
                Container(width: 220, height: 24, color: Color(0xFFD9D9D9)),
                const SizedBox(height: 16),

                // Primera fila: repostería y verduras.
                Row(
                  children: [
                    Expanded(
                      child: Container(height: 90, color: Color(0xFFCC7188)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(height: 90, color: Color(0xFFB6BD48)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

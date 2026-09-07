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
      // Evita que las cajas se estiren al llegar al inicio o al final.
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        overscroll: false,
      ),
      title: 'App móviles',
      home: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          scrolledUnderElevation: 0,
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
                // Pestañas de arriba.
                Row(
                  children: [
                    Container(
                      width: 128,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Text(
                        'Creaciones',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Text(
                        'Personas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Caja del buscador.
                Container(
                  width: double.infinity,
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFFB5B5B5)),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: Color(0xFFA5A5A5)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Buscar creaciones',
                          style: TextStyle(
                            color: Color(0xFFA5A5A5),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFEDEDED)),
                const SizedBox(height: 8),

                // Título de las categorías.
                const Text(
                  'Categorías más buscadas',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Primera fila: repostería y verduras.
                Row(
                  children: [
                    Expanded(
                      child: Container(height: 100, color: Color(0xFFCC7188)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(height: 100, color: Color(0xFFB6BD48)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Segunda fila: pescado y guarnición.
                Row(
                  children: [
                    Expanded(
                      child: Container(height: 100, color: Color(0xFF9BA8B4)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(height: 100, color: Color(0xFFCEB174)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tercera fila: salsas y aperitivos.
                Row(
                  children: [
                    Expanded(
                      child: Container(height: 100, color: Color(0xFFC9BDA7)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(height: 100, color: Color(0xFFE8AC79)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Cuarta fila: carne y dulce.
                Row(
                  children: [
                    Expanded(
                      child: Container(height: 100, color: Color(0xFFDD6053)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(height: 100, color: Color(0xFFE9B057)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Repetimos las cajas para seguir bajando.
                Row(
                  children: [
                    Expanded(
                      child: Container(height: 100, color: Color(0xFFCC7188)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(height: 100, color: Color(0xFFB6BD48)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Otra fila de pescado y guarnición.
                Row(
                  children: [
                    Expanded(
                      child: Container(height: 100, color: Color(0xFF9BA8B4)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(height: 100, color: Color(0xFFCEB174)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Otra fila de salsas y aperitivos.
                Row(
                  children: [
                    Expanded(
                      child: Container(height: 100, color: Color(0xFFC9BDA7)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(height: 100, color: Color(0xFFE8AC79)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Otra fila de carne y dulce.
                Row(
                  children: [
                    Expanded(
                      child: Container(height: 100, color: Color(0xFFDD6053)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(height: 100, color: Color(0xFFE9B057)),
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

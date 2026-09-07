import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //Para que no se buggen la cajas pq sino se estiran xd
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        overscroll: false,
      ),
      title: 'E_Abarca',
      home: Scaffold(
        backgroundColor: Colors.white,
        // Esta barra queda fija mientras las cajas se mueven.
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEDEDED))),
            ),

            //barrita de abajo
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(width: 35, height: 35, color: Color(0xFF3E3E3E)),
                Container(width: 35, height: 35, color: Color(0xFF16ADA8)),
                Container(width: 35, height: 35, color: Color(0xFF3E3E3E)),
                Container(width: 35, height: 35, color: Color(0xFF3E3E3E)),
              ],
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pestañas de arribade personas y creaciones
                Row(
                  children: [
                    Container(
                      width: 128,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Container(
                      width: 100,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Color(0xFFD9D9D9),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Caja del bsucador
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFFB5B5B5)),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFEDEDED)),
                const SizedBox(height: 10),

                // titulo de las categorias
                Container(width: 220, height: 24, color: Color(0xFFD9D9D9)),
                const SizedBox(height: 16),

                // Primera fila color de verduras y reposteria
                Row(
                  children: [
                    Expanded(
                      child: Container(height: 100, color: Color(0xFFC77D92)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(height: 100, color: Color(0xFFAEB653)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // segunda fila pescados y guarnicion
                Row(
                  children: [
                    Expanded(
                      child: Container(height: 100, color: Color(0xFF95A7B8)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(height: 100, color: Color(0xFFCEB174)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3era fila aperitivos y salsas
                Row(
                  children: [
                    Expanded(
                      child: Container(height: 100, color: Color(0xFFC9BDA7)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(height: 100, color: Color(0xFFE3A580)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 4ta fila carne y dulces
                Row(
                  children: [
                    Expanded(
                      child: Container(height: 100, color: Color(0xFFD66C60)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(height: 100, color: Color(0xFFE9B057)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // copipaste para scroll xd
                Row(
                  children: [
                    Expanded(
                      child: Container(height: 100, color: Color(0xFFC77D92)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(height: 100, color: Color(0xFFAEB653)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // copipaste para scroll xd
                Row(
                  children: [
                    Expanded(
                      child: Container(height: 100, color: Color(0xFF95A7B8)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(height: 100, color: Color(0xFFCEB174)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // copipaste para scroll xd
                Row(
                  children: [
                    Expanded(
                      child: Container(height: 100, color: Color(0xFFC9BDA7)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(height: 100, color: Color(0xFFE3A580)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // copipaste para scroll xd
                Row(
                  children: [
                    Expanded(
                      child: Container(height: 100, color: Color(0xFFD66C60)),
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

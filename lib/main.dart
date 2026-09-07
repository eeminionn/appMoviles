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
        appBar: AppBar(title: const Text('App móviles')),
        body: const SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: Text('Aquí vamos a armar la pantalla.'),
            ),
          ),
        ),
      ),
    );
  }
}

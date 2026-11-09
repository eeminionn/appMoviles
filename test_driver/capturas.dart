import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() {
  final ruta = Platform.environment['INDRIVE_CAPTURAS_DIR'] ?? 'build/capturas';
  final carpeta = Directory(ruta)..createSync(recursive: true);
  return integrationDriver(
    onScreenshot: (nombre, bytes, [argumentos]) async {
      await File('${carpeta.path}/$nombre.png').writeAsBytes(bytes);
      return true;
    },
  );
}

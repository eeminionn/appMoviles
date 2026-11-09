# InDrive

Prototipo de pasajeros para Desarrollo de Aplicaciones Móviles con [@joseSantorcuato](https://github.com/joseSantorcuato). Parte del [referente de InDrive en Figma](https://www.figma.com/design/NYWjQGbz2z6YSUq3c5zHBV/DesignSystem-InDrive--Copy-?node-id=286-14332). La [copia de trabajo](https://www.figma.com/design/rRx9CyU5mhLMszKSztUFmL/DesignSystem-InDrive--Copy---Copia-?node-id=4002-6948) contiene la página **Prototipo InDrive**, con los tres flujos conectados.

- **Viajes:** busca origen y destino, elige servicio, tarifa y pago, acepta una oferta y sigue el viaje en Actividad. Puedes buscar, filtrar, calificar y borrar viajes cerrados.
- **Direcciones:** guarda domicilio, trabajo u otro lugar; edítalo, bórralo o úsalo para pedir un viaje.
- **Soporte:** navega por temas, lee artículos y guarda consultas de prueba. También puedes abrir Seguridad, copiar el resumen de un viaje y guardar mensajes de demo.

Los mapas son los del prototipo. Las ofertas, el viaje, el pago y el chat se demuestran dentro de la app: no hay conductores ni cobros reales. Firebase guarda los registros de cada cuenta.

## Ejecutar en Android

El proyecto Firebase se llama **indrive26** (ID `app-flutter-20261019-4d8a`). Su app Android es `com.example.app_moviles` y usa Firebase Authentication (correo y Google) y Cloud Firestore. El nombre visible en Android es **InDrive**.

En un clon nuevo, instala Flutter, el SDK de Android, Node.js y las herramientas de Firebase. Inicia sesión con una cuenta que tenga acceso al proyecto:

```sh
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
export PATH="$PATH:$HOME/.pub-cache/bin"
flutter pub get
flutterfire configure --project=app-flutter-20261019-4d8a --platforms=android --android-package-name=com.example.app_moviles
```

Los archivos de configuración que genera FlutterFire se mantienen locales. Para usar Google en otro equipo, registra sus huellas de firma de depuración en Firebase y vuelve a ejecutar FlutterFire. El comando es `./gradlew signingReport` desde la carpeta Android; en Windows, `.\gradlew.bat signingReport`.

```sh
flutter emulators
flutter emulators --launch emulador
flutter devices
flutter run -d emulator-5554
```

Usa los identificadores que aparezcan en tu equipo. En Visual Studio Code también puedes seleccionar el emulador y presionar **F5**. Crea una cuenta de prueba con correo o usa Google en un emulador con servicios de Google.

## Comprobar la entrega

```sh
flutter analyze
flutter test
flutter build apk --debug
bash tools/probar_android.sh emulator-5554
```

La última prueba requiere Java y un emulador iniciado. Levanta Authentication y Firestore en el equipo y prueba las pantallas con datos ficticios. Las [reglas de Firestore](firestore.rules) separan las cuentas. La [guía de presentación](docs/entrega.md) relaciona la app con cada parte de la rúbrica.

Los [ejemplos del profesor](docs/referencias/README.md) se conservan para consultar su estilo. La fuente [Inter](https://github.com/rsms/inter/releases/tag/v4.1) se incluye con su licencia; el mapa y el logo provienen del referente de Figma.

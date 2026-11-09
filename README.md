# InDrive

Aplicación para organizar viajes y guardar direcciones, desarrollada para Desarrollo de Aplicaciones Móviles con [@joseSantorcuato](https://github.com/joseSantorcuato). Parte del [diseño de InDrive en Figma](https://www.figma.com/design/NYWjQGbz2z6YSUq3c5zHBV/DesignSystem-InDrive--Copy-?node-id=286-14332). La [copia de trabajo](https://www.figma.com/design/rRx9CyU5mhLMszKSztUFmL/DesignSystem-InDrive--Copy---Copia-?node-id=4002-6948) contiene la página **Prototipo InDrive**, con los tres flujos conectados.

- Busca origen y destino, consulta el recorrido por calles y registra tu viaje en Actividad. Puedes buscar, filtrar, calificar y borrar viajes cerrados.
- Guarda domicilio, trabajo u otro lugar. Luego puedes editarlo, eliminarlo o usarlo al elegir un destino.
- Lee artículos en Soporte y guarda consultas en tu cuenta. También puedes abrir Seguridad, copiar el resumen de un viaje y guardar notas.

Firebase guarda los registros de cada cuenta. Las ofertas son opciones predefinidas de la app, el estado del viaje se actualiza manualmente y el medio de pago se guarda como preferencia del viaje.

## Mapa y rutas

El mapa se abre en el sector de la Universidad del Desarrollo. `flutter_map` muestra las imágenes del mapa de OpenStreetMap y permite mover y acercar la vista. `geocoding` usa el servicio de Android para ubicar las direcciones ingresadas. La vista previa y el detalle marcan el origen y el destino que elegiste y muestran el recorrido en auto que calcula el servicio de rutas. La función requiere conexión a internet y se limita a consultar el trayecto en el mapa. [Atribución de OpenStreetMap](https://www.openstreetmap.org/copyright) · [Política de uso de imágenes del mapa](https://operations.osmfoundation.org/policies/tiles/)

Para calcular una ruta, la app envía las coordenadas de ambos puntos al servidor de Open Source Routing Machine (OSRM) operado por FOSSGIS. El servidor registra las peticiones. [Política de uso y privacidad del servidor](https://routing.openstreetmap.de/about.html)

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

Usa los identificadores que aparezcan en tu equipo. En Visual Studio Code también puedes seleccionar el emulador y presionar **F5**. Puedes crear una cuenta con correo o iniciar sesión con Google en un emulador con servicios de Google.

## Comprobar la entrega

```sh
flutter analyze
flutter test
flutter build apk --debug
bash tools/probar_android.sh emulator-5554
```

La última prueba requiere Java y un emulador iniciado. Levanta Authentication y Firestore en el equipo y prueba las pantallas con datos ficticios. Las [reglas de Firestore](firestore.rules) separan las cuentas. La [guía de presentación](docs/entrega.md) relaciona la app con cada parte de la rúbrica.

Los [ejemplos del profesor](docs/referencias/README.md) se conservan para consultar su estilo. La fuente [Inter](https://github.com/rsms/inter/releases/tag/v4.1) se incluye con su licencia. El logo proviene del diseño de Figma.

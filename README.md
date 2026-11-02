# appMoviles
Repo para el ramo Desarrollo De App Móviles con [@joseSantorcuato](https://github.com/joseSantorcuato)

Este repositorio es la base de la app. Los cambios se incorporan sobre el ejemplo del profesor y se guardan en `main`.

## Referencias de programación

Los [ejemplos originales y la guía de estilo](docs/referencias/README.md) quedan disponibles para consultarlos al desarrollar la app. Mantendremos el estilo simple de esos ejemplos.

## Configurar Firebase en un clon nuevo

La app Android usa el proyecto **APP Flutter** (`app-flutter-20261019-4d8a`) y el paquete `com.example.app_moviles`. `firebase_core` y `cloud_firestore` ya están declarados en las dependencias.

Con Flutter y Node.js/npm instalados, prepara las herramientas e inicia sesión con una cuenta que tenga acceso al proyecto:

```sh
npm install -g firebase-tools
npx -y firebase-tools@latest login
dart pub global activate flutterfire_cli
```

En macOS, si la terminal no reconoce `flutterfire`, agrega esta línea a `~/.zshrc` y ejecuta `source ~/.zshrc`:

```sh
export PATH="$PATH:$HOME/.pub-cache/bin"
```

Desde la carpeta del repositorio, genera la configuración Android:

```sh
flutter pub get
flutterfire configure --project=app-flutter-20261019-4d8a --platforms=android --android-package-name=com.example.app_moviles
```

Este comando genera `lib/firebase_options.dart` y `android/app/google-services.json`. Ambos archivos se mantienen locales y están ignorados por Git. Cada clon debe ejecutar la configuración de FlutterFire antes de analizar o ejecutar la app.

La base de datos Firestore todavía no está creada; tampoco hay reglas ni operaciones para crear, leer, actualizar o eliminar datos.

Referencia: [configuración oficial de Firebase para Flutter](https://firebase.google.com/docs/flutter/setup).

## Autenticación y huellas Android

`firebase_auth` y `google_sign_in` ya están agregados. Los comandos para incorporarlos son:

```sh
flutter pub add firebase_auth
flutter pub add google_sign_in
```

Para obtener SHA-1 y SHA-256, abre la carpeta `android` desde la raíz del proyecto y ejecuta el reporte de firma. En macOS o Linux:

```sh
cd android
./gradlew signingReport
```

En Windows (PowerShell):

```powershell
cd android
.\gradlew.bat signingReport
```

Las huellas de depuración obtenidas en esta máquina están en [android-sha-debug.txt](docs/android-sha-debug.txt). La variante `release` actualmente usa la misma firma `debug`; estas huellas no corresponden a un certificado de producción.

Después, vuelve a la raíz del proyecto y ejecuta otra vez el comando `flutterfire configure` de la sección anterior para actualizar los archivos locales.

El inicio de sesión todavía no está implementado en la interfaz. Al implementarlo, habrá que verificar que Google esté habilitado en Firebase Authentication y que las huellas estén registradas en la app Android; si faltan, agregarlas y volver a configurar FlutterFire. Consulta la [guía de Google para Flutter](https://firebase.google.com/docs/auth/flutter/federated-auth#google).

## Ejecutar en Android

Necesitas Flutter, el SDK de Android y un emulador Android configurado. Desde la carpeta del proyecto, instala las dependencias:

```sh
flutter pub get
```

Lista los emuladores disponibles e inicia uno usando su identificador:

```sh
flutter emulators
flutter emulators --launch <id>
```

Reemplaza `<id>` por el identificador mostrado en la lista. Espera a que Android termine de iniciar.

En VS Code, selecciona el emulador Android en el selector de dispositivos y presiona **F5**. También puedes ejecutar desde la terminal:

```sh
flutter devices
flutter run -d <id_del_dispositivo>
```

Usa el identificador Android que muestra `flutter devices`. Si solo hay un dispositivo disponible, basta con `flutter run`.

## Validar y subir cambios

Antes de guardar un cambio, revisa que la app funcione y ejecuta el análisis:

```sh
flutter analyze
```

Si el proyecto tiene pruebas, ejecuta también `flutter test`. Para cambios de interfaz o comportamiento, compruébalos en Android.

Revisa los archivos modificados y el diff antes de preparar el commit:

```sh
git status
git diff
```

Agrega los archivos correspondientes al cambio con `git add`, revisa `git diff --cached` y guarda una descripción clara:

```sh
git commit -m "Describe el cambio realizado"
git push origin main
```

No subas compilaciones, cachés, credenciales ni claves de firma. No uses force push ni reescribas el historial compartido.

# appMoviles
Repo para el ramo Desarrollo De App Móviles con [@joseSantorcuato](https://github.com/joseSantorcuato)

Este repositorio es la base de la app. Los cambios se incorporan sobre el ejemplo del profesor y se guardan en `main`.

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

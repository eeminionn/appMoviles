# Acuerdos de trabajo

- Este repositorio (`eeminionn/appMoviles`) es la base permanente de la app y del trabajo con el usuario.
- Conservar el ejemplo del profesor y su interfaz al incorporar cambios. Modificarlo según lo solicite el usuario, sin reemplazarlo por otra app.
- Antes de desarrollar funciones, consultar la [guía de estilo](docs/referencias/README.md) y los ejemplos originales del profesor: [list1.txt](docs/referencias/list1.txt) y [list2.txt](docs/referencias/list2.txt). Mantener su estilo simple de Flutter, sus nombres y comentarios en español y sus patrones de formularios, estado local y Firestore, adaptándolos al código existente.
- El usuario pidió no agregar cosas muy distintas a esos ejemplos. Evitar arquitectura adicional, capas, dependencias o patrones nuevos salvo que sean necesarios para la tarea o el usuario los solicite. Los ejemplos se conservan sin modificaciones como referencia; no implementar sus funciones automáticamente.
- Validar los cambios relevantes antes de subirlos. Usar `flutter analyze`, las pruebas disponibles y una ejecución en Android cuando corresponda.
- Para el trabajo autorizado por el usuario, realizar commits con mensajes claros y hacer push a `origin/main`. Revisar el diff antes de cada commit. No usar force push ni reescribir el historial.
- No incluir compilaciones, cachés, credenciales, tokens ni claves de firma. Respetar `.gitignore` y revisar los archivos que se agregan.
- Mantener `lib/firebase_options.dart` y `android/app/google-services.json` como configuración local generada por `flutterfire configure`; no versionarlos. Seguir los pasos del README al preparar otro clon.

# InDrive

[Abrir en GitHub Pages](https://eeminionn.github.io/appMoviles/) · [Abrir en Firebase Hosting](https://app-flutter-20261019-4d8a.web.app/) · [Guía del examen](docs/examen.md)

Aplicación para organizar viajes y guardar direcciones, desarrollada para Desarrollo de Aplicaciones Móviles con [@joseSantorcuato](https://github.com/joseSantorcuato). Parte del [diseño de InDrive en Figma](https://www.figma.com/design/NYWjQGbz2z6YSUq3c5zHBV/DesignSystem-InDrive--Copy-?node-id=286-14332). La [copia de trabajo](https://www.figma.com/design/rRx9CyU5mhLMszKSztUFmL/DesignSystem-InDrive--Copy---Copia-?node-id=4002-6948) contiene la página **Prototipo InDrive**, con los tres flujos conectados.

- Busca direcciones de Chile para el origen o destino, vuelve a usar tus búsquedas recientes y consulta el recorrido por calles. Puedes buscar, filtrar, calificar y borrar viajes cerrados en Actividad.
- Guarda domicilio, trabajo u otro lugar. Luego puedes editarlo, eliminarlo o usarlo al elegir un destino.
- Lee artículos en Soporte y guarda consultas en tu cuenta. También puedes abrir Seguridad, copiar el resumen de un viaje y guardar notas.
- Al registrarte, guarda nombre, apellido, edad y correo en tu perfil. Puedes consultar y editar tus datos desde Perfil. Las cuentas anteriores y de Google completan sus datos antes de entrar.

Firebase guarda los registros de cada cuenta y actualiza sus búsquedas recientes y pagos frecuentes. Los pagos frecuentes se ordenan por la cantidad de solicitudes guardadas con cada método desde que se habilitó esta función. Las ofertas son opciones predefinidas de la app y el estado del viaje se actualiza manualmente.

## Mapa y rutas

El mapa usa Google Maps y se abre en el sector de la Universidad del Desarrollo, con un punto azul fijo en el campus. La vista previa y el detalle marcan el origen y el destino que elegiste y muestran el recorrido en auto. En otro equipo, configura una clave propia restringida al paquete Android y su firma en la propiedad local `google.maps.apiKey` de Android o en la variable de entorno `GOOGLE_MAPS_API_KEY`. [Configuración de Google Maps](https://developers.google.com/maps/flutter-package/config)

Al pulsar **Buscar dirección**, InDrive envía el texto a Photon, que consulta datos de OpenStreetMap. La búsqueda también puede recurrir al servicio de direcciones de Android. La disponibilidad y los resultados dependen de la conexión y de la cobertura de los proveedores. [Servicio de búsqueda Photon](https://github.com/komoot/photon#demo-server)

Para calcular una ruta, la app envía las coordenadas de ambos puntos al servidor de Open Source Routing Machine (OSRM) operado por FOSSGIS. El servidor registra las peticiones. [Política de uso y privacidad del servidor](https://routing.openstreetmap.de/about.html)

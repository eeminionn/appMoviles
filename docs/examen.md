# Examen de Desarrollo de Aplicaciones Móviles

InDrive permite organizar una solicitud de viaje desde una sola pantalla de inicio. La persona puede buscar un destino, entender el recorrido, proponer una tarifa y revisar sus solicitudes. Las direcciones guardadas y las preferencias frecuentes reducen los pasos al volver a pedir un viaje.

- [Código en GitHub](https://github.com/eeminionn/appMoviles)
- [Versión web en GitHub Pages](https://eeminionn.github.io/appMoviles/)
- [Versión web en Firebase Hosting](https://app-flutter-20261019-4d8a.web.app/)
- [Diseño de referencia en Figma](https://www.figma.com/design/NYWjQGbz2z6YSUq3c5zHBV/DesignSystem-InDrive--Copy-?node-id=286-14332)
- [Prototipo navegable en Figma](https://www.figma.com/design/rRx9CyU5mhLMszKSztUFmL/DesignSystem-InDrive--Copy---Copia-?node-id=4002-6948)

## Investigación y decisiones

- **Referente directo formal y funcional.** inDrive organiza el viaje con campos de origen y destino, tarifa propuesta y elección entre ofertas. Su comunicación enfatiza que la persona puede decidir cuánto ofrecer. [Flujo de viajes urbanos de inDrive](https://indrive.com/city-rides)
- **Referente directo funcional y comunicacional.** Uber guía el flujo con una pregunta corta para el destino, accesos a lugares guardados y confirmación del punto de recogida. [Cómo solicitar un viaje en Uber](https://help.uber.com/riders/article/how-to-request-a-ride?nodeId=e9862b49-81c6-4c6a-a9d3-3c05bf42e82e)
- **Referente indirecto formal y funcional.** Google Maps separa los campos de origen y destino y distingue el recorrido con una línea sobre el mapa. [Cómo obtener indicaciones en Google Maps](https://support.google.com/maps/answer/144339?hl=es)

La propuesta combina un mapa para orientarse y un panel inferior que presenta las decisiones en orden. Las tarjetas, el buscador y la barra inferior conservan la composición del prototipo. El formulario de direcciones combina etiquetas reconocibles, vista previa del lugar y confirmación antes de borrar.

| Rol | Tareas |
|---|---|
| Diseño de interfaz | Definir el problema, revisar referentes y documentar flujos, componentes y estados en Figma. |
| Desarrollo | Implementar vistas Flutter, conectar autenticación y Firestore, integrar mapa y preparar ambas compilaciones. |
| Validación y presentación | Probar navegación y persistencia, contrastar el resultado con el prototipo y mostrar las versiones con sus enlaces. |

## Evidencia por indicador

| Indicador | Dónde mostrarlo |
|---|---|
| 1–4. Concepto, referentes, roles y propuesta formal | Enunciado y decisiones de la sección anterior. |
| 5. Prototipo y comparación | Mostrar las conexiones entre pantallas en la lámina de Figma y recorrer el flujo en el prototipo navegable. |
| 6. Guía de estilos | Abrir el [tema de Flutter](../lib/theme/theme.dart) y mostrar los tokens de la tabla siguiente. |
| 7. Componentes y navegación | Buscador, tarjetas de servicio, panel inferior y barra de navegación. Desde Inicio se abre un viaje o Mis direcciones. La barra lleva a Actividad, Mensajes y Perfil. |
| 8. Cuatro pantallas | Inicio de sesión, Inicio, formulario de dirección y Detalle del viaje. |
| 9. Pantalla inicial con isotipo | Abrir InDrive desde el lanzador de Android o recargar la versión web. |
| 10. Diagramación y componentes | Comparar mapa arriba, panel redondeado, buscador, tarjetas en dos columnas y barra inferior con Inicio en Figma. |
| 11–12. Color y escala tipográfica | Revisar `AppColors` y `AppTypography` en el tema. Las pantallas aplican esos valores mediante `Theme.of(context)` y los tokens de color. |
| 13. Acceso con Google | Pulsar **Continuar con Google** y completar el perfil si es el primer acceso. |
| 14. Crear, consultar, editar y eliminar | Abrir **Mis direcciones** y recorrer las cuatro operaciones con una dirección de ejemplo. |
| 15. Icono de lanzamiento | Mostrar el isotipo verde en el lanzador de Android. |
| 16. Compilación y pruebas | Usar los comandos de la sección de verificación. |
| 17. Código en GitHub | Abrir el enlace al repositorio. |
| 18. Despliegue web | Abrir Firebase Hosting para el requisito de alojamiento de Google. GitHub Pages ofrece otro enlace a la app. |
| 19. Equivalencia con Android | Mostrar Google, mapa, CRUD de direcciones y viajes con la misma cuenta en Android y web. |

| Grupo de tokens | Valores y uso |
|---|---|
| `AppTypography` | Inter, pesos 400, 500 y 700. Títulos 34, 24, 20, 18 y 14. Cuerpo 16, 14 y 12. Etiquetas 14, 12 y 10. La escala incluye el espaciado entre letras. |
| `AppColors` | Acción verde `#0A7A2E`, acento azul `#3870D2`, selección `#D8F5C8`, texto `#111827`, blanco `#FFFFFF` y error `#D41515`. |
| `AppSpacing` | Escala de 2 a 72 para márgenes, relleno y separación. El inicio usa 20 en los márgenes laterales y 16 entre tarjetas. |
| `AppRadius` | Tarjeta 20, botón 12 y panel inferior 23. |
| `AppSize` | Elevación 0 en barras, 2 en tarjetas y controles del mapa, y 3 en el panel inferior. |

## Demostración de diez minutos

1. **0:00–1:30** Explica el problema, la propuesta, los referentes y las tareas del proyecto.
2. **1:30–3:00** Abre los componentes y la navegación del prototipo. Relaciona Inter, la paleta y el espaciado con el tema Flutter.
3. **3:00–4:00** Inicia la app desde su icono. Muestra el isotipo, el acceso con Google y la pantalla Inicio.
4. **4:00–6:30** Busca una dirección, guárdala, vuelve a abrirla, edítala y elimínala. La lista se actualiza desde Firestore.
5. **6:30–8:15** Busca el Palacio de La Moneda, revisa el trayecto, guarda una solicitud y abre su detalle desde Actividad. Las ofertas son opciones predefinidas.
6. **8:15–9:00** Abre la versión web y muestra los datos de la misma cuenta. Comparte el enlace de la app y el del repositorio.
7. **9:00–10:00** Muestra en Figma qué interacción conecta cada pantalla y recorre una de esas transiciones en la aplicación.

## Verificación técnica

Con la configuración local de Firebase y de Google Maps, ejecuta `flutter analyze`, `flutter test` y `flutter build apk --debug`. Para regenerar la configuración de Firebase del proyecto, usa `flutterfire configure --project=app-flutter-20261019-4d8a --platforms=android,web`. La configuración Android de Maps se toma de `google.maps.apiKey` en `android/local.properties` o de `GOOGLE_MAPS_API_KEY` en el entorno.

El [flujo de GitHub Actions](../.github/workflows/pages.yml) compila con la ruta base de Pages y publica los archivos de Flutter Web. El mapa usa Google Maps en ambas plataformas, con un punto azul fijo en la Universidad del Desarrollo. La búsqueda de direcciones usa Photon y la ruta se calcula con OSRM.

# Entrega 2 · InDrive

Abre el [sistema de diseño original](https://www.figma.com/design/NYWjQGbz2z6YSUq3c5zHBV/DesignSystem-InDrive--Copy-?node-id=286-14332) y la [copia corregida](https://www.figma.com/design/rRx9CyU5mhLMszKSztUFmL/DesignSystem-InDrive--Copy---Copia-?node-id=4002-6948). En la copia, abre **Prototipo InDrive** y elige un flujo en **Presentar**. El original era de solo lectura y sus recorridos no estaban conectados. La copia conserva los originales y añade 23 marcos navegables con 47 enlaces y 3 puntos de inicio. También corrige textos de ejemplo en las copias.

| Rúbrica | Qué mostrar |
|---|---|
| Tema y estilo (5 + 5) | Un tema compartido con colores, tipografía y formas; las pantallas usan el tema y las constantes de medidas. |
| Diagramación (5) | Mapa arriba, hoja blanca redondeada, buscador, tarjetas en dos columnas y barra inferior. Abrir el menú lateral y comparar con el marco de 360 × 800. |
| Tipografía (3) | Inter incluida en el proyecto. Comparar títulos de 24, textos de 16 y 14, y pies de 12. |
| Color (5) | Verde de marca y selección menta, blanco, grises y azul del sistema. Mostrar variables de color en Figma y su uso en la app. |
| Componentes (5) | Buscador ovalado, hojas, tarjetas, selector de servicio, pago y fila de dirección con lápiz. |
| Flujos e interacción (5 + 5) | Pedir viaje → ruta → tarifa → pago → oferta → confirmación. Menú → Mis direcciones → buscar → mapa → guardar. Menú → Soporte → Ciudad → Mi perfil → Comunicación. |
| Funcionalidades (10 + 10) | Mostrar el recorrido por calles entre dos direcciones. Explicar cómo se aplican a viajes y direcciones los formularios y listas en tiempo real del ejemplo del profesor. Mostrar Soporte y las notas del viaje. |
| Compilación (10) | Ejecutar en el emulador Android con internet y recorrer los tres flujos. Mostrar el Figma junto a la app y explicar la relación. |
| Entrega (5) | En Android se llama **InDrive**. Usar el [repositorio GitHub](https://github.com/eeminionn/appMoviles) como enlace de entrega en Canvas UDD. |
| Presentación y Firebase (5) | Usar solo Figma y el emulador, en menos de 10 minutos. Abrir la configuración del proyecto **indrive26** y mostrar el acceso del profesor si se solicita. |

## Recorrido de 8:45 sin diapositivas

1. **0:00–0:30.** Presenta InDrive como una aplicación para organizar viajes y guardar direcciones.
2. **0:30–2:10.** Muestra en Figma Inter, la paleta y los componentes. Abre los tres puntos de inicio.
3. **2:10–3:00.** En Android, abre InDrive e inicia sesión. Muestra el punto azul fijo de la Universidad del Desarrollo. Mueve el mapa y pulsa **Centrar en la UDD** para volver al campus. Muestra el menú y las pestañas.
4. **3:00–5:30.** Elige la Universidad del Desarrollo como origen y Mallplaza Los Dominicos como destino. Muestra los marcadores y la ruta por calles. Cambia la tarifa, guarda una preferencia de pago, elige una oferta y actualiza el estado del viaje. Filtra en Actividad y califícalo.
5. **5:30–6:55.** Guarda una dirección, edítala, vuelve a verla y úsala al buscar destino. Muestra el borrado con confirmación.
6. **6:55–8:00.** Abre Comunicación desde Soporte y registra una consulta. Señala Mensajes y Seguridad.
7. **8:00–8:45.** Explica cómo se guardan los datos por usuario, muestra GitHub y deja lista la URL para Canvas.

Las ofertas son opciones predefinidas de la app. El estado y el medio de pago quedan guardados en el historial de la cuenta. La [descripción del mapa](../README.md#mapa-y-rutas) indica qué servicios usa y qué datos se envían al consultar un recorrido.

## Validación realizada

- Análisis de Flutter sin observaciones y pruebas del formulario de inicio de sesión aprobadas.
- Comprobación en Android de las calles, los marcadores de origen y destino y el recorrido entre la Universidad del Desarrollo y Metro Salvador.
- Compilación e instalación de la app Android. La prueba de extremo a extremo en el emulador cubre registro, edición y borrado de direcciones, consultas, ofertas, cambios de estado del viaje, calificación, notas, filtros y cierre de sesión.
- La validación de Firebase usa datos ficticios y servidores locales. Las reglas también pasaron 62 comprobaciones y se publicaron en el proyecto **indrive26**, donde el profesor ya tiene acceso.

La entrega se registra como **URL web** en [ENTREGA CERTAMEN 2 de Canvas UDD](https://udd.instructure.com/courses/78364/assignments/555975).

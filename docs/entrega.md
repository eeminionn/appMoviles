# Entrega 2 · InDrive

Abre el [sistema de diseño original](https://www.figma.com/design/NYWjQGbz2z6YSUq3c5zHBV/DesignSystem-InDrive--Copy-?node-id=286-14332) y la [copia corregida](https://www.figma.com/design/rRx9CyU5mhLMszKSztUFmL/DesignSystem-InDrive--Copy---Copia-?node-id=4002-6948). En la copia, abre **Prototipo InDrive** y elige un flujo en **Presentar**. El original era de solo lectura y sus recorridos no estaban conectados. La copia conserva los originales y añade 23 marcos navegables con 47 enlaces y 3 puntos de inicio. También corrige textos de ejemplo en las copias.

| Rúbrica | Qué mostrar |
|---|---|
| Tema y estilo (5 + 5) | Un tema compartido con colores, tipografía y formas; las pantallas usan el tema y las constantes de medidas. |
| Diagramación (5) | Inicio: mapa arriba, hoja blanca redondeada, buscador, tarjetas en dos columnas y barra inferior. Abrir el menú lateral y comparar con el marco de 360 × 800. |
| Tipografía (3) | Inter incluida en el proyecto. Comparar títulos de 24, textos de 16 y 14, y pies de 12. |
| Color (5) | Verde de marca y selección menta, blanco, grises y azul del sistema. Mostrar variables de color en Figma y su uso en la app. |
| Componentes (5) | Buscador ovalado, hojas, tarjetas, selector de servicio, pago y fila de dirección con lápiz. |
| Flujos e interacción (5 + 5) | Pedir viaje → ruta → tarifa → pago → oferta → confirmación. Menú → Mis direcciones → buscar → mapa → guardar. Menú → Soporte → Ciudad → Mi perfil → Comunicación. |
| Funcionalidades (10 + 10) | Mostrar cómo el ejemplo del profesor usa formularios y listas en tiempo real. En InDrive se aplican a viajes y direcciones, con edición, borrado confirmado, búsqueda, filtros y calificación. Mostrar Soporte y mensajes de demo. |
| Compilación (10) | Ejecutar en el emulador Android y probar los tres flujos. Mostrar el Figma junto a la app y explicar la relación. |
| Entrega (5) | En Android se llama **InDrive**. Usar el [repositorio GitHub](https://github.com/eeminionn/appMoviles) como enlace de entrega en Canvas UDD. |
| Presentación y Firebase (5) | Usar solo Figma y el emulador, en menos de 10 minutos. Abrir la configuración del proyecto **indrive26** y mostrar el acceso del profesor si se solicita. |

## Recorrido de 8:45 sin diapositivas

1. **0:00–0:30.** Explica que es un prototipo académico para pasajeros.
2. **0:30–2:10.** Muestra en Figma Inter, la paleta y los componentes. Abre los tres puntos de inicio.
3. **2:10–3:00.** En Android, abre InDrive, inicia sesión y muestra mapa, menú y pestañas.
4. **3:00–5:30.** Pide un viaje de demo, cambia la tarifa, elige el pago, acepta una oferta y completa el viaje. Filtra en Actividad y califícalo.
5. **5:30–6:55.** Guarda una dirección, edítala, vuelve a verla y úsala al buscar destino. Muestra el borrado con confirmación.
6. **6:55–8:00.** Abre Comunicación desde Soporte y registra una consulta de prueba. Señala Mensajes y Seguridad.
7. **8:00–8:45.** Explica cómo se guardan los datos por usuario, muestra GitHub y deja lista la URL para Canvas.

Ensaya con una cuenta propia o ficticia. Las ofertas son simuladas y no se cobra ni se envía nada a conductores reales.

## Validación realizada

- Análisis de Flutter sin observaciones y pruebas del formulario de inicio de sesión aprobadas.
- Compilación e instalación de la app Android. Prueba de extremo a extremo en el emulador: registro, dirección creada/editada/borrada, consulta, oferta, viaje completado, calificación, chat, filtros y cierre de sesión.
- La prueba usa datos ficticios y servidores locales. Las reglas también pasaron 62 comprobaciones y se publicaron en el proyecto **indrive26**, donde el profesor ya tiene acceso.

La entrega se registra como **URL web** en [ENTREGA CERTAMEN 2 de Canvas UDD](https://udd.instructure.com/courses/78364/assignments/555975).

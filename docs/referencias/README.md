# Ejemplos del profesor

El usuario entregó estos archivos como referencias para el estilo de programación de la app. Se conservan sin cambios y con extensión `.txt` para consultarlos sin incorporarlos al código que se ejecuta.

- [list1.txt](list1.txt): vista de canciones con consulta en tiempo real y formulario para agregar registros en Firestore.
- [list2.txt](list2.txt): amplía el mismo ejemplo con un formulario compartido para crear o editar, y un diálogo de confirmación antes de eliminar.

## Estilo que debemos mantener

- Vistas con `StatefulWidget` y métodos sencillos dentro de su `State`; nombres de variables, métodos y comentarios explicativos en español, siguiendo los ejemplos.
- Widgets de Material, como `Scaffold`, `AppBar`, `ListView.builder`, `ListTile` y `FloatingActionButton`.
- Tema compartido mediante `Theme.of(context)`, `AppSpacing` y `AppRadius`.
- Formularios con `TextEditingController`, liberados en `dispose`, `GlobalKey<FormState>` y validación con `TextFormField`.
- Formularios en `showModalBottomSheet` con `StatefulBuilder` para el estado local de guardado; botones desactivados mientras se guarda e indicador de progreso.
- Consultas de Firestore con `StreamBuilder` y estados explícitos de carga, error y lista vacía. Operaciones de guardado con `async`/`await`, `try`/`catch`, comprobaciones de `mounted` y mensajes con `SnackBar`.
- Para crear y editar datos similares, tomar como referencia el formulario reutilizado de `list2.txt`; para eliminar, su diálogo de confirmación.

Antes de desarrollar nuevas funciones, consultar los ejemplos y adaptar lo necesario al código existente. Mantener soluciones simples y cercanas a lo enseñado por el profesor. Agregar arquitectura, capas, dependencias o patrones distintos solo si la tarea lo necesita o el usuario lo solicita.

Estos archivos son referencias: guardarlos no activa las funciones de canciones ni obliga a copiar literalmente cada detalle. Las rutas de imports y los recursos deben corresponder al archivo y a la app donde se usen.

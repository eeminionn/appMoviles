// Ejecutar con Node dentro de Firebase Emulator Suite (Auth y Firestore).
// Usa usuarios desechables del proyecto demo-indrive-local y no requiere paquetes.
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';

const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const firestoreHost = process.env.FIRESTORE_EMULATOR_HOST;
const esLocal = (host) => /^127\.0\.0\.1:[1-9]\d{0,4}$/.test(host ?? '');
assert.ok(esLocal(authHost) && esLocal(firestoreHost), 'Inicia ambos emuladores en 127.0.0.1.');

const proyecto = 'demo-indrive-local';
const documentos = `projects/${proyecto}/databases/(default)/documents`;
const base = `http://${firestoreHost}/v1/${documentos}`;
let pruebas = 0;

async function pedir(url, metodo, token, datos) {
  return fetch(url, {
    method: metodo,
    headers: {
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(datos ? { 'Content-Type': 'application/json' } : {}),
    },
    body: datos ? JSON.stringify(datos) : undefined,
    redirect: 'error',
  });
}

async function comprobar(caso, peticion, esperado) {
  const respuesta = await peticion;
  assert.equal(respuesta.status, esperado, caso);
  pruebas++;
  return respuesta;
}

async function usuario() {
  const url = `http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=local-only`;
  const respuesta = await pedir(url, 'POST', null, {
    email: `reglas-${randomUUID()}@example.test`,
    password: 'prueba-local-26',
    returnSecureToken: true,
  });
  assert.equal(respuesta.status, 200, 'Auth debe crear un usuario de prueba local.');
  const { idToken, localId } = await respuesta.json();
  assert.ok(idToken && localId, 'Auth debe devolver UID y token local.');
  return { token: idToken, ruta: `usuarios/${localId}` };
}

function campos(datos) {
  return Object.fromEntries(Object.entries(datos).map(([nombre, valor]) => {
    if (typeof valor === 'string') return [nombre, { stringValue: valor }];
    if (typeof valor === 'boolean') return [nombre, { booleanValue: valor }];
    if (Number.isInteger(valor)) return [nombre, { integerValue: String(valor) }];
    if (typeof valor === 'number') return [nombre, { doubleValue: valor }];
    return [nombre, valor]; // Valor Firestore explícito, como timestampValue.
  }));
}

const horaServidor = [{ fieldPath: 'creadoEn', setToServerValue: 'REQUEST_TIME' }];
const guardar = (ruta, datos) => ({ update: { name: `${documentos}/${ruta}`, fields: campos(datos) } });
const alta = (ruta, datos, conHoraServidor = true) => ({
  ...guardar(ruta, datos), currentDocument: { exists: false },
  ...(conHoraServidor ? { updateTransforms: horaServidor } : {}),
});
const cambio = (ruta, datos, fieldPaths = Object.keys(datos)) => ({
  ...guardar(ruta, datos), currentDocument: { exists: true }, updateMask: { fieldPaths },
});
const baja = (ruta) => ({ delete: `${documentos}/${ruta}` });
const escribir = (actor, ...writes) => pedir(`${base}:commit`, 'POST', actor?.token, { writes });
const leer = (actor, ruta) => pedir(`${base}/${ruta}`, 'GET', actor?.token);
const listo = (caso, peticion) => comprobar(caso, peticion, 200);
const denegado = (caso, peticion) => comprobar(caso, peticion, 403);

const [ana, bea] = await Promise.all([usuario(), usuario()]);
const rutaViaje = `${ana.ruta}/viajes/principal`;
const rutaViajeBea = `${bea.ruta}/viajes/solo-bea`;
const rutaDireccion = `${ana.ruta}/direcciones/domicilio`;
const rutaConsulta = `${ana.ruta}/consultas/soporte`;
const rutaMensaje = `${ana.ruta}/mensajes/primero`;
const viaje = {
  origen: 'Campus UDD', destino: 'Plaza del barrio', servicio: 'Ciudad',
  pago: 'Efectivo', tarifa: 3500, autoAceptar: false,
  estado: 'buscando', conductor: '', calificacion: 0,
};
const direccion = { nombre: 'Mi casa', direccion: 'Calle de ejemplo 123', tipo: 'Domicilio' };
const consulta = { tema: 'Comunicación', mensaje: 'Es una consulta local de prueba.' };
const mensaje = { viajeId: 'principal', texto: 'Hola, estoy en la entrada.' };
const punto = { geoPointValue: { latitude: -33.3916042, longitude: -70.5005107 } };

await listo('Ana crea un viaje', escribir(ana, alta(rutaViaje, viaje)));
await listo('Bea crea su propio viaje', escribir(bea, alta(rutaViajeBea, viaje)));
await listo('Ana lee su viaje', leer(ana, rutaViaje));
await listo('Ana lista sus viajes por fecha', leer(ana, `${ana.ruta}/viajes?orderBy=creadoEn%20desc`));
await denegado('Lista sin sesión', leer(null, `${ana.ruta}/viajes`));
await denegado('Lectura cruzada', leer(bea, rutaViaje));
await denegado('Lista cruzada', leer(bea, `${ana.ruta}/viajes`));
await denegado('Creación bajo otro UID', escribir(bea, alta(`${ana.ruta}/viajes/intruso`, viaje)));
await denegado('Edición cruzada', escribir(bea, cambio(rutaViaje, { tarifa: 4000 })));
await denegado('Borrado cruzado', escribir(bea, baja(rutaViaje)));
await denegado('Perfil con privilegios fuera del esquema', escribir(ana, alta(ana.ruta, { rol: 'admin' })));
await denegado('Ruta ajena al modelo', escribir(ana, alta('viajes/otro', viaje)));

const viajeNuevo = `${ana.ruta}/viajes/validacion`;
const { destino: _destino, ...sinDestino } = viaje;
for (const [caso, datos] of [
  ['Falta destino', sinDestino],
  ['Añade un UID arbitrario', { ...viaje, uid: bea.ruta }],
  ['Origen de tipo incorrecto', { ...viaje, origen: 30 }],
  ['Tarifa fuera de rango', { ...viaje, tarifa: 200001 }],
  ['Tarifa decimal', { ...viaje, tarifa: 3500.5 }],
  ['Tarifa negativa', { ...viaje, tarifa: -5 }],
  ['Servicio desconocido', { ...viaje, servicio: 'Otro' }],
  ['Pago desconocido', { ...viaje, pago: 'Crédito' }],
  ['Crea en estado confirmado', { ...viaje, estado: 'confirmado', conductor: 'Conductor A' }],
]) {
  await denegado(caso, escribir(ana, alta(viajeNuevo, datos)));
}
await denegado('Fecha creada por el cliente', escribir(ana, alta(viajeNuevo, {
  ...viaje, creadoEn: { timestampValue: '2000-01-01T00:00:00Z' },
}, false)));
await denegado('Fecha de tipo incorrecto', escribir(ana, alta(viajeNuevo, {
  ...viaje, creadoEn: '2000-01-01',
}, false)));
await denegado('Quita un campo obligatorio', escribir(ana, cambio(rutaViaje, {}, ['destino'])));
await denegado('Agrega un campo en la edición', escribir(ana, cambio(rutaViaje, { uid: bea.ruta })));
await denegado('Edita fecha de creación', escribir(ana, cambio(rutaViaje, {
  creadoEn: { timestampValue: '2001-01-01T00:00:00Z' },
})));
await denegado('Edita origen con valor excesivo', escribir(ana, cambio(rutaViaje, { origen: 'x'.repeat(10000) })));
await denegado('Salta directamente a completado', escribir(ana, cambio(rutaViaje, { estado: 'completado' })));
await denegado('Borra un viaje activo', escribir(ana, baja(rutaViaje)));
await listo('Edita tarifa y aceptación automática mientras busca', escribir(ana, cambio(rutaViaje, { tarifa: 4000, autoAceptar: true })));
await denegado('Confirma sin conductor', escribir(ana, cambio(rutaViaje, { estado: 'confirmado' })));
await listo('Confirma una oferta de demo', escribir(ana, cambio(rutaViaje, { estado: 'confirmado', conductor: 'Conductor A', tarifa: 4100 })));
await denegado('Cambia el conductor confirmado', escribir(ana, cambio(rutaViaje, { conductor: 'Conductor B' })));
await denegado('Califica antes de completar', escribir(ana, cambio(rutaViaje, { calificacion: 5 })));
await listo('Comienza viaje confirmado', escribir(ana, cambio(rutaViaje, { estado: 'en curso' })));
await listo('Completa viaje en curso', escribir(ana, cambio(rutaViaje, { estado: 'completado' })));
await listo('Califica viaje completado', escribir(ana, cambio(rutaViaje, { calificacion: 5 })));
await denegado('Quita calificación de un viaje cerrado', escribir(ana, cambio(rutaViaje, { calificacion: 0 })));
await denegado('Reabre un viaje cerrado', escribir(ana, cambio(rutaViaje, { estado: 'buscando' })));
await listo('Cancela un viaje en búsqueda', escribir(bea, cambio(rutaViajeBea, { estado: 'cancelado' })));

await listo('Crea domicilio en ID fijo', escribir(ana, alta(rutaDireccion, direccion)));
await denegado('Crea otro domicilio con ID distinto', escribir(ana, alta(`${ana.ruta}/direcciones/duplicado`, direccion)));
await listo('Crea otra dirección con ID automático', escribir(ana, alta(`${ana.ruta}/direcciones/a1b2c3d4e5f6g7h8i9j0`, { ...direccion, tipo: 'Otro' })));
await listo('Edita su dirección', escribir(ana, cambio(rutaDireccion, { nombre: 'Casa nueva' })));
await listo('Agrega coordenada a una dirección guardada', escribir(ana, cambio(rutaDireccion, { punto })));
await denegado('Rechaza coordenada guardada de tipo incorrecto', escribir(ana, cambio(rutaDireccion, { punto: 'UDD' })));
await listo('Quita coordenada al editar dirección', escribir(ana, cambio(rutaDireccion, {}, ['punto'])));
await denegado('Nombre de dirección excesivo', escribir(ana, cambio(rutaDireccion, { nombre: 'a'.repeat(41) })));
await denegado('Otra cuenta no lee el domicilio', leer(bea, rutaDireccion));
await listo('Borra su domicilio', escribir(ana, baja(rutaDireccion)));

await listo('Guarda su consulta de soporte', escribir(ana, alta(rutaConsulta, consulta)));
await denegado('No edita consultas', escribir(ana, cambio(rutaConsulta, { tema: 'Otro tema' })));
await denegado('No lee consultas de otra cuenta', leer(bea, rutaConsulta));
await listo('Envía mensaje asociado a su propio viaje', escribir(ana, alta(rutaMensaje, mensaje)));
await denegado('No edita mensajes', escribir(ana, cambio(rutaMensaje, { texto: 'Texto modificado' })));
await denegado('No lee mensajes de otra cuenta', leer(bea, rutaMensaje));
await denegado('Rechaza viaje de otra cuenta', escribir(ana, alta(`${ana.ruta}/mensajes/cruzado`, { ...mensaje, viajeId: 'solo-bea' })));
await denegado('Rechaza viajeId con una ruta', escribir(ana, alta(`${ana.ruta}/mensajes/traversal`, { ...mensaje, viajeId: `${bea.ruta}/viajes/solo-bea` })));
await denegado('Rechaza mensaje excesivo', escribir(ana, alta(`${ana.ruta}/mensajes/extenso`, { ...mensaje, texto: 'x'.repeat(281) })));

const filtroMensaje = { structuredQuery: {
  from: [{ collectionId: 'mensajes' }],
  where: { fieldFilter: { field: { fieldPath: 'viajeId' }, op: 'EQUAL', value: { stringValue: 'principal' } } },
} };
const consultaMensajes = `${base}/${ana.ruta}:runQuery`;
const resultado = await listo('El filtro por viaje funciona para la dueña', pedir(consultaMensajes, 'POST', ana.token, filtroMensaje));
assert.equal((await resultado.json()).filter((fila) => fila.document).length, 1);
await denegado('El filtro por viaje no permite lectura cruzada', pedir(consultaMensajes, 'POST', bea.token, filtroMensaje));
await denegado('No crea un mensaje si borra el viaje en la misma operación', escribir(ana, baja(rutaViaje), alta(`${ana.ruta}/mensajes/huerfano`, mensaje)));
await listo('Borra su viaje cerrado', escribir(ana, baja(rutaViaje)));
await denegado('No crea mensajes de un viaje borrado', escribir(ana, alta(`${ana.ruta}/mensajes/posterior`, mensaje)));
await listo('Limpia un mensaje existente de un viaje borrado', escribir(ana, baja(rutaMensaje)));

const rutaBusqueda = `${ana.ruta}/busquedasRecientes/avenida-ejemplo`;
const busqueda = (datos, ruta = rutaBusqueda) => ({
  ...guardar(ruta, datos),
  updateTransforms: [{ fieldPath: 'buscadoEn', setToServerValue: 'REQUEST_TIME' }],
});
const consultaDireccion = { consulta: 'Avenida Ejemplo' };
await listo('Guarda una búsqueda reciente', escribir(ana, busqueda(consultaDireccion)));
await listo('Asocia una dirección encontrada a la búsqueda', escribir(ana, busqueda({
  ...consultaDireccion, direccion: 'Avenida Ejemplo 20', punto,
})));
await listo('Lista búsquedas por fecha', leer(ana, `${ana.ruta}/busquedasRecientes?orderBy=buscadoEn%20desc`));
await denegado('No lista búsquedas sin sesión', leer(null, `${ana.ruta}/busquedasRecientes`));
await denegado('No lee una búsqueda de otra cuenta', leer(bea, rutaBusqueda));
await denegado('No cambia una búsqueda de otra cuenta', escribir(bea, busqueda(consultaDireccion)));
await denegado('Rechaza IDs de búsqueda inválidos', escribir(ana, busqueda(consultaDireccion, `${ana.ruta}/busquedasRecientes/INVALIDO`)));
await denegado('Rechaza fecha de búsqueda elegida por cliente', escribir(ana, guardar(rutaBusqueda, {
  ...consultaDireccion, buscadoEn: { timestampValue: '2000-01-01T00:00:00Z' },
})));
for (const [caso, datos] of [
  ['Falta consulta', { direccion: 'Avenida Ejemplo 20', punto }],
  ['Rechaza consulta excesiva', { consulta: 'a'.repeat(121) }],
  ['Rechaza campos de búsqueda ajenos al esquema', { ...consultaDireccion, uid: bea.ruta }],
  ['Rechaza dirección sin coordenada', { ...consultaDireccion, direccion: 'Avenida Ejemplo 20' }],
  ['Rechaza coordenada sin dirección', { ...consultaDireccion, punto }],
  ['Rechaza coordenada mal tipada', { ...consultaDireccion, direccion: 'Avenida Ejemplo 20', punto: 10 }],
]) {
  await denegado(caso, escribir(ana, busqueda(datos)));
}

const idPrimero = 'a'.repeat(20);
const idSegundo = 'b'.repeat(20);
const rutaPrimero = `${ana.ruta}/viajes/${idPrimero}`;
const rutaSegundo = `${ana.ruta}/viajes/${idSegundo}`;
const pagoFrecuente = (ultimoViajeId, incremento = 1, metodo = 'Efectivo') => ({
  ...guardar(`${ana.ruta}/pagosFrecuentes/${metodo}`, { ultimoViajeId }),
  updateMask: { fieldPaths: ['ultimoViajeId'] },
  updateTransforms: [
    { fieldPath: 'ultimoUso', setToServerValue: 'REQUEST_TIME' },
    { fieldPath: 'usos', increment: { integerValue: String(incremento) } },
  ],
});
const rutaPago = `${ana.ruta}/pagosFrecuentes/Efectivo`;
const viajeConPuntos = { ...viaje, puntoOrigen: punto, puntoDestino: punto };
await denegado('Rechaza coordenada de viaje mal tipada', escribir(ana, alta(rutaPrimero, {
  ...viaje, puntoDestino: 'UDD',
})));
await denegado('No crea frecuencia sin viaje nuevo', escribir(ana, pagoFrecuente(idPrimero)));
await denegado('Rechaza un medio distinto al elegido en el viaje', escribir(ana,
  alta(rutaPrimero, viaje), pagoFrecuente(idPrimero, 1, 'MACH')));
await denegado('Rechaza un ID de viaje con segmentos de ruta', escribir(ana, pagoFrecuente('viajes/principal')));
await listo('Guarda viaje con coordenadas y registra su primer uso de pago', escribir(ana,
  alta(rutaPrimero, viajeConPuntos), pagoFrecuente(idPrimero)));
await denegado('No altera coordenadas de un viaje guardado', escribir(ana, cambio(rutaPrimero, {}, ['puntoOrigen'])));
await denegado('No aumenta frecuencia con un viaje ya registrado', escribir(ana, pagoFrecuente(idPrimero)));
await denegado('No aumenta frecuencia más de uno por viaje', escribir(ana,
  alta(rutaSegundo, viaje), pagoFrecuente(idSegundo, 2)));
await denegado('No cuenta el mismo viaje dos veces en el lote', escribir(ana,
  alta(rutaSegundo, viaje), pagoFrecuente(idSegundo), pagoFrecuente(idSegundo)));
await listo('Aumenta la frecuencia al guardar otro viaje', escribir(ana,
  alta(rutaSegundo, viaje), pagoFrecuente(idSegundo)));
const pagoGuardado = await listo('Lee su propia frecuencia', leer(ana, rutaPago));
assert.equal((await pagoGuardado.json()).fields.usos.integerValue, '2');
await listo('Lista sus pagos por frecuencia', leer(ana, `${ana.ruta}/pagosFrecuentes?orderBy=usos%20desc`));
await denegado('No lista pagos sin sesión', leer(null, `${ana.ruta}/pagosFrecuentes`));
await denegado('No lee frecuencias de otra cuenta', leer(bea, rutaPago));
await denegado('No escribe frecuencias de otra cuenta', escribir(bea, pagoFrecuente(idSegundo)));
await denegado('No borra una frecuencia', escribir(ana, baja(rutaPago)));

console.log(`${pruebas} comprobaciones de reglas de Firestore pasaron.`);

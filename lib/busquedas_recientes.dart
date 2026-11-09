import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import 'busqueda_direcciones.dart';
import 'datos.dart';

LatLng? leerPunto(Object? valor) =>
    valor is GeoPoint ? LatLng(valor.latitude, valor.longitude) : null;

GeoPoint guardarPunto(LatLng punto) =>
    GeoPoint(punto.latitude, punto.longitude);

class BusquedaReciente {
  const BusquedaReciente(this.consulta, this.resultado);

  final String consulta;
  final DireccionEncontrada? resultado;

  factory BusquedaReciente.desdeDatos(Map<String, dynamic> datos) {
    final punto = leerPunto(datos['punto']);
    final direccion = datos['direccion'] as String?;
    return BusquedaReciente(
      datos['consulta'] as String,
      punto != null && direccion != null
          ? DireccionEncontrada(direccion, punto)
          : null,
    );
  }
}

CollectionReference<Map<String, dynamic>> _busquedas(String uid) =>
    FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('busquedasRecientes');

Stream<List<BusquedaReciente>> escucharBusquedasRecientes(String uid) {
  return _busquedas(uid)
      .orderBy('buscadoEn', descending: true)
      .limit(5)
      .snapshots()
      .map(
        (snapshot) => [
          for (final doc in snapshot.docs)
            BusquedaReciente.desdeDatos(doc.data()),
        ],
      );
}

Future<void> guardarBusqueda(
  String uid,
  String consulta, [
  DireccionEncontrada? resultado,
]) {
  final clave = normalizar(
    consulta,
  ).replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
  final id = clave.isEmpty
      ? DateTime.now().microsecondsSinceEpoch.toString()
      : clave;
  return _busquedas(uid).doc(id).set({
    'consulta': consulta,
    'buscadoEn': FieldValue.serverTimestamp(),
    if (resultado != null) ...{
      'direccion': resultado.direccion,
      'punto': guardarPunto(resultado.punto),
    },
  }, SetOptions(merge: true));
}

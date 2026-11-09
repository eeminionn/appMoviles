import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'datos.dart';

// Campus Rector Ernesto Silva Bafalluy, Av. Plaza 680, Las Condes.
// https://www.openstreetmap.org/way/308307124
const centroMapa = LatLng(-33.3916042, -70.5005107);

const _puntosConocidos = {
  'Universidad del Desarrollo': centroMapa,
  // https://www.openstreetmap.org/node/520459156
  'Metro Salvador': LatLng(-33.4327195, -70.6260885),
  // https://www.openstreetmap.org/way/285975433
  'Renaissance Santiago Hotel': LatLng(-33.4025434, -70.5837992),
  // https://www.openstreetmap.org/way/207738085
  'Mallplaza Los Dominicos': LatLng(-33.4152017, -70.5408031),
};

const _aliasCampus = {
  'universidad del desarrollo av plaza',
  'av plaza 680 las condes',
  'avenida plaza 680 las condes',
  'avenida la plaza 680 las condes',
};

const _limiteCache = 32;
const _tiempoEspera = Duration(seconds: 6);
final _puntosGuardados = <String, LatLng>{};
final _puntosEnCurso = <String, Future<LatLng?>>{};
final _rutasGuardadas = <(LatLng, LatLng), List<LatLng>>{};
final _rutasEnCurso = <(LatLng, LatLng), Future<List<LatLng>>>{};
final _relojRutas = Stopwatch()..start();
Duration? _ultimaConsulta;
Future<void> _colaRutas = Future.value();

String _claveDireccion(String texto) =>
    normalizar(texto).replaceAll(RegExp(r'[^a-zñ0-9]+'), ' ').trim();

void _guardar<K, V>(Map<K, V> cache, K clave, V valor) {
  if (cache.length >= _limiteCache) cache.remove(cache.keys.first);
  cache[clave] = valor;
}

Future<LatLng?> buscarPunto(String direccion) async {
  final clave = _claveDireccion(direccion);
  if (clave.isEmpty) return null;
  if (_aliasCampus.contains(clave)) return centroMapa;

  final guardado = _puntosGuardados[clave];
  if (guardado != null) return guardado;

  for (final lugar in lugares.entries) {
    if (clave == _claveDireccion(lugar.key) ||
        (lugar.value.contains(RegExp(r'\d')) &&
            clave == _claveDireccion(lugar.value)) ||
        clave == _claveDireccion('${lugar.key}, ${lugar.value}')) {
      final punto = _puntosConocidos[lugar.key];
      if (punto != null) return punto;
      direccion = lugar.value;
      break;
    }
  }

  if (GeocodingPlatformFactory.instance == null) return null;

  return _puntosEnCurso[clave] ??= _buscarDireccion(direccion)
      .timeout(_tiempoEspera)
      .then(
        (punto) {
          if (punto != null) _guardar(_puntosGuardados, clave, punto);
          return punto;
        },
        onError: (Object error) {
          debugPrint('No se pudo ubicar la dirección (${error.runtimeType}).');
          return null;
        },
      )
      .whenComplete(() {
        _puntosEnCurso.remove(clave);
      });
}

Future<LatLng?> _buscarDireccion(String direccion) async {
  final geocoder = Geocoding(locale: const Locale('es', 'CL'));
  if (!await geocoder.isPresent()) return null;

  final partes = direccion.split(',');
  // Las direcciones guardadas pueden empezar por una etiqueta como «Casa».
  final indiceCalle =
      partes.length > 1 &&
          !partes.first.contains(RegExp(r'\d')) &&
          partes[1].contains(RegExp(r'\d'))
      ? 1
      : 0;
  const palabrasGenericas = {
    'avenida',
    'av',
    'calle',
    'pasaje',
    'psje',
    'de',
    'la',
    'del',
    'los',
    'las',
    'el',
  };
  final palabras = _claveDireccion(partes[indiceCalle])
      .split(' ')
      .where(
        (palabra) => palabra.isNotEmpty && !palabrasGenericas.contains(palabra),
      )
      .toList();
  if (palabras.isEmpty) return null;

  final direccionSinEtiqueta = partes.skip(indiceCalle).join(',').trim();
  final consulta =
      RegExp(r'\bchile\b').hasMatch(_claveDireccion(direccionSinEtiqueta))
      ? direccionSinEtiqueta
      : '$direccionSinEtiqueta, Chile';
  final ubicaciones = await geocoder.locationFromAddress(consulta);
  for (final ubicacion in ubicaciones.take(2)) {
    final marcas = await geocoder.placemarkFromCoordinates(
      ubicacion.latitude,
      ubicacion.longitude,
    );
    for (final marca in marcas) {
      if (marca.isoCountryCode?.toUpperCase() != 'CL') continue;
      final detalle = _claveDireccion(
        [
          marca.name,
          marca.street,
          marca.thoroughfare,
          marca.subThoroughfare,
        ].nonNulls.join(' '),
      ).split(' ').toSet();
      // Evitar poner un marcador en el centro de la comuna si no se encontró la calle.
      if (palabras.every(detalle.contains)) {
        return LatLng(ubicacion.latitude, ubicacion.longitude);
      }
    }
  }
  return null;
}

Future<List<LatLng>> buscarRuta(LatLng origen, LatLng destino) async {
  if (origen == destino) return const [];
  final clave = (origen, destino);
  final guardada = _rutasGuardadas[clave];
  if (guardada != null) return guardada;

  return _rutasEnCurso[clave] ??= _consultarRuta(origen, destino)
      .then((ruta) {
        if (ruta.isNotEmpty) _guardar(_rutasGuardadas, clave, ruta);
        return ruta;
      })
      .whenComplete(() {
        _rutasEnCurso.remove(clave);
      });
}

Future<List<LatLng>> _consultarRuta(LatLng origen, LatLng destino) {
  final consulta = _colaRutas.then((_) async {
    // El servicio de FOSSGIS permite hasta una solicitud por segundo.
    final anterior = _ultimaConsulta;
    if (anterior != null) {
      final espera =
          const Duration(seconds: 1) - (_relojRutas.elapsed - anterior);
      if (espera > Duration.zero) await Future<void>.delayed(espera);
    }
    _ultimaConsulta = _relojRutas.elapsed;
    return _descargarRuta(origen, destino);
  });
  _colaRutas = consulta.then<void>(
    (_) {},
    onError: (Object _, StackTrace _) {},
  );
  return consulta;
}

Future<List<LatLng>> _descargarRuta(LatLng origen, LatLng destino) async {
  final url = Uri.https(
    'routing.openstreetmap.de',
    '/routed-car/route/v1/driving/'
        '${origen.longitude},${origen.latitude};'
        '${destino.longitude},${destino.latitude}',
    {'overview': 'full', 'geometries': 'geojson', 'radiuses': '500;500'},
  );
  final cliente = http.Client();
  try {
    final respuesta = await cliente
        .get(
          url,
          headers: {
            'User-Agent':
                'InDrive/0.1 (+https://github.com/eeminionn/appMoviles)',
          },
        )
        .timeout(_tiempoEspera);
    if (respuesta.statusCode != 200) {
      debugPrint('No se pudo calcular la ruta (HTTP ${respuesta.statusCode}).');
      return const [];
    }

    final datos = jsonDecode(respuesta.body);
    if (datos is! Map<String, dynamic> || datos['code'] != 'Ok') {
      return const [];
    }
    final rutas = datos['routes'];
    if (rutas is! List || rutas.isEmpty || rutas.first is! Map) return const [];
    final geometria = (rutas.first as Map)['geometry'];
    if (geometria is! Map || geometria['type'] != 'LineString') return const [];
    final coordenadas = geometria['coordinates'];
    if (coordenadas is! List || coordenadas.length < 2) return const [];

    final puntos = <LatLng>[];
    for (final par in coordenadas) {
      if (par is! List || par.length < 2) return const [];
      final longitud = par[0];
      final latitud = par[1];
      if (longitud is! num ||
          latitud is! num ||
          !longitud.isFinite ||
          !latitud.isFinite ||
          longitud.abs() > 180 ||
          latitud.abs() > 90) {
        return const [];
      }
      puntos.add(LatLng(latitud.toDouble(), longitud.toDouble()));
    }
    return List.unmodifiable(puntos);
  } on Exception catch (error) {
    debugPrint('No se pudo calcular la ruta (${error.runtimeType}).');
    return const [];
  } finally {
    cliente.close();
  }
}

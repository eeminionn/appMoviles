import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'datos.dart';
import 'mapa.dart';

class DireccionEncontrada {
  const DireccionEncontrada(this.direccion, this.punto);

  final String direccion;
  final LatLng punto;
}

const _limiteCache = 32;
final _busquedasGuardadas = <String, List<DireccionEncontrada>>{};
final _busquedasEnCurso = <String, Future<List<DireccionEncontrada>>>{};

Future<List<DireccionEncontrada>> buscarDirecciones(String consulta) async {
  final texto = consulta.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (texto.length < 2 || texto.length > 120) return const [];

  final clave = normalizar(texto);
  final guardadas = _busquedasGuardadas[clave];
  if (guardadas != null) return guardadas;

  return _busquedasEnCurso[clave] ??= _consultarDirecciones(texto)
      .then((resultados) {
        if (resultados.isNotEmpty) {
          if (_busquedasGuardadas.length >= _limiteCache) {
            _busquedasGuardadas.remove(_busquedasGuardadas.keys.first);
          }
          _busquedasGuardadas[clave] = resultados;
        }
        return resultados;
      })
      .whenComplete(() {
        _busquedasEnCurso.remove(clave);
      });
}

Future<List<DireccionEncontrada>> _consultarDirecciones(String consulta) async {
  var servicioDisponible = true;
  try {
    final resultados = await _buscarEnPhoton(consulta);
    if (resultados.isNotEmpty) return resultados;
  } on Exception {
    servicioDisponible = false;
  }

  final punto = await buscarPunto(consulta);
  if (punto != null) {
    return List.unmodifiable([DireccionEncontrada(consulta, punto)]);
  }
  if (!servicioDisponible) {
    throw Exception('El servicio de direcciones no está disponible.');
  }
  return const [];
}

Future<List<DireccionEncontrada>> _buscarEnPhoton(String consulta) async {
  final servicio = Uri.parse(
    const String.fromEnvironment(
      'URL_BUSQUEDA_DIRECCIONES',
      defaultValue: 'https://photon.komoot.io/api/',
    ),
  );
  final url = servicio.replace(
    queryParameters: {
      ...servicio.queryParameters,
      'q': consulta,
      'countrycode': 'CL',
      'lat': centroMapa.latitude.toString(),
      'lon': centroMapa.longitude.toString(),
      'limit': '8',
    },
  );
  final cliente = http.Client();
  try {
    final respuesta = await cliente
        .get(
          url,
          headers: {
            'Accept-Language': 'es',
            'User-Agent':
                'InDrive/0.1 (+https://github.com/eeminionn/appMoviles)',
          },
        )
        .timeout(const Duration(seconds: 6));
    if (respuesta.statusCode != 200) {
      throw const FormatException(
        'Respuesta inválida del servicio de direcciones.',
      );
    }

    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
    if (datos is! Map<String, dynamic> || datos['features'] is! List) {
      throw const FormatException(
        'Respuesta inválida del servicio de direcciones.',
      );
    }

    final resultados = <DireccionEncontrada>[];
    final vistas = <String>{};
    for (final elemento in datos['features'] as List) {
      final resultado = _leerDireccion(elemento, consulta);
      if (resultado != null && vistas.add(normalizar(resultado.direccion))) {
        resultados.add(resultado);
      }
      if (resultados.length == 5) break;
    }
    return List.unmodifiable(resultados);
  } finally {
    cliente.close();
  }
}

DireccionEncontrada? _leerDireccion(Object? elemento, String consulta) {
  if (elemento is! Map<String, dynamic>) return null;
  final lugar = elemento['properties'];
  final geometria = elemento['geometry'];
  if (lugar is! Map<String, dynamic> ||
      lugar['countrycode'] != 'CL' ||
      geometria is! Map<String, dynamic> ||
      geometria['type'] != 'Point') {
    return null;
  }
  final coordenadas = geometria['coordinates'];
  if (coordenadas is! List || coordenadas.length < 2) return null;
  final longitud = coordenadas[0];
  final latitud = coordenadas[1];
  if (longitud is! num ||
      latitud is! num ||
      !longitud.isFinite ||
      !latitud.isFinite ||
      longitud.abs() > 180 ||
      latitud.abs() > 90) {
    return null;
  }

  String leer(String campo) {
    final valor = lugar[campo];
    return valor is String ? valor.trim() : '';
  }

  final nombre = leer('name');
  final calle = leer('street');
  final numero = leer('housenumber');
  if (!_coincideNumero(consulta, nombre, calle, numero)) return null;

  final calleConNumero = [
    calle,
    numero,
  ].where((parte) => parte.isNotEmpty).join(' ');
  final principal = nombre.isNotEmpty ? nombre : calleConNumero;
  if (principal.length < 2 || principal.length > 120) return null;

  final comuna = [
    'city',
    'district',
    'county',
    'state',
  ].map(leer).firstWhere((parte) => parte.isNotEmpty, orElse: () => '');
  var etiqueta = principal;
  for (final parte in [calleConNumero, comuna]) {
    if (parte.isNotEmpty &&
        normalizar(parte) != normalizar(principal) &&
        etiqueta.length + parte.length + 2 <= 120) {
      etiqueta = '$etiqueta, $parte';
    }
  }
  return DireccionEncontrada(
    etiqueta,
    LatLng(latitud.toDouble(), longitud.toDouble()),
  );
}

Set<String> _palabras(String texto) => normalizar(
  texto,
).split(RegExp(r'[^a-zñ0-9]+')).where((palabra) => palabra.isNotEmpty).toSet();

bool _coincideNumero(
  String consulta,
  String nombre,
  String calle,
  String numero,
) {
  final palabras = _palabras(consulta.split(',').first);
  final numeros = palabras.where(RegExp(r'^\d+[a-z]?$').hasMatch);
  if (numeros.isEmpty) return true;

  // Photon puede ofrecer calles vecinas que tengan el mismo número.
  final disponibles = _palabras('$nombre $calle $numero');
  if (!numeros.every(disponibles.contains)) return false;
  const comunes = {
    'av',
    'avenida',
    'calle',
    'pasaje',
    'psje',
    'de',
    'del',
    'la',
    'las',
    'el',
    'los',
  };
  bool coincideNombre(String valor) {
    final propias = _palabras(valor).difference(comunes);
    return propias.isNotEmpty && propias.every(palabras.contains);
  }

  return coincideNombre(calle) || coincideNombre(nombre);
}

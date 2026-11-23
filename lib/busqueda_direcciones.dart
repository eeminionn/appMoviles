import 'datos.dart';
import 'mapa.dart';
import 'photon.dart';

export 'photon.dart' show DireccionEncontrada;

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
    final resultados = await buscarEnPhoton(consulta, centroMapa);
    if (resultados.isNotEmpty) return resultados;
  } on Exception {
    servicioDisponible = false;
  }

  final punto = await buscarPunto(consulta, usarPhotonEnWeb: false);
  if (punto != null) {
    return List.unmodifiable([DireccionEncontrada(consulta, punto)]);
  }
  if (!servicioDisponible) {
    throw Exception('El servicio de direcciones no está disponible.');
  }
  return const [];
}

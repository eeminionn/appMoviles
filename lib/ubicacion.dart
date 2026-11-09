import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class ProblemaUbicacion implements Exception {
  const ProblemaUbicacion(this.mensaje, {this.etiquetaAccion, this.accion});

  final String mensaje;
  final String? etiquetaAccion;
  final Future<bool> Function()? accion;

  @override
  String toString() => mensaje;
}

const _servicioApagado = ProblemaUbicacion(
  'Activa la ubicación del dispositivo para ver tu punto en el mapa.',
  etiquetaAccion: 'Ajustes',
  accion: Geolocator.openLocationSettings,
);

const _permisoDenegado = ProblemaUbicacion(
  'Permite el acceso a tu ubicación para ver tu punto en el mapa.',
);

const _permisoBloqueado = ProblemaUbicacion(
  'Habilita el permiso de ubicación de InDrive en Ajustes.',
  etiquetaAccion: 'Ajustes',
  accion: Geolocator.openAppSettings,
);

ProblemaUbicacion _explicarError(Object error) => switch (error) {
  LocationServiceDisabledException() => _servicioApagado,
  PermissionDeniedException() => _permisoDenegado,
  _ => const ProblemaUbicacion(
    'No pudimos obtener tu ubicación. Inténtalo de nuevo.',
  ),
};

Future<Stream<LatLng>> seguirUbicacion({required bool pedirPermiso}) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) throw _servicioApagado;

    var permiso = await Geolocator.checkPermission();
    if (pedirPermiso &&
        (permiso == LocationPermission.denied ||
            permiso == LocationPermission.unableToDetermine)) {
      permiso = await Geolocator.requestPermission();
    }

    if (permiso == LocationPermission.deniedForever) throw _permisoBloqueado;
    if (permiso != LocationPermission.whileInUse &&
        permiso != LocationPermission.always) {
      throw _permisoDenegado;
    }

    // En Android, usar la ubicación del sistema sin pedir activar servicios de Google.
    final opciones = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(
            forceLocationManager: true,
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          );
    return Geolocator.getPositionStream(locationSettings: opciones)
        .where(
          (punto) => punto.latitude.abs() <= 90 && punto.longitude.abs() <= 180,
        )
        .map((punto) => LatLng(punto.latitude, punto.longitude))
        .handleError((Object error) => throw _explicarError(error));
  } on ProblemaUbicacion {
    rethrow;
  } catch (error) {
    throw _explicarError(error);
  }
}

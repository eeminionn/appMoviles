import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

void configurarGoogleMaps() {
  final mapas = GoogleMapsFlutterPlatform.instance;
  if (mapas is GoogleMapsFlutterAndroid) {
    // La composición nativa conserva la vista del mapa con el renderizador clásico.
    mapas.useAndroidViewSurface = true;
  }
}

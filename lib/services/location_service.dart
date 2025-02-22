import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://nominatim.openstreetmap.org';

  Future<List<Map<String, dynamic>>> searchLocation(String query,
      {LatLng? nearLocation}) async {
    try {
      final queryParams = {
        'q': query,
        'format': 'json',
        'limit': 5,
        'countrycodes': 'mx',
        'accept-language': 'es',
      };

      // Si hay una ubicación cercana, agregamos un área de búsqueda
      if (nearLocation != null) {
        // Definimos un cuadro de aproximadamente 50km alrededor del punto
        final viewBox = [
          nearLocation.longitude - 0.5, // ~50km oeste
          nearLocation.latitude - 0.5, // ~50km sur
          nearLocation.longitude + 0.5, // ~50km este
          nearLocation.latitude + 0.5, // ~50km norte
        ].join(',');

        queryParams['viewbox'] = viewBox;
        queryParams['bounded'] = '1';
      }

      final response = await _dio.get(
        '$_baseUrl/search',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'User-Agent': 'ProyectoVerdeParticipativo/1.0',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = response.data;
        return results.map((item) {
          return {
            'name': item['display_name'] as String,
            'location': LatLng(
              double.parse(item['lat'].toString()),
              double.parse(item['lon'].toString()),
            ),
          };
        }).toList();
      }

      return [];
    } catch (e) {
      print('Error buscando ubicación: $e');
      return [];
    }
  }
}

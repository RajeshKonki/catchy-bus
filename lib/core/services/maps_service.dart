import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapsService {
  final Dio _dio = Dio()
    ..options.connectTimeout = const Duration(seconds: 15)
    ..options.receiveTimeout = const Duration(seconds: 15);
  final String _apiKey = "AIzaSyDxrMKyHgfbv_P_pQoYJogXvAzGCI7Ah_0";

  Future<List<LatLng>> getDirections({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
  }) async {
    // 1. Try Google Routes API (V2)
    final googlePath = await _getGoogleDirections(origin, destination, waypoints);
    if (googlePath.isNotEmpty) return googlePath;

    // 2. Automated Smart Fallback: Use OpenSource Routing Machine (OSRM) 
    // This allows road-following routes even if Google API is disabled in the console
    print('DEBUG: [MapsService] Google API failed (likely disabled), trying OSRM fallback...');
    return await _getOSRMDirections(origin, destination, waypoints);
  }

  Future<List<LatLng>> _getGoogleDirections(LatLng origin, LatLng destination, List<LatLng>? waypoints) async {
    try {
      final url = 'https://routes.googleapis.com/directions/v2:computeRoutes';
      final Map<String, dynamic> data = {
        'origin': {'location': {'latLng': {'latitude': origin.latitude, 'longitude': origin.longitude}}},
        'destination': {'location': {'latLng': {'latitude': destination.latitude, 'longitude': destination.longitude}}},
        if (waypoints != null && waypoints.isNotEmpty)
          'intermediates': waypoints.map((w) => {'location': {'latLng': {'latitude': w.latitude, 'longitude': w.longitude}}}).toList(),
        'travelMode': 'DRIVE',
        'routingPreference': 'TRAFFIC_AWARE',
        'polylineQuality': 'OVERVIEW',
      };

      final response = await _dio.post(
        url,
        data: data,
        options: Options(headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': 'routes.polyline',
        }),
      );

      if (response.statusCode == 200) {
        final routes = response.data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final points = routes[0]['polyline']['encodedPolyline'] as String;
          return _decodePolyline(points);
        }
      }
      return [];
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 403) {
        print('DEBUG: Important - Enable Routes API at https://console.developers.google.com/apis/library/routes.googleapis.com');
      }
      return [];
    }
  }

  Future<List<LatLng>> _getOSRMDirections(LatLng origin, LatLng destination, List<LatLng>? waypoints) async {
    try {
      // OSRM coordinates are [lng,lat] separated by semicolons
      String coords = '${origin.longitude},${origin.latitude}';
      if (waypoints != null && waypoints.isNotEmpty) {
        coords += ';' + waypoints.map((w) => '${w.longitude},${w.latitude}').join(';');
      }
      coords += ';${destination.longitude},${destination.latitude}';

      final url = 'http://router.project-osrm.org/route/v1/driving/$coords?overview=full&geometries=polyline';
      
      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data['routes'] != null) {
        final routes = response.data['routes'] as List;
        if (routes.isNotEmpty) {
          final points = routes[0]['geometry'] as String;
          return _decodePolyline(points);
        }
      }
      return [];
    } catch (e) {
      print('DEBUG: OSRM fallback failed: $e');
      return [];
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polyline;
  }

  static const String cleanMapStyle = r'''
[
  {
    "featureType": "poi",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "transit",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  }
]
''';
}

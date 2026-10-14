import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';
import '../../../../core/config/app_config.dart';

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.description,
  });

  final String placeId;
  final String description;

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      placeId: json['place_id'] as String,
      description: json['description'] as String,
    );
  }
}

class PlaceDetails {
  const PlaceDetails({
    required this.name,
    required this.coordinates,
  });

  final String name;
  final LatLng coordinates;
}

class GooglePlacesService {
  GooglePlacesService();

  static final Logger _log = Logger();

  /// Vérifie si le service est disponible (clé API configurée).
  bool get isAvailable => AppConfig.isGooglePlacesEnabled;

  /// Recherche d'autocomplétion pour les villes.
  Future<List<PlaceSuggestion>> searchCities(String query) async {
    if (!isAvailable || query.isEmpty) {
      return [];
    }

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(query)}'
        '&types=(cities)'
        '&language=fr'
        '&key=${AppConfig.googlePlacesApiKey}',
      );

      _log.d('Google Places API request: $url');
      final response = await http.get(url);

      _log.d('Google Places API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final status = data['status'] as String?;

        if (status != 'OK') {
          _log.w('Google Places API status: $status — error_message: ${data["error_message"]}');
          return [];
        }

        _log.d('Google Places API successful response with status: $status');
        final predictions = data['predictions'] as List<dynamic>? ?? [];

        return predictions
            .map((prediction) => PlaceSuggestion.fromJson(prediction as Map<String, dynamic>))
            .toList();
      } else {
        _log.e('Google Places API HTTP error: ${response.statusCode} — body: ${response.body}');
      }
    } catch (e) {
      _log.e('Google Places API searchCities error: $e');
    }

    return [];
  }

  /// Récupère les détails d'un lieu par son placeId.
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    if (!isAvailable) {
      return null;
    }

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=${Uri.encodeComponent(placeId)}'
        '&fields=name,geometry'
        '&language=fr'
        '&key=${AppConfig.googlePlacesApiKey}',
      );

      _log.d('Google Places Details API request: $url');
      final response = await http.get(url);

      _log.d('Google Places Details API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final status = data['status'] as String?;

        if (status != 'OK') {
          _log.w('Google Places Details API status: $status — error_message: ${data["error_message"]}');
          return null;
        }

        _log.d('Google Places Details API successful response with status: $status');
        final result = data['result'] as Map<String, dynamic>?;

        if (result != null) {
          final name = result['name'] as String?;
          final geometry = result['geometry'] as Map<String, dynamic>?;
          final location = geometry?['location'] as Map<String, dynamic>?;

          if (name != null && location != null) {
            final lat = location['lat'] as double?;
            final lng = location['lng'] as double?;

            if (lat != null && lng != null) {
              return PlaceDetails(
                name: name,
                coordinates: LatLng(lat, lng),
              );
            }
          }
        }
      } else {
        _log.e('Google Places Details API HTTP error: ${response.statusCode} — body: ${response.body}');
      }
    } catch (e) {
      _log.e('Google Places API getPlaceDetails error: $e');
    }

    return null;
  }
}
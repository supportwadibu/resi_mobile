import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
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
        '&key=${AppConfig.googlePlacesApiKey}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final predictions = data['predictions'] as List<dynamic>? ?? [];

        return predictions
            .map((prediction) => PlaceSuggestion.fromJson(prediction as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // Erreur silencieuse pour le mode dégradé
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
        '&key=${AppConfig.googlePlacesApiKey}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
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
      }
    } catch (e) {
      // Erreur silencieuse pour le mode dégradé
    }

    return null;
  }
}
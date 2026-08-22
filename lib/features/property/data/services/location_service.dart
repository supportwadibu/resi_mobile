import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

/// Adresse déduite d'un point, telle qu'elle peut pré-remplir le formulaire.
///
/// Les deux champs sont facultatifs : Nominatim ne renvoie pas toujours une
/// rue exploitable, notamment hors des zones cartographiées finement.
class ResolvedAddress {
  const ResolvedAddress({this.street, this.city});

  final String? street;
  final String? city;

  bool get isEmpty => street == null && city == null;
}

/// Position de l'appareil, et adresse correspondante.
///
/// Le geocoding passe par Nominatim (OpenStreetMap), cohérent avec les tuiles
/// déjà affichées sur la carte. Le service impose une politique d'utilisation :
/// un `User-Agent` identifiant l'application est obligatoire, et les appels
/// doivent rester occasionnels — ils ne le sont ici qu'au moment du dépôt.
class LocationService {
  LocationService({Dio? client}) : _client = client ?? _defaultClient();

  final Dio _client;

  /// Client dédié, séparé de celui de l'API.
  ///
  /// L'instance applicative porte le jeton d'authentification et l'URL de
  /// base de Resi : la réutiliser enverrait les identifiants de l'utilisateur
  /// à un tiers.
  static Dio _defaultClient() => Dio(
    BaseOptions(
      baseUrl: 'https://nominatim.openstreetmap.org',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: const {
        // Exigé par la politique d'utilisation de Nominatim : une requête
        // anonyme est rejetée.
        'User-Agent': 'ResiAfrica/1.0 (contact@resi.africa)',
      },
    ),
  );

  /// Relève la position courante après avoir obtenu l'autorisation.
  ///
  /// Retourne `null` si l'utilisateur refuse, si le service de localisation
  /// est éteint, ou si le relevé échoue : la saisie manuelle reste le chemin
  /// de repli, jamais une impasse.
  Future<Position?> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // `deniedForever` ne peut plus être levé par une demande : seul un passage
    // par les réglages système le débloque.
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      // Relevé indisponible (délai dépassé, capteur muet) : l'appelant
      // retombe sur la saisie manuelle.
      return null;
    }
  }

  /// Traduit un point en adresse postale.
  ///
  /// Un échec réseau n'est pas remonté : le pré-remplissage est un confort,
  /// et son absence ne doit pas interrompre le dépôt de l'annonce.
  Future<ResolvedAddress> resolveAddress(double latitude, double longitude) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/reverse',
        queryParameters: {
          'lat': latitude,
          'lon': longitude,
          'format': 'jsonv2',
          // Niveau « rue » : au-delà, Nominatim renvoie le numéro de parcelle,
          // rarement pertinent pour une annonce.
          'zoom': 18,
          'addressdetails': 1,
          'accept-language': 'fr',
        },
      );

      final address = response.data?['address'] as Map<String, dynamic>?;
      if (address == null) return const ResolvedAddress();

      return ResolvedAddress(street: _street(address), city: _city(address));
    } on DioException {
      return const ResolvedAddress();
    } catch (_) {
      return const ResolvedAddress();
    }
  }

  /// Recompose une rue exploitable à partir des champs disponibles.
  static String? _street(Map<String, dynamic> address) {
    final road = _firstOf(address, const ['road', 'pedestrian', 'footway']);
    final quarter = _firstOf(address, const [
      'neighbourhood',
      'suburb',
      'quarter',
      'city_district',
    ]);

    final parts = [
      ?address['house_number']?.toString(),
      if (road != null) road,
      if (quarter != null && quarter != road) quarter,
    ];

    return parts.isEmpty ? null : parts.join(', ');
  }

  /// Retient la commune la plus spécifique renvoyée par Nominatim.
  ///
  /// Le champ `city` est absent de nombreuses réponses en Afrique de l'Ouest ;
  /// `town` et `village` prennent alors le relais.
  static String? _city(Map<String, dynamic> address) => _firstOf(address, const [
    'city',
    'town',
    'village',
    'municipality',
    'county',
    'state',
  ]);

  /// Première clé renseignée et non vide, dans l'ordre de préférence donné.
  static String? _firstOf(Map<String, dynamic> address, List<String> keys) {
    for (final key in keys) {
      final value = address[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}

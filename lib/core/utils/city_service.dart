import 'dart:convert';

import 'package:flutter/services.dart';

class CityService {
  CityService._();

  static final CityService instance = CityService._();

  final Map<String, List<String>> _cities = {};
  final Map<String, Map<String, List<String>>> _communes = {};

  static const Set<String> supportedCountries = {'CI'};

  static bool isSupported(String iso2) =>
      supportedCountries.contains(iso2.toUpperCase());

  Future<List<String>> citiesOf(String iso2) async {
    final code = iso2.toUpperCase();

    final cached = _cities[code];
    if (cached != null) return cached;

    if (!isSupported(code)) return const [];

    final cities = await _loadJson<List<String>>(
      'assets/data/cities/${code.toLowerCase()}.json',
      (decoded) => (decoded as List<dynamic>).cast<String>(),
      const [],
    );

    _cities[code] = cities;
    return cities;
  }

  Future<List<String>> communesOf(String iso2, String city) async {
    final code = iso2.toUpperCase();

    if (!isSupported(code)) return const [];

    final byCity = _communes[code] ?? await _loadCommunes(code);
    return byCity[city] ?? const [];
  }

  Future<bool> hasCommunes(String iso2, String city) async =>
      (await communesOf(iso2, city)).isNotEmpty;

  Future<Map<String, List<String>>> _loadCommunes(String code) async {
    final byCity = await _loadJson<Map<String, List<String>>>(
      'assets/data/communes/${code.toLowerCase()}.json',
      (decoded) => (decoded as Map<String, dynamic>).map(
        (city, communes) =>
            MapEntry(city, (communes as List<dynamic>).cast<String>()),
      ),
      const {},
    );

    _communes[code] = byCity;
    return byCity;
  }

  Future<T> _loadJson<T>(
    String path,
    T Function(Object? decoded) parse,
    T fallback,
  ) async {
    try {
      return parse(jsonDecode(await rootBundle.loadString(path)));
    } on Exception {
      return fallback;
    }
  }
}

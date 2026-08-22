import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/core/utils/city_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CityService — villes', () {
    test('charge les villes de Côte d’Ivoire', () async {
      final cities = await CityService.instance.citiesOf('CI');
      expect(cities, contains('Abidjan'));
      expect(cities, contains('Yamoussoukro'));
      expect(cities, contains('Bouaké'));
    });

    test('ne contient aucune commune d’Abidjan', () async {
      final cities = await CityService.instance.citiesOf('CI');
      // Ces entités sont des communes, pas des villes : les lister ici
      // reviendrait à mélanger deux niveaux administratifs.
      expect(cities, isNot(contains('Abobo')));
      expect(cities, isNot(contains('Yopougon')));
      expect(cities, isNot(contains('Cocody')));
      expect(cities, isNot(contains('Anyama')));
    });

    test('le code ISO est insensible à la casse', () async {
      expect(await CityService.instance.citiesOf('ci'), isNotEmpty);
    });

    test('un pays non couvert renvoie une liste vide', () async {
      expect(await CityService.instance.citiesOf('FR'), isEmpty);
      expect(await CityService.instance.citiesOf('ZZ'), isEmpty);
    });
  });

  group('CityService — communes', () {
    test('Abidjan a ses communes', () async {
      final communes = await CityService.instance.communesOf('CI', 'Abidjan');
      expect(communes, contains('Cocody'));
      expect(communes, contains('Yopougon'));
      expect(communes, contains('Plateau'));
    });

    test('Yamoussoukro a ses communes', () async {
      final communes = await CityService.instance.communesOf(
        'CI',
        'Yamoussoukro',
      );
      expect(communes, contains('Attiégouakro'));
    });

    test('une ville sans sous-découpage renvoie une liste vide', () async {
      expect(await CityService.instance.communesOf('CI', 'Bouaké'), isEmpty);
      expect(await CityService.instance.communesOf('CI', 'Korhogo'), isEmpty);
    });

    test('hasCommunes distingue les deux cas', () async {
      expect(await CityService.instance.hasCommunes('CI', 'Abidjan'), isTrue);
      expect(await CityService.instance.hasCommunes('CI', 'Daloa'), isFalse);
    });

    test('une ville inconnue ne lève pas', () async {
      expect(await CityService.instance.communesOf('CI', 'Atlantide'), isEmpty);
      expect(await CityService.instance.communesOf('FR', 'Paris'), isEmpty);
    });
  });

  group('Cohérence des données', () {
    test('chaque ville de communes/ci.json existe dans cities/ci.json', () async {
      // Le chaînage repose sur une correspondance exacte des libellés : une
      // divergence orthographique rendrait les communes inatteignables.
      final cities = await CityService.instance.citiesOf('CI');
      final raw = await rootBundle.loadString('assets/data/communes/ci.json');
      final keys = (jsonDecode(raw) as Map<String, dynamic>).keys;

      for (final city in keys) {
        expect(
          cities,
          contains(city),
          reason: '"$city" est clé dans communes/ci.json mais absente des villes',
        );
      }
    });
  });
}

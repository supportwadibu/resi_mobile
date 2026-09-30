import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/features/reservation/business_logic/reservation_state.dart';
import 'package:resi_africa/features/reservation/data/models/reservation_model.dart';

ReservationModel _booking(String id, {Map<String, dynamic>? client}) =>
    ReservationModel.fromJson({
      'id': id,
      'status': 'confirmed',
      'source': client == null ? 'online' : 'offline',
      'client': ?client,
    });

void main() {
  final items = [
    _booking(
      'a',
      client: {'full_name': 'Kouamé Yao', 'phone': '07 01 02 03 04'},
    ),
    _booking('b', client: {'full_name': 'Awa Traoré', 'phone': '0505050505'}),
    // Réservation en ligne : aucun instantané client.
    _booking('c'),
  ];

  List<String> search(String query) => ReservationLoaded(
    items,
    query: query,
  ).visibleItems.map((r) => r.id).toList();

  group('ReservationLoaded.visibleItems — recherche client', () {
    test('sans recherche, toute la liste, en ligne comprise', () {
      expect(search(''), ['a', 'b', 'c']);
      expect(search('   '), ['a', 'b', 'c']);
    });

    test('le nom se trouve sans accents ni majuscules', () {
      expect(search('kouame'), ['a']);
      expect(search('TRAORÉ'), ['b']);
    });

    test('le téléphone se compare chiffres seuls', () {
      expect(search('0701 02'), ['a']);
      expect(search('0505'), ['b']);
    });

    test('une réservation sans instantané client sort dès qu’on cherche', () {
      expect(search('a'), ['a', 'b']);
    });
  });
}

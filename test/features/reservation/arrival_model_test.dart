import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/features/reservation/data/models/arrival_model.dart';

Map<String, dynamic> _json(Map<String, dynamic> check) => {
  'booking': {
    'id': 'b1',
    'property_id': 'p1',
    'client_id': 'u1',
    'status': 'confirmed',
    'start_date': '2026-11-21T12:00:00.000Z',
    'end_date': '2026-11-23T12:00:00.000Z',
    'total_amount': 50000,
  },
  'check': check,
};

void main() {
  group('ArrivalModel.documentsComplete', () {
    test('pièce absente du carnet : à enregistrer avant les clés', () {
      final arrival = ArrivalModel.fromJson(
        _json({'can_check_in': true, 'documents_complete': false}),
      );
      expect(arrival.canCheckIn, isTrue);
      expect(arrival.documentsComplete, isFalse);
    });

    test('serveur antérieur, sans le champ : l’arrivée ne se bloque pas', () {
      final arrival = ArrivalModel.fromJson(_json({'can_check_in': true}));
      expect(arrival.documentsComplete, isTrue);
    });
  });
}

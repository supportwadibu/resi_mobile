import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/features/clients/data/models/client_model.dart';
import 'package:resi_africa/features/clients/data/services/id_card_reading.dart';
import 'package:resi_africa/features/clients/presentation/widgets/create/client_identity_controller.dart';

void main() {
  const reading = IdCardReading(
    documentType: ClientIdDocumentType.cni,
    documentNumber: 'C0012345',
    birthPlace: 'Bouaké',
    nationality: 'Ivoirienne',
  );

  test('une photo déposée ne comble que les champs vides', () {
    final controller = ClientIdentityController()
      ..birthPlace.text = 'Korhogo';

    controller.apply(reading, overwrite: false);

    // La correction à la main tient ; le reste se remplit.
    expect(controller.birthPlace.text, 'Korhogo');
    expect(controller.nationality.text, 'Ivoirienne');
    expect(controller.documentNumber.text, 'C0012345');
    expect(controller.documentType, ClientIdDocumentType.cni);
  });

  test('un scan explicite remplace la saisie', () {
    final controller = ClientIdentityController()
      ..birthPlace.text = 'Korhogo';

    controller.apply(reading, overwrite: true);

    expect(controller.birthPlace.text, 'Bouaké');
  });

  test('un champ non lu n’est jamais vidé', () {
    final controller = ClientIdentityController()..address.text = 'Yopougon';

    controller.apply(reading, overwrite: true);

    expect(controller.address.text, 'Yopougon');
  });

  test('rend l’identité saisie, champs vides à null', () {
    final controller = ClientIdentityController(
      identity: ClientIdentity(birthDate: DateTime(1990, 4, 12)),
    )..nationality.text = '  ';

    final identity = controller.identity;
    expect(identity.birthDate, DateTime(1990, 4, 12));
    expect(identity.nationality, isNull);
  });

  group('ClientIdentity.toFormFields', () {
    final identity = ClientIdentity(
      birthDate: DateTime(1990, 4, 2),
      birthPlace: 'Bouaké',
    );

    test('dates en AAAA-MM-JJ, champs vides omis à la création', () {
      expect(identity.toFormFields(), {
        'birth_date': '1990-04-02',
        'birth_place': 'Bouaké',
      });
    });

    test('champs vides envoyés vides à la mise à jour, pour les effacer', () {
      final fields = identity.toFormFields(includeEmpty: true);
      expect(fields['nationality'], '');
      expect(fields['id_document_issued_at'], '');
    });

    test('une date serveur est lue sur sa partie calendaire', () {
      final read = ClientIdentity.fromJson({
        'birth_date': '1990-04-12T00:00:00.000Z',
      });
      expect(read.birthDate, DateTime(1990, 4, 12));
    });
  });
}

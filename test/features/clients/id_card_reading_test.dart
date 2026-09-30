import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/features/clients/data/models/client_model.dart';
import 'package:resi_africa/features/clients/data/services/id_card_reading.dart';
import 'package:resi_africa/features/clients/data/services/id_label_parser.dart';

/// Recto d'une CNI ivoirienne tel que ML Kit le rend : libellés bilingues au
///-dessus des valeurs, ordre des blocs approximatif.
const _recto = '''
REPUBLIQUE DE COTE D'IVOIRE
CARTE NATIONALE D'IDENTITE
Nom / Surname
KOUASSI
Prénom(s) / Given names
AYA MARIE
Date de naissance / Date of birth
12/04/1990
Lieu de naissance / Place of birth
BOUAKE
Sexe / Sex
F
Nationalité / Nationality
IVOIRIENNE
''';

/// Verso : dates de délivrance et domicile, puis la bande MRZ.
const _verso = '''
Profession : COMMERCANTE
Domicile : COCODY ANGRE 8E TRANCHE
Date de délivrance : 12.03.2021
Date d'expiration : 11.03.2031
I<UTOD231458907<<<<<<<<<<<<<<<
7408122F1204159UTO<<<<<<<<<<<6
ERIKSSON<<ANNA<MARIA<<<<<<<<<<
''';

void main() {
  group('IdLabelParser', () {
    test('lit les valeurs placées sous leur libellé', () {
      final fields = IdLabelParser.parse(_recto);

      expect(fields.surname, 'Kouassi');
      expect(fields.givenNames, 'Aya Marie');
      expect(fields.birthDate, DateTime(1990, 4, 12));
      expect(fields.birthPlace, 'Bouake');
      expect(fields.nationality, 'Ivoirienne');
    });

    test('lit les valeurs placées sur la ligne du libellé', () {
      final fields = IdLabelParser.parse(_verso);

      expect(fields.address, 'Cocody Angre 8e Tranche');
      expect(fields.issuedAt, DateTime(2021, 3, 12));
    });

    test('ne prend pas un libellé voisin pour une valeur', () {
      const text = 'Lieu de naissance\nSexe / Sex\nF';
      expect(IdLabelParser.parse(text).birthPlace, isNull);
    });

    test('ignore une date impossible', () {
      const text = 'Date de délivrance : 45/13/2021';
      expect(IdLabelParser.parse(text).issuedAt, isNull);
    });

    test('un texte sans libellé ne livre rien', () {
      expect(IdLabelParser.parse('BONJOUR\n1234').isEmpty, isTrue);
    });
  });

  group('IdCardReading.fromText', () {
    test('la MRZ prime pour le nom, le numéro et la naissance', () {
      final reading = IdCardReading.fromText('$_recto\n$_verso')!;

      // Nom et date lus sur la MRZ, vérifiés par chiffres de contrôle.
      expect(reading.fullName, 'Anna Maria Eriksson');
      expect(reading.documentNumber, 'D23145890');
      expect(reading.documentType, ClientIdDocumentType.cni);
      expect(reading.birthDate, DateTime(1974, 8, 12));
      // Ce que la MRZ ne porte pas vient des libellés.
      expect(reading.birthPlace, 'Bouake');
      expect(reading.address, 'Cocody Angre 8e Tranche');
      expect(reading.issuedAt, DateTime(2021, 3, 12));
    });

    test('sans MRZ, le recto seul suffit à préremplir', () {
      final reading = IdCardReading.fromText(_recto)!;

      expect(reading.fullName, 'Aya Marie Kouassi');
      expect(reading.birthDate, DateTime(1990, 4, 12));
      expect(reading.nationality, 'Ivoirienne');
      expect(reading.documentNumber, isNull);
    });

    test('la nationalité MRZ est traduite pour le registre', () {
      const civ =
          'I<CIVD231458907<<<<<<<<<<<<<<<\n'
          '7408122F1204159CIV<<<<<<<<<<<6\n'
          'KOUASSI<<AYA<<<<<<<<<<<<<<<<<<';
      // Chiffre de contrôle final recalculé par le parseur : seul le champ
      // nationalité compte ici, la ligne est lue au mieux.
      final reading = IdCardReading.fromText(civ);
      expect(reading?.nationality, 'Ivoirienne');
    });

    test('rien de lisible : null', () {
      expect(IdCardReading.fromText('photo floue'), isNull);
    });
  });

  group('IdCardReading.merge', () {
    test('complète sans écraser', () {
      const first = IdCardReading(documentNumber: 'A1', birthPlace: 'Man');
      const second = IdCardReading(
        documentNumber: 'B2',
        address: 'Yopougon',
      );

      final merged = first.merge(second);
      expect(merged.documentNumber, 'A1');
      expect(merged.birthPlace, 'Man');
      expect(merged.address, 'Yopougon');
    });
  });
}

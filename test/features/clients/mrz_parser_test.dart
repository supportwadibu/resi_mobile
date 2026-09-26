import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/features/clients/data/models/client_model.dart';
import 'package:resi_africa/features/clients/data/services/mrz_parser.dart';

/// Spécimens de la norme ICAO 9303, parties 4 et 5.
const _td3 =
    'P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<\n'
    'L898902C36UTO7408122F1204159ZE184226B<<<<<10';

const _td1 =
    'I<UTOD231458907<<<<<<<<<<<<<<<\n'
    '7408122F1204159UTO<<<<<<<<<<<6\n'
    'ERIKSSON<<ANNA<MARIA<<<<<<<<<<';

void main() {
  group('MrzParser', () {
    test('lit un passeport (TD3)', () {
      final result = MrzParser.parse(_td3);

      expect(result, isNotNull);
      expect(result!.documentType, ClientIdDocumentType.passeport);
      expect(result.surname, 'Eriksson');
      expect(result.givenNames, 'Anna Maria');
      expect(result.fullName, 'Anna Maria Eriksson');
      expect(result.documentNumber, 'L898902C3');
      expect(result.nationality, 'UTO');
      expect(result.birthDate, DateTime(1974, 8, 12));
    });

    test("lit une carte d'identité (TD1)", () {
      final result = MrzParser.parse(_td1);

      expect(result, isNotNull);
      expect(result!.documentType, ClientIdDocumentType.cni);
      expect(result.fullName, 'Anna Maria Eriksson');
      expect(result.documentNumber, 'D23145890');
      expect(result.nationality, 'UTO');
    });

    test('reconstitue un numéro de carte plus long que le champ', () {
      const number = 'D23145890734';
      final check = MrzParser.checkDigit(number);
      final first = 'I<UTOD23145890<734$check'.padRight(30, '<');

      final result = MrzParser.parse(
        '$first\n7408122F1204159UTO<<<<<<<<<<<6\nERIKSSON<<ANNA<<<<<<<<<<<<<<<<',
      );

      expect(result?.documentNumber, number);
    });

    test('tolère le bruit de lecture : espaces, chevrons mal reconnus', () {
      const noisy =
          'REPUBLIQUE DE COTE D IVOIRE\n'
          'I<UTO D231458907 «<<<<<<<<<<<<<\n'
          '7408122F1204159UTO<<<<<<<<<<<6\n'
          'ERIKSSON<<ANNA<MARIA<<<<<<<<';

      expect(MrzParser.parse(noisy)?.documentNumber, 'D23145890');
    });

    test('un numéro au chiffre de contrôle faux est écarté, pas le nom', () {
      final result = MrzParser.parse(
        _td1.replaceFirst('D231458907', 'D231458908'),
      );

      expect(result, isNotNull);
      expect(result!.documentNumber, isNull);
      expect(result.fullName, 'Anna Maria Eriksson');
    });

    test('un texte sans MRZ ne donne rien', () {
      expect(
        MrzParser.parse('CARTE NATIONALE D IDENTITE\nNom : KOUASSI'),
        isNull,
      );
      expect(MrzParser.parse(''), isNull);
    });

    test('chiffre de contrôle ICAO', () {
      expect(MrzParser.checkDigit('L898902C3'), '6');
      expect(MrzParser.checkDigit('740812'), '2');
      expect(MrzParser.checkDigit('<<<'), '0');
    });
  });
}

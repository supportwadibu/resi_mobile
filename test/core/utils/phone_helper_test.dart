import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/core/utils/flag_helper.dart';
import 'package:resi_africa/core/utils/phone_helper.dart';

void main() {
  group('PhoneHelper — Côte d’Ivoire', () {
    test('accepte un numéro local à 10 chiffres', () {
      expect(PhoneHelper.isValid('0700000000', 'CI'), isTrue);
      expect(PhoneHelper.isValid('07 00 00 00 00', 'CI'), isTrue);
    });

    test('rejette un numéro à 8 chiffres, format abandonné', () {
      expect(PhoneHelper.isValid('07000000', 'CI'), isFalse);
    });

    test('normalise en E.164', () {
      expect(PhoneHelper.toE164('07 00 00 00 00', 'CI'), '+2250700000000');
    });

    test('toNational est l’inverse de toE164', () {
      final national = PhoneHelper.toNational('+2250700000000', 'CI');
      expect(PhoneHelper.toE164(national, 'CI'), '+2250700000000');
    });

    test('toE164 renvoie null sur un numéro invalide', () {
      expect(PhoneHelper.toE164('123', 'CI'), isNull);
    });
  });

  group('PhoneHelper — robustesse', () {
    test('une saisie vide ou absurde ne lève pas', () {
      expect(PhoneHelper.tryParse('', 'CI'), isNull);
      expect(PhoneHelper.tryParse('abc', 'CI'), isNull);
      expect(PhoneHelper.isValid('++--', 'CI'), isFalse);
    });

    test('un pays inconnu n’impose aucune contrainte', () {
      expect(PhoneHelper.isoCodeOf('ZZ'), isNull);
      expect(PhoneHelper.validate('123', 'ZZ'), isNull);
    });

    test('un champ vide reste requis', () {
      expect(PhoneHelper.validate('', 'CI'), 'Ce champ est requis');
      expect(PhoneHelper.validate(null, 'CI'), 'Ce champ est requis');
    });

    test('les indicatifs partagés restent distincts par pays', () {
      // +1 couvre US et CA : la validation dépend du pays, jamais de
      // l'indicatif seul.
      expect(PhoneHelper.toE164('2025550119', 'US'), '+12025550119');
      expect(PhoneHelper.isoCodeOf('CA'), isNotNull);
    });
  });

  group('countryFlag', () {
    test('convertit un code ISO2 en emoji', () {
      expect(countryFlag('CI'), '🇨🇮');
      expect(countryFlag('ci'), '🇨🇮');
      expect(countryFlag('FR'), '🇫🇷');
    });

    test('renvoie une chaîne vide sur une entrée invalide', () {
      expect(countryFlag('C'), '');
      expect(countryFlag('CIV'), '');
      expect(countryFlag('12'), '');
    });
  });
}

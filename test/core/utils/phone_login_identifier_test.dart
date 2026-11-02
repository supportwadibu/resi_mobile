import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/core/utils/phone_helper.dart';

/// Un gérant enregistré par son propriétaire ne pouvait pas se connecter.
///
/// `AddGerantScreen` envoie le numéro mis en forme internationale
/// (`+2250102030405`), tandis que l'écran de connexion envoyait la saisie
/// brute (`0102030405`). L'API cherche par égalité stricte : elle ne trouvait
/// aucun compte et répondait « Identifiants invalides » sur des données
/// pourtant exactes.
void main() {
  group('normalizeLoginIdentifier', () {
    test('un numéro national prend la forme enregistrée en base', () {
      // Le cœur du défaut : cette égalité était fausse, et c'est elle que
      // l'API évalue.
      expect(
        PhoneHelper.normalizeLoginIdentifier('0102030405', 'CI'),
        PhoneHelper.toE164('0102030405', 'CI'),
      );
      expect(
        PhoneHelper.normalizeLoginIdentifier('0102030405', 'CI'),
        '+2250102030405',
      );
    });

    test('un numéro déjà international reste inchangé', () {
      expect(
        PhoneHelper.normalizeLoginIdentifier('+2250102030405', 'CI'),
        '+2250102030405',
      );
    });

    test('les espaces de saisie ne changent pas le résultat', () {
      // Le clavier téléphone en pose, et le serveur n'accepte que des chiffres.
      expect(
        PhoneHelper.normalizeLoginIdentifier('01 02 03 04 05', 'CI'),
        '+2250102030405',
      );
    });

    test('une adresse e-mail traverse sans être touchée', () {
      // Même champ à l'écran pour les deux : la casse et le contenu d'une
      // adresse ne doivent pas dépendre du chemin téléphone.
      expect(
        PhoneHelper.normalizeLoginIdentifier('Awa@Exemple.ci', 'CI'),
        'Awa@Exemple.ci',
      );
    });

    test('une saisie illisible est rendue telle quelle', () {
      // Mieux vaut laisser l'API refuser que transformer une saisie en une
      // autre : une normalisation approximative masquerait la vraie erreur.
      expect(PhoneHelper.normalizeLoginIdentifier('12', 'CI'), '12');
    });

    test('une saisie vide reste vide', () {
      expect(PhoneHelper.normalizeLoginIdentifier('   ', 'CI'), '');
    });
  });
}

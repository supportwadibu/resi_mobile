import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/core/error/failures.dart';
import 'package:resi_africa/features/gerant/data/models/gerant_account_model.dart';
import 'package:resi_africa/features/gerant/data/repositories/gerant_admin_repository.dart';

void main() {
  group('traduction des refus métier', () {
    test('les deux 422 se distinguent par leur code, pas par leur message', () {
      // `AppFailure.validation` écrase le message du serveur quand la réponse
      // ne porte pas de clé `errors` — c'est le cas des refus métier. Lire le
      // code est donc le seul moyen de dire lequel des deux refus s'est
      // produit.
      final contact = translateGerantFailure(
        AppFailure.validation(
          errors: const {},
          code: 'manager_contact_required',
        ),
      );
      final notOwned = translateGerantFailure(
        AppFailure.validation(errors: const {}, code: 'property_not_owned'),
      );

      expect(contact.userMessage, 'Renseignez un e-mail ou un téléphone.');
      expect(
        notOwned.userMessage,
        'Un des logements sélectionnés ne vous appartient pas.',
      );
    });

    test('le conflit 409 devient un message sur les coordonnées', () {
      final failure = translateGerantFailure(
        AppFailure.serverError(
          code: 409,
          message: 'Conflit',
          businessCode: 'manager_already_exists',
        ),
      );

      expect(
        failure.userMessage,
        'Un compte existe déjà avec ces coordonnées.',
      );
      expect(failure.statusCode, 409);
    });

    test('le 404 métier nomme le gérant', () {
      final failure = translateGerantFailure(
        AppFailure.notFound(code: 'manager_not_found'),
      );

      expect(failure.userMessage, 'Ce gérant est introuvable.');
    });

    test('un échec sans code connu passe inchangé', () {
      // Une panne de transport doit continuer à dire ce qu'elle est : la
      // repeindre en erreur de gérant enverrait le propriétaire corriger un
      // formulaire correct.
      final reseau = AppFailure.noInternet();

      expect(
        translateGerantFailure(reseau).userMessage,
        'Pas de connexion internet.',
      );
      expect(
        translateGerantFailure(
          AppFailure.validation(errors: const {}, code: 'autre_chose'),
        ).userMessage,
        'Les informations saisies ont été refusées par le serveur.',
      );
    });
  });

  group('modèle de compte gérant', () {
    test('la clé du document est lue sous `_id`', () {
      final model = GerantAccountModel.fromJson(const {
        '_id': 'g-1',
        'full_name': 'Awa Koné',
        'email': 'awa@example.com',
        'phone': null,
        'is_active': true,
        'property_ids': ['p-1', 'p-2'],
        'created_at': '2026-09-01T10:00:00.000Z',
      });

      expect(model.id, 'g-1');
      expect(model.propertiesCount, 2);
      expect(model.contact, 'awa@example.com');
      expect(model.isActive, isTrue);
    });

    test('un gérant sans périmètre se lit sans lever', () {
      // Un compte ouvert sans logement est légitime : le propriétaire lui en
      // attribuera ensuite.
      final model = GerantAccountModel.fromJson(const {
        '_id': 'g-2',
        'full_name': 'Koffi',
        'phone': '+2250700000000',
        'is_active': false,
      });

      expect(model.propertyIds, isEmpty);
      expect(model.contact, '+2250700000000');
      expect(model.isActive, isFalse);
      expect(model.createdAt, isNull);
    });

    test('la charge utile de création porte toujours property_ids', () {
      // Même vide : le serveur attend la clé, et son absence ferait échouer la
      // validation sur un cas pourtant légitime.
      final payload = const CreateGerantPayload(
        fullName: '  Awa Koné  ',
        password: 'motdepasse1',
        email: '  ',
      ).toJson();

      expect(payload['property_ids'], <String>[]);
      expect(payload['full_name'], 'Awa Koné');
      // Une coordonnée vide n'est pas envoyée vide : le validateur la
      // refuserait comme adresse malformée.
      expect(payload.containsKey('email'), isFalse);
    });
  });
}

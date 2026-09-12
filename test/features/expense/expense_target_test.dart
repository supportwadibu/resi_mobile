import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/features/expense/data/models/expense_model.dart';

void main() {
  group('ExpenseModel — rattachement', () {
    test('lit une charge de logement', () {
      final expense = ExpenseModel.fromJson({
        'id': 'exp_1',
        'property_id': 'studio-1',
        'category': 'cleaning',
        'amount': 5000,
        'spent_at': '2026-09-01T00:00:00.000Z',
        'property': {'id': 'studio-1', 'title': 'Studio 1', 'city': 'Abidjan'},
      });

      expect(expense.propertyId, 'studio-1');
      expect(expense.residenceId, isNull);
      expect(expense.isCommonCharge, isFalse);
      expect(expense.targetLabel, 'Studio 1');
    });

    test('lit une charge commune de résidence', () {
      // Le cas que l'ancien modèle ne savait pas représenter : `property_id`
      // était lu en `String` non nullable avec un repli `''`, ce qui affichait
      // une dépense sans libellé.
      final expense = ExpenseModel.fromJson({
        'id': 'exp_2',
        'property_id': null,
        'residence_id': 'resi-adja',
        'category': 'electricity',
        'amount': 30000,
        'spent_at': '2026-09-01T00:00:00.000Z',
        'residence': {'id': 'resi-adja', 'name': 'Resi Adja', 'city': 'Abidjan'},
      });

      expect(expense.propertyId, isNull);
      expect(expense.residenceId, 'resi-adja');
      expect(expense.isCommonCharge, isTrue);
      expect(expense.targetLabel, 'Resi Adja');
    });

    test('une cible supprimée laisse un libellé lisible', () {
      // Le serveur renvoie `residence: null` quand la résidence a été supprimée
      // depuis la saisie : sans repli, l'historique afficherait une ligne vide.
      final expense = ExpenseModel.fromJson({
        'id': 'exp_3',
        'residence_id': 'resi-disparue',
        'category': 'water',
        'amount': 12000,
        'spent_at': '2026-09-01T00:00:00.000Z',
        'residence': null,
      });

      expect(expense.targetLabel, 'Résidence supprimée');
    });

    test('un bien supprimé laisse un libellé distinct', () {
      final expense = ExpenseModel.fromJson({
        'id': 'exp_4',
        'property_id': 'bien-disparu',
        'category': 'maintenance',
        'amount': 8000,
        'spent_at': '2026-09-01T00:00:00.000Z',
      });

      expect(expense.targetLabel, 'Bien supprimé');
      expect(expense.isCommonCharge, isFalse);
    });

    test('une dépense antérieure aux résidences reste une charge de logement', () {
      // Compatibilité ascendante : l'historique ne porte pas `residence_id`.
      final expense = ExpenseModel.fromJson({
        'id': 'exp_5',
        'property_id': 'villa',
        'category': 'taxes',
        'amount': 50000,
        'spent_at': '2026-01-01T00:00:00.000Z',
      });

      expect(expense.isCommonCharge, isFalse);
      expect(expense.residenceId, isNull);
    });
  });

  group('CreateExpensePayload', () {
    test('une charge de logement n’envoie que property_id', () {
      final json = CreateExpensePayload.forProperty(
        propertyId: 'studio-1',
        category: ExpenseCategory.cleaning,
        amount: 5000,
        spentAt: DateTime(2026, 9, 1),
      ).toJson();

      expect(json['property_id'], 'studio-1');
      expect(json.containsKey('residence_id'), isFalse);
    });

    test('une charge commune n’envoie que residence_id', () {
      // Envoyer les deux ferait refuser la dépense en 422
      // (`ambiguous_expense_target`) : les constructeurs nommés rendent ce cas
      // impossible à construire.
      final json = CreateExpensePayload.forResidence(
        residenceId: 'resi-adja',
        category: ExpenseCategory.electricity,
        amount: 30000,
        spentAt: DateTime(2026, 9, 1),
      ).toJson();

      expect(json['residence_id'], 'resi-adja');
      expect(json.containsKey('property_id'), isFalse);
    });
  });

  group('UpdateExpensePayload', () {
    test('une modification sans bascule ne touche pas au rattachement', () {
      final json = UpdateExpensePayload(amount: 7000).toJson();

      expect(json['amount'], 7000);
      expect(json.containsKey('property_id'), isFalse);
      expect(json.containsKey('residence_id'), isFalse);
    });

    test('la bascule vers une résidence efface property_id explicitement', () {
      // Les deux clés voyagent ensemble, `null` compris : poser `residence_id`
      // sans effacer l'autre les ferait coexister, et la dépense serait comptée
      // deux fois dans un relevé de résidence.
      final json = UpdateExpensePayload.toResidence('resi-adja').toJson();

      expect(json['residence_id'], 'resi-adja');
      expect(json.containsKey('property_id'), isTrue);
      expect(json['property_id'], isNull);
    });

    test('la bascule vers un logement efface residence_id explicitement', () {
      final json = UpdateExpensePayload.toProperty('studio-2').toJson();

      expect(json['property_id'], 'studio-2');
      expect(json.containsKey('residence_id'), isTrue);
      expect(json['residence_id'], isNull);
    });

    test('une bascule n’est jamais vide', () {
      // `isEmpty` court-circuite l'appel réseau : un changement de cible seul
      // doit malgré tout partir.
      expect(UpdateExpensePayload.toResidence('resi-adja').isEmpty, isFalse);
      expect(const UpdateExpensePayload().isEmpty, isTrue);
    });

    test('une note effacée se distingue d’une note inchangée', () {
      expect(
        const UpdateExpensePayload(clearNote: true).toJson()['note'],
        isNull,
      );
      expect(
        const UpdateExpensePayload(clearNote: true).toJson().containsKey('note'),
        isTrue,
      );
      expect(const UpdateExpensePayload().toJson().containsKey('note'), isFalse);
    });
  });
}

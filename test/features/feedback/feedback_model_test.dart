import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/features/feedback/data/models/feedback_model.dart';

void main() {
  group('FeedbackType', () {
    test('reconnaît les valeurs du contrat', () {
      expect(FeedbackType.fromValue('bug'), FeedbackType.bug);
      expect(FeedbackType.fromValue('amelioration'), FeedbackType.amelioration);
    });

    test('range un type inconnu dans « autre »', () {
      // Une API plus récente peut introduire un type que cette version ignore :
      // l'historique doit rester affichable plutôt que de lever.
      expect(FeedbackType.fromValue('nouveaute'), FeedbackType.autre);
      expect(FeedbackType.fromValue(null), FeedbackType.autre);
    });
  });

  group('FeedbackStatus', () {
    test('présente comme non traité un statut absent', () {
      // `status` est arrivé avec le back-office : les premiers avis n'en
      // portent pas.
      expect(FeedbackStatus.fromValue(null), FeedbackStatus.newFeedback);
      expect(
        FeedbackStatus.fromValue('in_progress'),
        FeedbackStatus.inProgress,
      );
    });
  });

  group('FeedbackContext.toJson', () {
    test('n’envoie que les champs connus', () {
      // L'API accepte chacun d'eux absent : envoyer des `null` explicites
      // écraserait inutilement le document côté serveur.
      const context = FeedbackContext(appVersion: '1.4.1', platform: 'android');
      expect(context.toJson(), {'app_version': '1.4.1', 'platform': 'android'});
    });

    test('produit un objet vide quand rien n’a pu être collecté', () {
      expect(const FeedbackContext().toJson(), isEmpty);
    });
  });

  group('CreateFeedbackPayload.toJson', () {
    test('sérialise le type par sa valeur de contrat', () {
      const payload = CreateFeedbackPayload(
        type: FeedbackType.amelioration,
        title: 'Le filtre des dates',
        message: 'Il faudrait garder le dernier filtre choisi.',
        context: FeedbackContext(flavor: 'prod'),
      );

      final json = payload.toJson();
      expect(json['type'], 'amelioration');
      expect(json['title'], 'Le filtre des dates');
      expect(json['context'], {'flavor': 'prod'});
    });
  });

  group('FeedbackModel.fromJson', () {
    test('lit une réponse complète', () {
      final model = FeedbackModel.fromJson({
        'id': 'feedback-1',
        'type': 'bug',
        'title': 'Calendrier vide',
        'message': 'Aucune date ne s’affiche.',
        'status': 'read',
        'created_at': '2026-09-01T10:00:00.000Z',
      });

      expect(model.id, 'feedback-1');
      expect(model.type, FeedbackType.bug);
      expect(model.status, FeedbackStatus.read);
      expect(model.createdAt.year, 2026);
    });

    test('survit à une réponse partielle', () {
      // Un champ manquant ne doit pas faire échouer toute la liste.
      final model = FeedbackModel.fromJson({'id': 'feedback-2'});

      expect(model.title, isEmpty);
      expect(model.type, FeedbackType.autre);
      expect(model.status, FeedbackStatus.newFeedback);
    });
  });
}

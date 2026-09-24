import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/features/property/data/models/property_model.dart';

void main() {
  group('PriceTierList — bornes d’un palier', () {
    test('le premier palier ne descend pas sous le minimum du serveur', () {
      const tiers = [
        PriceTier(minDays: 2, discountPercent: 10),
        PriceTier(minDays: 7, discountPercent: 20),
      ];

      // `vine.number().min(2)` : un palier à 1 jour serait refusé en 422.
      expect(PriceTierList.minDaysBounds(tiers, 0).min, 2);
    });

    test('un palier ne peut pas rejoindre la durée du suivant', () {
      const tiers = [
        PriceTier(minDays: 7, discountPercent: 10),
        PriceTier(minDays: 30, discountPercent: 20),
      ];

      // Deux paliers à la même durée : le second n'aurait aucun effet.
      expect(PriceTierList.minDaysBounds(tiers, 0).max, 29);
    });

    test('un palier ne peut pas passer sous la durée du précédent', () {
      const tiers = [
        PriceTier(minDays: 7, discountPercent: 10),
        PriceTier(minDays: 30, discountPercent: 20),
      ];

      expect(PriceTierList.minDaysBounds(tiers, 1).min, 8);
    });

    test('le dernier palier n’a pas de plafond de durée', () {
      const tiers = [PriceTier(minDays: 7, discountPercent: 10)];
      expect(PriceTierList.minDaysBounds(tiers, 0).max, isNull);
    });

    test('la remise reste dans les bornes du serveur', () {
      const tiers = [PriceTier(minDays: 7, discountPercent: 10)];
      final bounds = PriceTierList.discountBounds(tiers, 0);

      expect(bounds.min, 1);
      expect(bounds.max, 90);
    });

    test('une remise croît avec la durée : le palier suivant plafonne', () {
      const tiers = [
        PriceTier(minDays: 7, discountPercent: 10),
        PriceTier(minDays: 30, discountPercent: 20),
      ];

      // Un séjour plus long doit être au moins aussi avantageux : sans cette
      // borne, le palier long deviendrait inatteignable — `discountPercentFor`
      // retient le meilleur, jamais le dernier.
      expect(PriceTierList.discountBounds(tiers, 0).max, 19);
      expect(PriceTierList.discountBounds(tiers, 1).min, 11);
    });
  });

  group('PriceTierList — modification', () {
    test('allonger un palier au-delà du suivant est refusé', () {
      const tiers = [
        PriceTier(minDays: 7, discountPercent: 10),
        PriceTier(minDays: 14, discountPercent: 20),
      ];

      final updated = PriceTierList.replace(
        tiers,
        0,
        const PriceTier(minDays: 20, discountPercent: 10),
      );

      // La valeur est ramenée à la borne, jamais appliquée telle quelle : la
      // liste reste ordonnée et sans doublon par construction.
      expect(updated[0].minDays, 13);
      expect(updated[1].minDays, 14);
    });

    test('une remise dépassant le palier suivant est ramenée à la borne', () {
      const tiers = [
        PriceTier(minDays: 7, discountPercent: 10),
        PriceTier(minDays: 30, discountPercent: 20),
      ];

      final updated = PriceTierList.replace(
        tiers,
        0,
        const PriceTier(minDays: 7, discountPercent: 50),
      );

      expect(updated[0].discountPercent, 19);
    });

    test('la liste reste triée par durée croissante', () {
      const tiers = [
        PriceTier(minDays: 7, discountPercent: 10),
        PriceTier(minDays: 30, discountPercent: 20),
      ];

      final updated = PriceTierList.replace(
        tiers,
        1,
        const PriceTier(minDays: 30, discountPercent: 25),
      );

      expect(updated.map((t) => t.minDays), [7, 30]);
    });
  });

  group('PriceTierList — ajout', () {
    test('le premier palier suggéré est la semaine', () {
      final tiers = PriceTierList.appended(const []);

      expect(tiers.single.minDays, 7);
      expect(tiers.single.discountPercent, greaterThanOrEqualTo(1));
    });

    test('un palier ajouté est plus long et plus avantageux', () {
      final tiers = PriceTierList.appended(const [
        PriceTier(minDays: 7, discountPercent: 10),
      ]);

      expect(tiers.last.minDays, greaterThan(7));
      expect(tiers.last.discountPercent, greaterThan(10));
    });

    test('aucun palier n’est ajouté quand la remise est au plafond', () {
      const tiers = [PriceTier(minDays: 7, discountPercent: 90)];

      // Il ne reste aucune remise valide au-dessus : proposer un palier
      // produirait un doublon de pourcentage, sans effet.
      expect(PriceTierList.canAppend(tiers), isFalse);
      expect(PriceTierList.appended(tiers), tiers);
    });

    test('un ajout reste possible tant qu’une remise supérieure existe', () {
      const tiers = [PriceTier(minDays: 7, discountPercent: 89)];
      expect(PriceTierList.canAppend(tiers), isTrue);
      expect(PriceTierList.appended(tiers).last.discountPercent, 90);
    });
  });

  group('PriceTierList — cohérence d’une liste existante', () {
    test('une liste relue désordonnée est remise en ordre', () {
      // Les annonces enregistrées avant cette validation peuvent porter des
      // paliers dans n'importe quel ordre : l'écran doit les présenter
      // lisiblement plutôt que de refléter le désordre.
      const tiers = [
        PriceTier(minDays: 30, discountPercent: 20),
        PriceTier(minDays: 7, discountPercent: 10),
      ];

      expect(PriceTierList.sorted(tiers).map((t) => t.minDays), [7, 30]);
    });

    test('un palier historique sans effet est signalé', () {
      const tiers = [
        PriceTier(minDays: 7, discountPercent: 20),
        PriceTier(minDays: 30, discountPercent: 10),
      ];

      // 30 jours à 10 % n'est jamais retenu : à 30 jours, le palier 7 jours
      // offre déjà 20 %. Le propriétaire doit le savoir.
      expect(PriceTierList.isIneffective(tiers, 1), isTrue);
      expect(PriceTierList.isIneffective(tiers, 0), isFalse);
    });
  });
}

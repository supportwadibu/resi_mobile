import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/features/reservation/data/datasources/reservation_local_store.dart';

/// Ligne telle que `sqflite` la rend, après la migration en version 2.
Map<String, Object?> _row({
  String id = 'studio-1',
  String title = 'Studio meublé Cocody',
  Object? residenceId,
  Object? residenceName,
  Object? unitLabel,
}) {
  return {
    'id': id,
    'title': title,
    'daily_price': 25000,
    'residence_id': residenceId,
    'residence_name': residenceName,
    'unit_label': unitLabel,
  };
}

void main() {
  group('CachedProperty.fromRow', () {
    test('lit une unité rattachée à une résidence', () {
      final cached = CachedProperty.fromRow(
        _row(
          residenceId: 'resi-adja',
          residenceName: 'Resi Adja',
          unitLabel: 'Studio 1',
        ),
      );

      expect(cached.residenceId, 'resi-adja');
      expect(cached.residenceName, 'Resi Adja');
      expect(cached.unitLabel, 'Studio 1');
    });

    test('une ligne antérieure à la version 2 du schéma reste lisible', () {
      // `ALTER TABLE ADD COLUMN` laisse les lignes existantes à `NULL` : elles
      // valent « bien autonome », le comportement d'avant la migration.
      final cached = CachedProperty.fromRow({
        'id': 'villa',
        'title': 'Villa Belvédère',
        'daily_price': 60000,
        'residence_id': null,
        'residence_name': null,
        'unit_label': null,
      });

      expect(cached.residenceId, isNull);
      expect(cached.displayLabel, 'Villa Belvédère');
    });
  });

  group('CachedProperty.displayLabel', () {
    test('affiche « Résidence › Unité » pour une unité nommée', () {
      // C'est ce libellé qui rend la saisie comptoir utilisable : trois
      // « Studio 1 » de trois résidences différentes seraient sinon
      // indiscernables dans le sélecteur.
      final cached = CachedProperty.fromRow(
        _row(residenceName: 'Resi Adja', unitLabel: 'Studio 1'),
      );

      expect(cached.displayLabel, 'Resi Adja › Studio 1');
    });

    test('retombe sur le titre de l’annonce quand l’unité n’est pas nommée', () {
      final cached = CachedProperty.fromRow(
        _row(residenceName: 'Resi Adja', title: 'Studio meublé Cocody'),
      );

      expect(cached.displayLabel, 'Resi Adja › Studio meublé Cocody');
    });

    test('un bien autonome garde son seul titre', () {
      final cached = CachedProperty.fromRow(_row(title: 'Villa Belvédère'));

      expect(cached.displayLabel, 'Villa Belvédère');
    });

    test('un nom de résidence vide ne laisse pas de séparateur orphelin', () {
      // Le serveur peut renvoyer une chaîne vide plutôt qu'un `null` : afficher
      // « › Studio 1 » serait un défaut visible à l'écran.
      final cached = CachedProperty.fromRow(
        _row(residenceName: '   ', unitLabel: 'Studio 1'),
      );

      expect(cached.displayLabel, 'Studio meublé Cocody');
    });

    test('un libellé d’unité vide retombe sur le titre', () {
      final cached = CachedProperty.fromRow(
        _row(residenceName: 'Resi Adja', unitLabel: '  '),
      );

      expect(cached.displayLabel, 'Resi Adja › Studio meublé Cocody');
    });
  });
}

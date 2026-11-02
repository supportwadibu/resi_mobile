import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Cles attendues par `SyncResultListener`, avec leurs formes plurielles.
///
/// Une cle absente ne fait pas echouer `easy_localization` : elle s'affiche
/// telle quelle. Le gerant lirait « sync.rejected.one » au lieu du motif du
/// rejet, et le defaut ne se verrait qu'en production.
const _pluralKeys = ['sent', 'conflicts', 'rejected', 'failed'];

Map<String, dynamic> _load(String locale) {
  final file = File('assets/translations/$locale.json');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  group('traductions de la synchronisation', () {
    for (final locale in ['fr', 'en']) {
      test('$locale porte toutes les cles du rapport', () {
        final sync = _load(locale)['sync'] as Map<String, dynamic>?;

        expect(sync, isNotNull, reason: 'section "sync" absente en $locale');
        expect(sync!['done'], isA<String>());

        for (final key in _pluralKeys) {
          final entry = sync[key] as Map<String, dynamic>?;

          expect(entry, isNotNull, reason: 'sync.$key absente en $locale');
          expect(entry!['one'], isA<String>(), reason: 'sync.$key.one');
          expect(entry['other'], isA<String>(), reason: 'sync.$key.other');

          // Le pluriel porte le compte : sans le jeton, le message annoncerait
          // « reservations transmises » sans dire combien.
          expect(
            entry['other'],
            contains('{}'),
            reason: 'sync.$key.other doit interpoler le compte',
          );
        }
      });
    }

    test('le rejet ne se confond pas avec le conflit', () {
      // Un conflit s'arbitre, un rejet se constate : deux libelles distincts,
      // sans quoi le gerant attendrait un arbitrage qui ne viendra pas.
      for (final locale in ['fr', 'en']) {
        final sync = _load(locale)['sync'] as Map<String, dynamic>;
        final conflicts = sync['conflicts'] as Map<String, dynamic>;
        final rejected = sync['rejected'] as Map<String, dynamic>;

        expect(rejected['one'], isNot(equals(conflicts['one'])));
        expect(rejected['other'], isNot(equals(conflicts['other'])));
      }
    });
  });
}

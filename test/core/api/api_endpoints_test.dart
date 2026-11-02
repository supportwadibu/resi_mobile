import 'package:flutter_test/flutter_test.dart';

import 'package:resi_africa/core/api/api_endpoints.dart';

void main() {
  group('chemins par rôle', () {
    test('les réservations suivent le rôle', () {
      expect(ApiEndpoints.bookings('gerant'), '/api/v1/gerant/bookings');
      expect(ApiEndpoints.bookings('proprio'), '/api/v1/proprio/bookings');
    });

    test('une réservation nommée suit le rôle', () {
      expect(
        ApiEndpoints.booking('gerant', 'bk-1'),
        '/api/v1/gerant/bookings/bk-1',
      );
    });

    test('les compteurs de réservations suivent le rôle', () {
      // Écrits en dur sur le chemin propriétaire, ils rendaient un 403 au
      // gérant, que le cubit avalait : les compteurs disparaissaient de son
      // onglet Réservations au lieu d'afficher ses chiffres.
      expect(
        ApiEndpoints.bookingStats('gerant'),
        '/api/v1/gerant/bookings/stats',
      );
      expect(
        ApiEndpoints.bookingStats('proprio'),
        '/api/v1/proprio/bookings/stats',
      );
    });

    test('le carnet clients suit le rôle', () {
      expect(ApiEndpoints.clients('gerant'), '/api/v1/gerant/clients');
    });

    test('les dépenses suivent le rôle', () {
      expect(ApiEndpoints.expenses('gerant'), '/api/v1/gerant/expenses');
    });

    test('le relevé financier suit le rôle', () {
      expect(
        ApiEndpoints.financeOverview('gerant'),
        '/api/v1/gerant/finance/overview',
      );
    });

    test('le propriétaire garde exactement les chemins d’avant', () {
      // Aucune régression : les URLs produites pour le propriétaire doivent
      // rester identiques à celles des constantes qu'elles remplacent.
      expect(ApiEndpoints.clients('proprio'), '/api/v1/proprio/clients');
      expect(ApiEndpoints.expenses('proprio'), '/api/v1/proprio/expenses');
      expect(ApiEndpoints.properties('proprio'), '/api/v1/proprio/properties');
      expect(ApiEndpoints.residences('proprio'), '/api/v1/proprio/residences');
      expect(
        ApiEndpoints.financeOverview('proprio'),
        '/api/v1/proprio/finance/overview',
      );
    });
  });

  group('routes sans équivalent gérant', () {
    test('l’abonnement reste une constante propriétaire', () {
      // Pas de variante par rôle : un gérant n'a pas d'abonnement, et la
      // signature doit le dire plutôt que de produire une URL qui échouera.
      expect(ApiEndpoints.proprioSubscription, contains('/proprio/'));
    });

    test('le dépôt de photos reste propriétaire', () {
      expect(ApiEndpoints.proprioPropertyImages, contains('/proprio/'));
    });

    test('les rapports restent propriétaires', () {
      expect(ApiEndpoints.reports, contains('/proprio/'));
    });
  });

  group('gestion des gérants', () {
    test('le périmètre se remplace en bloc', () {
      expect(
        ApiEndpoints.proprioManagerProperties('mg-1'),
        '/api/v1/proprio/managers/mg-1/properties',
      );
    });

    test('le statut a sa propre route', () {
      expect(
        ApiEndpoints.proprioManagerStatus('mg-1'),
        '/api/v1/proprio/managers/mg-1/status',
      );
    });
  });
}

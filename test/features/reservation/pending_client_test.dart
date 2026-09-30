import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/features/clients/data/models/client_model.dart';
import 'package:resi_africa/features/reservation/data/datasources/reservation_local_store.dart';

void main() {
  group('PendingClient', () {
    test('la pièce et l’identité survivent à la file hors ligne', () {
      // Un client saisi sans réseau n'atteint le carnet qu'à la
      // synchronisation : ce qui ne passe pas par la ligne SQLite est perdu.
      final client = PendingClient(
        localId: 'local-1',
        fullName: 'Aya Traoré',
        phone: '0700000000',
        idDocumentType: ClientIdDocumentType.cni,
        idDocumentNumber: 'C0012345',
        identity: ClientIdentity(
          birthDate: DateTime(1990, 4, 12),
          birthPlace: 'Bouaké',
          nationality: 'Ivoirienne',
          address: 'Cocody Angré',
          idDocumentIssuedAt: DateTime(2021, 3, 12),
        ),
      );

      final read = PendingClient.fromRow({
        ...client.toRow(createdAt: 1000),
        'remote_id': null,
      });

      expect(read.idDocumentType, ClientIdDocumentType.cni);
      expect(read.idDocumentNumber, 'C0012345');
      expect(read.identity.birthDate, DateTime(1990, 4, 12));
      expect(read.identity.birthPlace, 'Bouaké');
      expect(read.identity.nationality, 'Ivoirienne');
      expect(read.identity.address, 'Cocody Angré');
      expect(read.identity.idDocumentIssuedAt, DateTime(2021, 3, 12));
    });

    test('une ligne antérieure à la v4 se lit sans identité', () {
      final read = PendingClient.fromRow({
        'local_id': 'local-1',
        'remote_id': null,
        'full_name': 'Aya',
        'phone': '0700000000',
        'document_front_path': null,
        'document_back_path': null,
        'created_at': 1000,
      });

      expect(read.idDocumentType, isNull);
      expect(read.identity.birthDate, isNull);
    });

    test('une identité illisible vaut une identité vide', () {
      final read = PendingClient.fromRow({
        'local_id': 'local-1',
        'full_name': 'Aya',
        'phone': '0700000000',
        'identity_fields': '{pas du json',
      });

      expect(read.identity.birthPlace, isNull);
    });
  });
}

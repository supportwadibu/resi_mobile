import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/features/auth/data/models/owner_profile_model.dart';
import 'package:resi_africa/features/auth/data/repositories/owner_profile_repository.dart';

/// Intercepteur qui court-circuite le réseau et mémorise la requête composée.
///
/// L'objectif est d'observer les en-têtes tels que Dio les a fusionnés, ce
/// qu'aucune inspection du code appelant ne permet de garantir.
class _CapturingInterceptor extends Interceptor {
  RequestOptions? captured;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    captured = options;
    handler.resolve(
      Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'data': {'full_name': 'Awa Koné', 'is_submitted': true},
        },
      ),
    );
  }
}

void main() {
  late Dio dio;
  late _CapturingInterceptor interceptor;
  late OwnerProfileRepository repository;

  setUp(() {
    // Mêmes en-têtes que le client réel : c'est le `Content-Type: application/
    // json` de `BaseOptions` qui entrait en conflit avec l'envoi multipart.
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://example.test',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
    interceptor = _CapturingInterceptor();
    dio.interceptors.add(interceptor);
    repository = OwnerProfileRepository(dio);
  });

  group('OwnerProfileRepository.submit', () {
    test('ne lève pas malgré le Content-Type JSON du client', () async {
      // Reproduit le crash observé : ArgumentError(contentType) levé par
      // `_RequestConfig` avant même que la requête ne parte.
      await expectLater(
        repository.submit(
          fullName: 'Awa Koné',
          phone: '+2250700000000',
          idDocumentType: IdDocumentType.cni,
          idDocumentNumber: 'CI001',
        ),
        completes,
      );
    });

    test('envoie un corps multipart, pas du JSON', () async {
      await repository.submit(
        fullName: 'Awa Koné',
        phone: '+2250700000000',
        idDocumentType: IdDocumentType.passport,
        idDocumentNumber: 'P42',
      );

      final sent = interceptor.captured!;
      expect(sent.data, isA<FormData>());
      expect(
        sent.headers[Headers.contentTypeHeader],
        startsWith(Headers.multipartFormDataContentType),
      );
      expect(
        sent.headers[Headers.contentTypeHeader],
        isNot(contains('application/json')),
      );
    });

    test('transmet les champs du dossier', () async {
      await repository.submit(
        fullName: 'Awa Koné',
        phone: '+2250700000000',
        idDocumentType: IdDocumentType.cni,
        idDocumentNumber: 'CI001',
        city: 'Abidjan',
        country: 'Ivory Coast',
      );

      final form = interceptor.captured!.data as FormData;
      final fields = Map.fromEntries(form.fields);

      expect(fields['full_name'], 'Awa Koné');
      expect(fields['id_document_type'], 'cni');
      expect(fields['city'], 'Abidjan');
      // Les champs facultatifs vides ne sont pas envoyés.
      expect(fields.containsKey('address'), isFalse);
    });

    test('le GET conserve le Content-Type JSON du client', () async {
      await repository.fetch();

      // La surcharge multipart doit rester locale au POST : la contaminer
      // ferait échouer toutes les autres requêtes du client.
      expect(
        interceptor.captured!.headers[Headers.contentTypeHeader],
        'application/json',
      );
    });
  });
}

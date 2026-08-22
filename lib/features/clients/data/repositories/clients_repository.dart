import 'package:dio/dio.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../models/client_model.dart';

/// Une page du carnet, avec de quoi savoir s'il en reste.
class ClientPage {
  const ClientPage({required this.items, required this.total, required this.page, required this.lastPage});

  final List<ClientModel> items;
  final int total;
  final int page;
  final int lastPage;

  bool get hasMore => page < lastPage;

  factory ClientPage.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List? ?? const [];
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};

    return ClientPage(
      items: data
          .map((e) => ClientModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      total: (meta['total'] as num?)?.toInt() ?? data.length,
      page: (meta['currentPage'] as num?)?.toInt() ?? 1,
      lastPage: (meta['lastPage'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Résultat de la recherche par numéro.
///
/// L'absence de fiche n'est pas une erreur : c'est le cas nominal d'un nouveau
/// client, et la saisie enchaîne.
class ClientLookup {
  const ClientLookup({required this.exists, this.client});

  final bool exists;
  final ClientModel? client;

  factory ClientLookup.fromJson(Map<String, dynamic> json) {
    final client = json['client'];
    return ClientLookup(
      exists: json['exists'] as bool? ?? false,
      client: client is Map<String, dynamic>
          ? ClientModel.fromJson(client)
          : null,
    );
  }
}

/// Carnet de clients du propriétaire connecté.
class ClientsRepository {
  const ClientsRepository(this._dio);
  final Dio _dio;

  /// Une page du carnet, la plus récemment modifiée d'abord.
  Future<ClientPage> getClientPage({
    String? query,
    ClientStatus? status,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.proprioClients,
        queryParameters: {
          if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
          if (status != null) 'status': status.code,
          'page': page,
          'per_page': perPage,
        },
      );
      return ClientPage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  /// Fiche complète, avec les URLs signées vers les pièces déposées.
  Future<ClientModel> getClient(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.proprioClient(id));
      final data = (response.data as Map<String, dynamic>)['data'];
      return ClientModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  /// Cherche une fiche par numéro pendant la saisie.
  ///
  /// Le téléphone identifie le client : proposer la fiche trouvée évite un
  /// doublon, et les statistiques de séjour restent justes.
  Future<ClientLookup> lookupByPhone(String phone) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.proprioClientLookup,
        data: {'phone': phone},
      );
      return ClientLookup.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  /// Enregistre un client, pièces d'identité comprises si elles sont fournies.
  ///
  /// Le serveur répond `already_existed` quand le numéro est déjà au carnet :
  /// aucune fiche n'est créée, et celle qui existe est retournée pour que
  /// l'application propose de la réutiliser.
  Future<({ClientModel client, bool alreadyExisted})> create({
    required String fullName,
    required String phone,
    String? whatsapp,
    ClientIdDocumentType? idDocumentType,
    String? idDocumentNumber,
    String? documentFrontPath,
    String? documentBackPath,
  }) async {
    try {
      final form = FormData.fromMap({
        'full_name': fullName,
        'phone': phone,
        if (whatsapp != null && whatsapp.isNotEmpty) 'whatsapp': whatsapp,
        if (idDocumentType != null) 'id_document_type': idDocumentType.code,
        if (idDocumentNumber != null && idDocumentNumber.isNotEmpty)
          'id_document_number': idDocumentNumber,
        if (documentFrontPath != null)
          'id_document_front': await _imageFile(documentFrontPath),
        if (documentBackPath != null)
          'id_document_back': await _imageFile(documentBackPath),
      });

      final response = await _dio.post(
        ApiEndpoints.proprioClients,
        data: form,
        options: Options(contentType: Headers.multipartFormDataContentType),
      );

      final body = response.data as Map<String, dynamic>;
      return (
        client: ClientModel.fromJson(body['data'] as Map<String, dynamic>),
        alreadyExisted: body['already_existed'] as bool? ?? false,
      );
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  /// Met à jour une fiche : coordonnées, pièces, ou archivage.
  Future<ClientModel> update(
    String id, {
    String? fullName,
    String? phone,
    String? whatsapp,
    ClientIdDocumentType? idDocumentType,
    String? idDocumentNumber,
    ClientStatus? status,
    String? documentFrontPath,
    String? documentBackPath,
  }) async {
    try {
      final form = FormData.fromMap({
        // `?` plutôt qu'un `if` : la clé n'est posée que si la valeur existe,
        // et un champ absent n'est pas envoyé — le serveur ne réécrit alors
        // que ce qui a changé.
        'full_name': ?fullName,
        'phone': ?phone,
        'whatsapp': ?whatsapp,
        if (idDocumentType != null) 'id_document_type': idDocumentType.code,
        'id_document_number': ?idDocumentNumber,
        if (status != null) 'status': status.code,
        if (documentFrontPath != null)
          'id_document_front': await _imageFile(documentFrontPath),
        if (documentBackPath != null)
          'id_document_back': await _imageFile(documentBackPath),
      });

      final response = await _dio.patch(
        ApiEndpoints.proprioClient(id),
        data: form,
        options: Options(contentType: Headers.multipartFormDataContentType),
      );

      final data = (response.data as Map<String, dynamic>)['data'];
      return ClientModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  /// Construit la partie fichier d'une pièce.
  ///
  /// Le nom est transmis explicitement : la validation serveur s'appuie sur
  /// l'extension pour reconnaître une image, et une partie sans nom serait
  /// refusée quel que soit son contenu.
  Future<MultipartFile> _imageFile(String path) {
    return MultipartFile.fromFile(path, filename: path.split(_separator).last);
  }

  /// Sépare les segments d'un chemin, indifféremment des conventions de l'OS.
  static final RegExp _separator = RegExp(r'[/\\]');
}

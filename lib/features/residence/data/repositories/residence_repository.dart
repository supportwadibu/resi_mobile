import 'package:dio/dio.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../../property/data/models/property_model.dart';
import '../models/residence_model.dart';

/// Résidences du propriétaire connecté.
class ResidenceRepository {
  const ResidenceRepository(this._dio);
  final Dio _dio;

  /// Une page de résidences, la plus récente d'abord.
  Future<ResidencePage> getResidencePage({int page = 1, int perPage = 20}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.proprioResidences,
        queryParameters: {'page': page, 'per_page': perPage},
      );
      return ResidencePage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  /// Toutes les résidences, pages comprises.
  ///
  /// Sert aux sélecteurs, qui doivent proposer l'ensemble et non la première
  /// page. Les pages sont parcourues en série, comme pour les dépenses : les
  /// lancer toutes d'un coup exposerait à une limitation de débit.
  Future<List<ResidenceModel>> getAllResidences() async {
    final all = <ResidenceModel>[];
    var page = 1;

    while (true) {
      final result = await getResidencePage(page: page, perPage: 100);
      all.addAll(result.items);
      if (!result.hasMore) break;
      page++;
    }

    return all;
  }

  Future<ResidenceModel> getResidence(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.proprioResidence(id));
      final data = (response.data as Map<String, dynamic>)['data'];
      return ResidenceModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  Future<ResidenceModel> createResidence(CreateResidencePayload payload) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.proprioResidences,
        data: payload.toJson(),
      );
      final data = (response.data as Map<String, dynamic>)['data'];
      return ResidenceModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  Future<ResidenceModel> updateResidence(
    String id,
    UpdateResidencePayload payload,
  ) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.proprioResidence(id),
        data: payload.toJson(),
      );
      final data = (response.data as Map<String, dynamic>)['data'];
      return ResidenceModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  /// Supprime une résidence.
  ///
  /// Refusée en 409 (`residence_has_units`) tant qu'elle porte des logements :
  /// ceux-ci portent des réservations et un historique, et ne sont jamais
  /// supprimés en cascade. Lire le `statusCode` pour distinguer ce cas, jamais
  /// le texte du message.
  Future<void> deleteResidence(String id) async {
    try {
      await _dio.delete(ApiEndpoints.proprioResidence(id));
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  /// Rattache un bien à une résidence, ou l'en détache avec `residenceId: null`.
  ///
  /// `copyAddress` recopie l'adresse de la résidence sur le bien. Explicite, et
  /// non implicite : un bien déjà publié porte une adresse que ses annonces
  /// affichent, et l'écraser en silence changerait ce que le client a vu.
  Future<PropertyModel> attachToResidence(
    String propertyId, {
    required String? residenceId,
    String? unitLabel,
    bool copyAddress = false,
  }) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.proprioPropertyResidence(propertyId),
        data: {
          'residence_id': residenceId,
          'unit_label': unitLabel,
          if (copyAddress) 'copy_address': true,
        },
      );
      final data = (response.data as Map<String, dynamic>)['data'];
      return PropertyModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }
}

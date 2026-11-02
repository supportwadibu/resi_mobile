import 'package:dio/dio.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../models/sponsorship_model.dart';

/// Parrainage du compte connecté.
///
/// Sans cache hors ligne, comme le portefeuille : des gains affichés hors
/// réseau pourraient être déjà dépensés, et une demande ne se met pas en file.
class SponsorshipRepository {
  const SponsorshipRepository(this._dio);

  final Dio _dio;

  Future<SponsorshipOverview> getOverview() => _guard(() async {
    final response = await _dio.get(ApiEndpoints.sponsorship);
    return SponsorshipOverview.fromJson(
      _data(response) as Map<String, dynamic>,
    );
  });

  Future<List<SponsoredUser>> getSponsored() => _guard(() async {
    final response = await _dio.get(ApiEndpoints.sponsorshipSponsored);
    return (_data(response) as List)
        .whereType<Map<String, dynamic>>()
        .map(SponsoredUser.fromJson)
        .toList(growable: false);
  });

  /// Dernières demandes, de la plus récente à la plus ancienne.
  Future<List<RedemptionModel>> getRedemptions({int perPage = 20}) =>
      _guard(() async {
        final response = await _dio.get(
          ApiEndpoints.sponsorshipRedemptions,
          queryParameters: {'per_page': perPage},
        );
        return (_data(response) as List)
            .whereType<Map<String, dynamic>>()
            .map(RedemptionModel.fromJson)
            .toList(growable: false);
      });

  /// Vérifie un code avant de l'envoyer avec l'inscription. Un 404 dit qu'il
  /// n'existe pas.
  Future<SponsorshipCodeCheck> checkCode(String code) => _guard(() async {
    final response = await _dio.get(ApiEndpoints.sponsorshipCode(code));
    return SponsorshipCodeCheck.fromJson(
      _data(response) as Map<String, dynamic>,
    );
  });

  /// Rattache le compte au parrain dont le code est saisi. Un 422 dit
  /// pourquoi — code inconnu, délai passé, premier paiement déjà fait.
  Future<void> applyCode(String code) => _guard(() async {
    await _dio.post(ApiEndpoints.sponsorshipApply, data: {'code': code});
  });

  /// Retrait Wave ou conversion. Seuil et solde sont vérifiés au serveur, au
  /// moment du débit ; son message dit ce qui manque.
  Future<RedemptionModel> requestRedemption({
    required RedemptionType type,
    required int amount,
    String? payoutPhone,
    String? payoutName,
  }) => _guard(() async {
    final response = await _dio.post(
      ApiEndpoints.sponsorshipRedemptions,
      data: {
        'type': type.code,
        'amount': amount,
        'payout_phone': ?payoutPhone,
        'payout_name': ?payoutName,
      },
    );
    return RedemptionModel.fromJson(_data(response) as Map<String, dynamic>);
  });

  Object? _data(Response<dynamic> response) =>
      (response.data as Map<String, dynamic>)['data'];

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }
}

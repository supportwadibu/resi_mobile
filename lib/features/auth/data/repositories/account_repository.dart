import 'package:dio/dio.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/offline/offline_cache_interceptor.dart';
import '../models/account_deletion_model.dart';

/// Compte de l'utilisateur connecté, quel que soit son rôle.
class AccountRepository {
  const AccountRepository(this._dio);

  final Dio _dio;

  Future<AccountDeletionPreview> fetchDeletionPreview() async {
    try {
      final res = await _dio.get(ApiEndpoints.accountDeletion);
      final data = res.data as Map<String, dynamic>;
      return AccountDeletionPreview.fromJson(
        data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw AppFailure.fromDio(e);
    }
  }

  /// Ferme le compte. Le serveur révoque aussitôt toutes les sessions : la
  /// suite (purge locale, retour à la connexion) revient à l'appelant.
  ///
  /// `confirm` est exigé par l'API, qui refuse un corps vide : une requête
  /// rejouée par erreur ne doit pas fermer un compte. Pas de rejeu
  /// automatique non plus : après un délai dépassé, la première tentative a pu
  /// aboutir, et la seconde tomberait sur un compte déjà fermé — un 401 qui
  /// ferait croire à l'échec d'une suppression réussie.
  Future<void> deleteAccount({String? reason}) async {
    try {
      await _dio.delete(
        ApiEndpoints.account,
        data: {
          'confirm': true,
          if (reason != null && reason.trim().isNotEmpty)
            'reason': reason.trim(),
        },
        options: Options(extra: {noRetryExtra: true}),
      );
    } on DioException catch (e) {
      throw AppFailure.fromDio(e);
    }
  }
}

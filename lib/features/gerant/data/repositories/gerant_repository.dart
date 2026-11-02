import 'package:dio/dio.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/session/session_role.dart';
import '../models/gerant_account_model.dart';
import '../models/gerant_overview_model.dart';

/// Relevé du mois d'un gérant, sur les seuls logements qui lui sont confiés.
///
/// Séparé du `FinanceRepository` bien que la route ne diffère que par son
/// préfixe : le serveur y rend un `ManagerOverviewDto`, de forme distincte et
/// sans revenu net. Les mêler derrière un seul repository rendrait un jour un
/// `FinanceOverviewModel` au gérant, dont le bénéfice net retomberait à zéro
/// sans que rien ne le signale.
class GerantRepository {
  const GerantRepository(this._dio, this._role);

  final Dio _dio;
  final SessionRole _role;

  /// Réservations, encaissements bruts et taux d'occupation sur une période.
  ///
  /// `ApiEndpoints.financeOverview` porte déjà la bascule de préfixe : appelée
  /// avec le rôle de la session, elle vise `/gerant/finance/overview`. Le rôle
  /// n'est pas forcé à `'gerant'` ici — un propriétaire qui atteindrait cet
  /// appel doit échouer visiblement plutôt que lire un relevé tronqué.
  Future<GerantOverviewModel> getOverview({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.financeOverview(_role.value),
        queryParameters: {
          if (from != null) 'from': _formatDate(from),
          if (to != null) 'to': _formatDate(to),
        },
      );
      final data = (response.data as Map<String, dynamic>)['data'];
      return GerantOverviewModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  /// Compte du gérant connecté : nom, coordonnées, périmètre, état.
  ///
  /// `GerantAccountModel` est réutilisé tel quel — le serveur sert le même
  /// `ManagerDto` ici et sur `/proprio/managers`, où le propriétaire lit la
  /// fiche de ses gérants. Un second modèle des mêmes champs finirait par en
  /// diverger sans que rien ne le signale.
  ///
  /// Le chemin est fixe et n'emprunte pas `_role` : `/proprio/profile` rend un
  /// dossier de validation, pas un compte. Un propriétaire qui atteindrait cet
  /// appel doit échouer visiblement plutôt que de lire une forme qu'il ne sait
  /// pas interpréter.
  Future<GerantAccountModel> getProfile() async {
    try {
      final response = await _dio.get(ApiEndpoints.gerantProfile);
      final data = (response.data as Map<String, dynamic>)['data'];
      return GerantAccountModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

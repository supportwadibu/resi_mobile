import 'package:dio/dio.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../models/finance/finance_overview_model.dart';

/// Situation financière du propriétaire connecté : revenus, charges, bénéfice.
class FinanceRepository {
  const FinanceRepository(this._dio);
  final Dio _dio;

  /// Revenus, charges et bénéfice sur une période.
  ///
  /// [residenceId] restreint le relevé à une résidence : le revenu de ses
  /// logements, ses charges communes et celles de ses logements. Le taux
  /// d’occupation est alors rapporté à ses seules unités, et non au parc entier.
  ///
  /// Une résidence inconnue répond 404 — lire le `statusCode`, jamais le texte
  /// du message.
  Future<FinanceOverviewModel> getOverview({
    DateTime? from,
    DateTime? to,
    String? residenceId,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.proprioFinanceOverview,
        queryParameters: {
          if (from != null) 'from': _formatDate(from),
          if (to != null) 'to': _formatDate(to),
          'residence_id': ?residenceId,
        },
      );
      final data = (response.data as Map<String, dynamic>)['data'];
      return FinanceOverviewModel.fromJson(data as Map<String, dynamic>);
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

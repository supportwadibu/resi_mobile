import 'package:dio/dio.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../models/expense_model.dart';

/// Dépenses du propriétaire connecté.
class ExpenseRepository {
  const ExpenseRepository(this._dio);
  final Dio _dio;

  /// Une page de dépenses, la plus récente d'abord.
  ///
  /// L'API répond `{ data: [...], meta: {...} }` : le bloc `meta` est conservé
  /// pour que l'écran sache s'il reste des pages à charger.
  Future<ExpensePage> getExpensePage({
    String? propertyId,
    String? residenceId,
    ExpenseCategory? category,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.proprioExpenses,
        queryParameters: {
          ...?_filters(
            propertyId: propertyId,
            residenceId: residenceId,
            category: category,
            from: from,
            to: to,
          ),
          'page': page,
          'per_page': perPage,
        },
      );
      return ExpensePage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  /// Toutes les dépenses correspondant aux filtres, pages comprises.
  ///
  /// Réservé à l'export, qui doit porter sur l'ensemble et non sur ce qui est
  /// affiché. Les pages sont parcourues en série : le nombre d'appels dépend du
  /// volume, et les lancer tous d'un coup exposerait à une limitation de débit.
  Future<List<ExpenseModel>> getAllExpenses({
    String? propertyId,
    String? residenceId,
    ExpenseCategory? category,
    DateTime? from,
    DateTime? to,
  }) async {
    final all = <ExpenseModel>[];
    var page = 1;

    while (true) {
      final result = await getExpensePage(
        propertyId: propertyId,
        residenceId: residenceId,
        category: category,
        from: from,
        to: to,
        page: page,
        perPage: 100,
      );

      all.addAll(result.items);
      if (!result.hasMore || result.items.isEmpty) break;
      page++;
    }

    return all;
  }

  /// Total et ventilation par catégorie, sur les mêmes filtres que la liste.
  Future<ExpenseSummary> getSummary({
    String? propertyId,
    String? residenceId,
    ExpenseCategory? category,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.proprioExpenseSummary,
        queryParameters: _filters(
          propertyId: propertyId,
          residenceId: residenceId,
          category: category,
          from: from,
          to: to,
        ),
      );
      final data = (response.data as Map<String, dynamic>)['data'];
      return ExpenseSummary.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  Future<ExpenseModel> create(CreateExpensePayload payload) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.proprioExpenses,
        data: payload.toJson(),
      );
      final data = (response.data as Map<String, dynamic>)['data'];
      return ExpenseModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  Future<ExpenseModel> update(String id, UpdateExpensePayload payload) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.proprioExpense(id),
        data: payload.toJson(),
      );
      final data = (response.data as Map<String, dynamic>)['data'];
      return ExpenseModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete(ApiEndpoints.proprioExpense(id));
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  /// Filtres non nuls uniquement : une clé vide serait refusée par le
  /// validateur, qui attend une valeur ou rien.
  Map<String, dynamic>? _filters({
    String? propertyId,
    String? residenceId,
    ExpenseCategory? category,
    DateTime? from,
    DateTime? to,
  }) {
    final params = <String, dynamic>{
      if (propertyId != null && propertyId.isNotEmpty) 'property_id': propertyId,
      // Filtre les charges communes du lieu. Les deux filtres ne se combinent
      // pas utilement : une dépense ne porte jamais les deux rattachements.
      if (residenceId != null && residenceId.isNotEmpty)
        'residence_id': residenceId,
      if (category != null) 'category': category.code,
      if (from != null) 'from': _formatDate(from),
      if (to != null) 'to': _formatDate(to),
    };

    return params.isEmpty ? null : params;
  }

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

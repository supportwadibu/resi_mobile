import 'package:dio/dio.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../models/wallet_model.dart';

/// Portefeuilles et retraits du propriétaire connecté.
///
/// Sans cache hors ligne : un solde affiché hors réseau pourrait être déjà
/// retiré, et une demande de retrait ne se met pas en file.
class WalletRepository {
  const WalletRepository(this._dio);

  final Dio _dio;

  Future<List<WalletModel>> getWallets() async {
    try {
      final response = await _dio.get(ApiEndpoints.proprioWallets);
      final data = (response.data as Map<String, dynamic>)['data'] as List;
      return data
          .whereType<Map<String, dynamic>>()
          .map(WalletModel.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  /// Dernières demandes de retrait, toutes résidences confondues.
  Future<List<WithdrawalModel>> getWithdrawals({int perPage = 20}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.proprioWithdrawals,
        queryParameters: {'per_page': perPage},
      );
      final data = (response.data as Map<String, dynamic>)['data'] as List;
      return data
          .whereType<Map<String, dynamic>>()
          .map(WithdrawalModel.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  /// Demande un retrait. Un 422 signale un solde insuffisant ou un montant
  /// sous le minimum ; le message du serveur le dit.
  Future<WithdrawalModel> requestWithdrawal(
    String walletId, {
    required int amount,
    required String payoutPhone,
    String? payoutName,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.proprioWalletWithdrawals(walletId),
        data: {
          'amount': amount,
          'payout_phone': payoutPhone,
          if (payoutName != null && payoutName.trim().isNotEmpty)
            'payout_name': payoutName.trim(),
        },
      );
      final data = (response.data as Map<String, dynamic>)['data'];
      return WithdrawalModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }
}

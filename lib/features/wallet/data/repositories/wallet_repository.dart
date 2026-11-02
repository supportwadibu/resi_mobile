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

  /// Une page du journal d'un portefeuille, du plus récent au plus ancien.
  Future<WalletTransactionPage> getTransactions(
    String walletId, {
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.proprioWalletTransactions(walletId),
        queryParameters: {'page': page, 'per_page': perPage},
      );
      return WalletTransactionPage.fromJson(
        response.data as Map<String, dynamic>,
      );
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

  /// Retrait minimal réglé par l'équipe et numéros Wave enregistrés.
  Future<PayoutSettings> getPayoutSettings() async {
    try {
      final response = await _dio.get(ApiEndpoints.proprioPayoutSettings);
      final data = (response.data as Map<String, dynamic>)['data'];
      return PayoutSettings.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  /// Remplace les numéros Wave enregistrés. Un 422 dit pourquoi un numéro
  /// est refusé — format, doublon.
  Future<List<PayoutNumber>> savePayoutNumbers(
    List<PayoutNumber> numbers,
  ) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.proprioPayoutNumbers,
        data: {'numbers': numbers.map((n) => n.toJson()).toList()},
      );
      final data = (response.data as Map<String, dynamic>)['data'] as List;
      return data
          .whereType<Map<String, dynamic>>()
          .map(PayoutNumber.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  /// Demande un retrait vers le numéro Wave enregistré [payoutSlot]. Un 422
  /// signale un solde insuffisant, un montant sous le minimum ou un numéro
  /// retiré entre-temps ; le message du serveur le dit.
  Future<WithdrawalModel> requestWithdrawal(
    String walletId, {
    required int amount,
    required int payoutSlot,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.proprioWalletWithdrawals(walletId),
        data: {'amount': amount, 'payout_slot': payoutSlot},
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

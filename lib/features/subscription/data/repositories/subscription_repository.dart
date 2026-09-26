import 'package:dio/dio.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../models/subscription_plan_model.dart';

/// Forfaits et paiement Wave de l'abonnement.
///
/// Ces routes restent ouvertes à un compte inactif : c'est par elles qu'il
/// redevient actif.
class SubscriptionRepository {
  SubscriptionRepository(this._dio);

  final Dio _dio;

  Future<List<SubscriptionPlanModel>> fetchPlans() async {
    try {
      final response = await _dio.get(ApiEndpoints.proprioPlans);
      final data = (response.data as Map<String, dynamic>)['data'];
      return (data as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(SubscriptionPlanModel.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  /// Lance le paiement d'un forfait. Le serveur refuse (409) un changement de
  /// palier en cours de période : le message renvoyé est affichable tel quel.
  Future<SubscriptionCheckoutModel> startCheckout(String planId) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.proprioSubscriptionCheckout,
        data: {'plan_id': planId},
      );
      final data = (response.data as Map<String, dynamic>)['data'];
      return SubscriptionCheckoutModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  /// Demande au serveur de constater l'issue du paiement chez Wave.
  Future<SubscriptionPaymentStatus> confirm(String reference) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.proprioSubscriptionConfirm(reference),
      );
      final data = (response.data as Map<String, dynamic>)['data'];
      return SubscriptionPaymentStatus.fromCode(
        (data as Map<String, dynamic>)['status'] as String?,
      );
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }
}

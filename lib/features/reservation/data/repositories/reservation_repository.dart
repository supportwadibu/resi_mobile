import 'package:dio/dio.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../models/occupied_period_model.dart';
import '../models/reservation_model.dart';

/// Une page de réservations, avec de quoi savoir s'il en reste.
class ReservationPage {
  const ReservationPage({
    required this.items,
    required this.total,
    required this.page,
    required this.lastPage,
  });

  final List<ReservationModel> items;
  final int total;
  final int page;
  final int lastPage;

  bool get hasMore => page < lastPage;

  factory ReservationPage.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List? ?? const [];
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};

    return ReservationPage(
      items: data
          .map((e) => ReservationModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      total: (meta['total'] as num?)?.toInt() ?? data.length,
      page: (meta['currentPage'] as num?)?.toInt() ?? 1,
      lastPage: (meta['lastPage'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Réservations reçues par le propriétaire connecté.
class ReservationRepository {
  const ReservationRepository(this._dio);
  final Dio _dio;

  /// Une page de réservations, la plus récente d'abord.
  Future<ReservationPage> getReservationPage({
    String? propertyId,
    ReservationStatus? status,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.proprioBookings,
        queryParameters: {
          if (propertyId != null && propertyId.isNotEmpty)
            'property_id': propertyId,
          if (status != null) 'status': status.code,
          'page': page,
          'per_page': perPage,
        },
      );
      return ReservationPage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  /// Première page seulement — conservé pour les écrans qui n'exploitent pas
  /// encore la pagination.
  Future<List<ReservationModel>> getReservationList() async {
    final page = await getReservationPage();
    return page.items;
  }

  /// Enregistre une réservation prise au comptoir.
  ///
  /// [clientRequestId] rend la création idempotente : sur un réseau instable,
  /// un envoi qui expire puis se rejoue ne doit pas produire deux réservations
  /// pour un même client. Le serveur reconnaît l'identifiant et renvoie la
  /// réservation déjà créée.
  Future<ReservationModel> createOwnerBooking({
    required String propertyId,
    required String clientId,
    required StayType stayType,
    required DateTime checkInAt,
    DateTime? checkOutAt,
    double? receivedAmount,
    double? depositAmount,
    String? message,
    bool isCheckIn = false,
    String? clientRequestId,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.proprioBookings,
        data: {
          'property_id': propertyId,
          'client_id': clientId,
          'stay_type': stayType.code,
          'check_in_at': checkInAt.toUtc().toIso8601String(),
          if (checkOutAt != null)
            'check_out_at': checkOutAt.toUtc().toIso8601String(),
          // `?` plutôt qu'un `if` : la clé n'est posée que si la valeur
          // existe, et le serveur applique alors sa propre valeur par défaut.
          'received_amount': ?receivedAmount,
          'deposit_amount': ?depositAmount,
          if (message != null && message.isNotEmpty) 'message': message,
          'is_check_in': isCheckIn,
          'client_request_id': ?clientRequestId,
        },
      );

      final data = (response.data as Map<String, dynamic>)['data'];
      return ReservationModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  /// Clôture un séjour : enregistre la sortie et cumule le montant sur la
  /// fiche du client.
  Future<ReservationModel> checkOut(String id) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.proprioBookingCheckOut(id),
      );
      final data = (response.data as Map<String, dynamic>)['data'];
      return ReservationModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  /// Prolonge un séjour comptoir.
  ///
  /// `receivedAmount` est le montant renégocié ; à défaut, le serveur
  /// réajuste sur le nouveau montant attendu — laisser l’ancien montant
  /// ferait apparaître un impayé qui n’existe pas.
  ///
  /// Un 409 est un conflit de période : le bien est déjà réservé sur la
  /// période demandée, à arbitrer par le propriétaire.
  Future<ReservationModel> extend(
    String id, {
    required DateTime checkOutAt,
    num? receivedAmount,
  }) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.proprioBookingExtend(id),
        data: {
          'check_out_at': checkOutAt.toUtc().toIso8601String(),
          // `?` plutôt qu'un `if`, comme à la création : sans la clé, le
          // serveur réajuste sur le montant attendu.
          'received_amount': ?receivedAmount,
        },
      );
      final data = (response.data as Map<String, dynamic>)['data'];
      return ReservationModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  /// Périodes déjà réservées sur un bien.
  ///
  /// Consultées avant la saisie : le propriétaire doit voir les dates prises
  /// plutôt que d'essuyer un refus une fois le formulaire rempli.
  Future<List<OccupiedPeriodModel>> getAvailability({
    required String propertyId,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.proprioPropertyAvailability,
        queryParameters: {
          'property_id': propertyId,
          if (from != null) 'from': from.toUtc().toIso8601String(),
          if (to != null) 'to': to.toUtc().toIso8601String(),
        },
      );

      final data = (response.data as Map<String, dynamic>)['data'] as List? ??
          const [];
      return data
          .map((e) => OccupiedPeriodModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }
}

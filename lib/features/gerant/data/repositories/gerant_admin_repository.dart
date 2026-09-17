import 'package:dio/dio.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../models/gerant_account_model.dart';

/// Messages affichables pour les refus métier de la gestion des gérants.
///
/// Indexés sur le **code** et non sur le statut HTTP : deux refus en 422 y
/// cohabitent, et surtout `AppFailure.validation` écrase le message du serveur
/// quand la réponse ne porte pas de clé `errors` — ce qui est justement le cas
/// des refus métier. Le texte rendu par l'API est donc inutilisable ici ; le
/// code, lui, est stable.
///
/// Défaut connu et volontairement non corrigé ici : il touche toute
/// l'application et déborde largement la gestion des gérants.
const _gerantErrorMessages = <String, String>{
  'manager_already_exists': 'Un compte existe déjà avec ces coordonnées.',
  'manager_contact_required': 'Renseignez un e-mail ou un téléphone.',
  'property_not_owned':
      'Un des logements sélectionnés ne vous appartient pas.',
  'manager_not_found': 'Ce gérant est introuvable.',
};

/// Traduit un refus métier en message affichable, ou rend l'échec inchangé.
///
/// Rendre l'échec tel quel quand le code est inconnu est délibéré : une panne
/// de transport ou un refus nouveau doit continuer à dire ce qu'il est plutôt
/// que d'être repeint en erreur de gérant.
AppFailure translateGerantFailure(AppFailure failure) {
  final message = _gerantErrorMessages[failure.code];
  if (message == null) return failure;

  return AppFailure.validation(
    errors: {
      '_': [message],
    },
    statusCode: failure.statusCode ?? 422,
    code: failure.code,
  );
}

/// Comptes gérants du propriétaire connecté : ouverture, périmètre, statut.
///
/// Distinct du `GerantRepository` voisin, qui sert le **relevé financier** lu
/// par le gérant lui-même. Ici c'est le propriétaire qui agit, sur les routes
/// `/proprio/managers`, et le préfixe n'est donc jamais dérivé du rôle de
/// session : ces routes sont fermées au gérant par construction.
class GerantAdminRepository {
  const GerantAdminRepository(this._dio);

  final Dio _dio;

  Future<List<GerantAccountModel>> list() async {
    return _guard(() async {
      final response = await _dio.get(ApiEndpoints.proprioManagers);
      final data = (response.data as Map<String, dynamic>)['data'];
      return [
        for (final item in data as List<dynamic>? ?? const [])
          GerantAccountModel.fromJson(item as Map<String, dynamic>),
      ];
    });
  }

  Future<GerantAccountModel> get(String id) {
    return _guard(() async {
      final response = await _dio.get(ApiEndpoints.proprioManager(id));
      return _one(response);
    });
  }

  /// Ouvre le compte et pose son périmètre en une seule requête.
  Future<GerantAccountModel> create(CreateGerantPayload payload) {
    return _guard(() async {
      final response = await _dio.post(
        ApiEndpoints.proprioManagers,
        data: payload.toJson(),
      );
      return _one(response);
    });
  }

  Future<GerantAccountModel> update(String id, UpdateGerantPayload payload) {
    return _guard(() async {
      final response = await _dio.patch(
        ApiEndpoints.proprioManager(id),
        data: payload.toJson(),
      );
      return _one(response);
    });
  }

  /// Remplace le périmètre entier — `PUT`, jamais un ajout.
  ///
  /// [propertyIds] est la liste voulue au complet : les logements absents sont
  /// retirés. Envoyer le seul ajout retirerait tous les autres en silence.
  Future<GerantAccountModel> replaceProperties(
    String id,
    List<String> propertyIds,
  ) {
    return _guard(() async {
      final response = await _dio.put(
        ApiEndpoints.proprioManagerProperties(id),
        data: {'property_ids': propertyIds},
      );
      return _one(response);
    });
  }

  /// Suspend ou réactive le gérant.
  ///
  /// La suspension ne supprime rien : l'affectation et l'historique des
  /// réservations qu'il a saisies restent, seul l'accès est coupé.
  Future<GerantAccountModel> setStatus(String id, {required bool isActive}) {
    return _guard(() async {
      final response = await _dio.patch(
        ApiEndpoints.proprioManagerStatus(id),
        data: {'is_active': isActive},
      );
      return _one(response);
    });
  }

  static GerantAccountModel _one(Response<dynamic> response) {
    final data = (response.data as Map<String, dynamic>)['data'];
    return GerantAccountModel.fromJson(data as Map<String, dynamic>);
  }

  /// Exécute un appel et n'en laisse sortir que des `AppFailure` traduites.
  ///
  /// Facteur commun aux six routes : aucune `DioException` ne doit franchir le
  /// repository, et les quatre refus métier doivent porter leur message dès
  /// ici — l'écran qui les affiche n'a pas à connaître les codes de l'API.
  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw translateGerantFailure(mapDioExceptionToFailure(e));
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }
}

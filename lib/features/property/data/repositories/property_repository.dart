import 'package:dio/dio.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/session/session_role.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../models/property_model.dart';

/// Annonces du propriétaire connecté.
class PropertyRepository {
  const PropertyRepository(this._dio, this._role);

  final Dio _dio;
  final SessionRole _role;

  /// Liste paginée des annonces.
  ///
  /// L'API répond `{ data: [...], meta: {...} }` : seule la page courante est
  /// retournée ici, la pagination n'étant pas encore exploitée par l'écran.
  /// Biens du propriétaire connecté.
  ///
  /// [residenceId] restreint la liste aux unités d'une résidence, pour sa
  /// fiche de détail. Le contrôle de propriété reste au serveur : le filtre
  /// s'ajoute au périmètre du compte, il ne l'élargit pas.
  Future<List<PropertyModel>> getPropertyList({String? residenceId}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.properties(_role.value),
        queryParameters: {
          if (residenceId != null && residenceId.isNotEmpty)
            'residence_id': residenceId,
        },
      );
      final data = (response.data as Map<String, dynamic>)['data'] as List;
      return data
          .map((e) => PropertyModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  /// Une page de biens, avec son bloc `meta`.
  ///
  /// L'API plafonne `per_page` à 100 et retombe à 20 quand il est absent :
  /// le paramètre est donc toujours transmis, faute de quoi le serveur
  /// tronque silencieusement la liste sans que la réponse ne le signale
  /// autrement que par `meta`.
  Future<PropertyPage> getPropertyPage({
    String? residenceId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.properties(_role.value),
        queryParameters: {
          if (residenceId != null && residenceId.isNotEmpty)
            'residence_id': residenceId,
          'page': page,
          'per_page': perPage,
        },
      );
      return PropertyPage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  /// Tous les biens du propriétaire, pages comprises.
  ///
  /// Sert aux sélecteurs — celui du périmètre d'un gérant en particulier —,
  /// qui doivent proposer l'ensemble du parc : sur la seule première page, le
  /// 21e logement d'un propriétaire restait invisible, donc impossible à
  /// confier. Les pages sont parcourues en série, comme pour les résidences et
  /// les dépenses : les lancer toutes d'un coup exposerait à une limitation de
  /// débit.
  ///
  /// Une page vide interrompt aussi la boucle : un `meta` qui annoncerait
  /// toujours une page suivante ferait tourner l'appelant sans fin.
  Future<List<PropertyModel>> getAllProperties({String? residenceId}) async {
    final all = <PropertyModel>[];
    var page = 1;

    while (true) {
      final result = await getPropertyPage(
        residenceId: residenceId,
        page: page,
        perPage: 100,
      );

      all.addAll(result.items);
      if (!result.hasMore || result.items.isEmpty) break;
      page++;
    }

    return all;
  }

  /// Dépose les photos et retourne leurs URLs publiques, dans l'ordre.
  ///
  /// Appelé avant [create] : le serveur attend des URLs dans `media.images`,
  /// pas des fichiers. Un lot vide n'appelle aucune requête.
  Future<List<String>> uploadImages(List<String> filePaths) async {
    if (filePaths.isEmpty) return const [];

    try {
      final form = FormData();
      for (final path in filePaths) {
        form.files.add(
          MapEntry(
            'images',
            await MultipartFile.fromFile(
              path,
              // La validation serveur s'appuie sur l'extension : une partie
              // sans nom serait refusée quel que soit son contenu.
              filename: path.split(_separator).last,
            ),
          ),
        );
      }

      final response = await _dio.post(
        ApiEndpoints.proprioPropertyImages,
        data: form,
        // Le client pose `application/json` par défaut : le surcharger via
        // `contentType` — et non via l'en-tête — est le seul moyen de le
        // remplacer sans conflit dans `Options.compose`.
        options: Options(contentType: Headers.multipartFormDataContentType),
      );

      final data = (response.data as Map<String, dynamic>)['data'];
      return ((data as Map<String, dynamic>)['images'] as List)
          .cast<String>()
          .toList();
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  /// Crée l'annonce et retourne sa version enregistrée.
  Future<PropertyModel> create(CreatePropertyPayload payload) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.properties(_role.value),
        data: payload.toJson(),
      );
      final data = (response.data as Map<String, dynamic>)['data'];
      return PropertyModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  /// Applique les modifications et retourne la fiche à jour.
  ///
  /// Le payload ne porte que les écarts : voir [UpdatePropertyPayload], dont
  /// dépend le fait que les photos et les paliers de remise ne soient pas
  /// réécrits inutilement.
  Future<PropertyModel> update(String id, UpdatePropertyPayload payload) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.property(_role.value, id),
        data: payload.toJson(),
      );
      final data = (response.data as Map<String, dynamic>)['data'];
      return PropertyModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  /// Rend l'annonce visible du public.
  ///
  /// Répond 403 tant que le dossier d'identité du propriétaire n'est pas
  /// déposé : l'appelant distingue ce cas pour inviter à le compléter plutôt
  /// que d'annoncer un échec sans issue.
  Future<PropertyModel> publish(String id) =>
      _visibility(ApiEndpoints.proprioPropertyPublish(id));

  /// Retire l'annonce de la vitrine, sans la supprimer.
  Future<PropertyModel> unpublish(String id) =>
      _visibility(ApiEndpoints.proprioPropertyUnpublish(id));

  Future<PropertyModel> _visibility(String endpoint) async {
    try {
      final response = await _dio.patch(endpoint);
      final data = (response.data as Map<String, dynamic>)['data'];
      return PropertyModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }

  /// Sépare les segments d'un chemin, indifféremment des conventions de l'OS.
  static final RegExp _separator = RegExp(r'[/\\]');
}

/// Une page de biens, avec son bloc `meta`.
///
/// Calquée sur `ResidencePage` : l'API sert le même `meta` aux deux listes.
class PropertyPage {
  const PropertyPage({
    required this.items,
    required this.total,
    required this.currentPage,
    required this.lastPage,
  });

  final List<PropertyModel> items;
  final int total;
  final int currentPage;
  final int lastPage;

  bool get hasMore => currentPage < lastPage;

  /// Les replis couvrent une réponse sans `meta` : la liste est alors tenue
  /// pour complète, ce qui vaut mieux qu'une boucle sur une page unique.
  factory PropertyPage.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? const [];
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};

    return PropertyPage(
      items: [
        for (final item in data)
          PropertyModel.fromJson(item as Map<String, dynamic>),
      ],
      total: (meta['total'] as num?)?.toInt() ?? data.length,
      currentPage: (meta['currentPage'] as num?)?.toInt() ?? 1,
      lastPage: (meta['lastPage'] as num?)?.toInt() ?? 1,
    );
  }
}

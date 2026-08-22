import 'package:dio/dio.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../models/property_model.dart';

/// Annonces du propriétaire connecté.
class PropertyRepository {
  const PropertyRepository(this._dio);

  final Dio _dio;

  /// Liste paginée des annonces.
  ///
  /// L'API répond `{ data: [...], meta: {...} }` : seule la page courante est
  /// retournée ici, la pagination n'étant pas encore exploitée par l'écran.
  Future<List<PropertyModel>> getPropertyList() async {
    try {
      final response = await _dio.get(ApiEndpoints.proprioProperties);
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
        ApiEndpoints.proprioProperties,
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

  /// Sépare les segments d'un chemin, indifféremment des conventions de l'OS.
  static final RegExp _separator = RegExp(r'[/\\]');
}

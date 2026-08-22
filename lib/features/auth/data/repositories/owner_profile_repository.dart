import 'package:dio/dio.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/failures.dart';
import '../models/owner_profile_model.dart';

/// Accès au dossier de validation du propriétaire.
///
/// Le dépôt passe par `multipart/form-data` : les pièces d'identité
/// accompagnent les champs texte dans une requête unique, ce qui évite un état
/// intermédiaire où les documents seraient enregistrés sans le formulaire —
/// ou l'inverse.
class OwnerProfileRepository {
  const OwnerProfileRepository(this._dio);

  final Dio _dio;

  /// Dossier tel qu'enregistré côté serveur.
  ///
  /// Sert à repeupler le formulaire lors d'une reprise : sans cela, corriger un
  /// seul champ obligerait à tout ressaisir et à redéposer les deux photos.
  Future<OwnerProfileModel> fetch() async {
    try {
      final res = await _dio.get(ApiEndpoints.proprioProfile);
      final data = res.data as Map<String, dynamic>;
      return OwnerProfileModel.fromJson(data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppFailure.fromDio(e);
    }
  }

  /// Dépose ou corrige le dossier.
  ///
  /// Les chemins de fichiers sont optionnels : lors d'une correction, les
  /// justificatifs déjà transmis restent valables et n'ont pas à transiter une
  /// seconde fois. Le serveur refuse la requête si, au total, le recto manque.
  Future<OwnerProfileModel> submit({
    required String fullName,
    required String phone,
    required IdDocumentType idDocumentType,
    required String idDocumentNumber,
    String? address,
    String? city,
    String? country,
    String? frontImagePath,
    String? backImagePath,
  }) async {
    try {
      final form = FormData.fromMap({
        'full_name': fullName,
        'phone': phone,
        'id_document_type': idDocumentType.code,
        'id_document_number': idDocumentNumber,
        if (address != null && address.isNotEmpty) 'address': address,
        if (city != null && city.isNotEmpty) 'city': city,
        if (country != null && country.isNotEmpty) 'country': country,
        if (frontImagePath != null)
          'id_document_front': await _imageFile(frontImagePath),
        if (backImagePath != null)
          'id_document_back': await _imageFile(backImagePath),
      });

      final res = await _dio.post(
        ApiEndpoints.proprioProfile,
        data: form,
        // Le Content-Type par défaut du client est `application/json` : le
        // laisser ici enverrait un corps multipart sous une étiquette JSON, que
        // le serveur refuserait d'analyser.
        //
        // Il faut le surcharger via `contentType`, et non via le header :
        // `Options.compose` recopie d'abord les en-têtes de `BaseOptions`,
        // qui portent déjà `application/json`. Une entrée locale à `null` ne
        // les efface pas — la clé reste présente — et `_RequestConfig` lève
        // alors sur le désaccord entre les deux valeurs. `contentType` est
        // appliqué après la fusion et l'emporte proprement.
        //
        // La frontière multipart est ajoutée ensuite par `FormData`.
        options: Options(contentType: Headers.multipartFormDataContentType),
      );

      final data = res.data as Map<String, dynamic>;
      return OwnerProfileModel.fromJson(data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppFailure.fromDio(e);
    }
  }

  /// Construit la partie fichier d'un justificatif.
  ///
  /// Le nom de fichier est transmis explicitement : la validation serveur
  /// s'appuie sur l'extension pour reconnaître une image, et une partie sans
  /// nom se verrait refusée quel que soit son contenu.
  Future<MultipartFile> _imageFile(String path) {
    return MultipartFile.fromFile(path, filename: path.split(_separator).last);
  }

  /// Sépare les segments d'un chemin, indifféremment des conventions de l'OS.
  static final RegExp _separator = RegExp(r'[/\\]');
}

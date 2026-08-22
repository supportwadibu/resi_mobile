import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../data/models/property_model.dart';
import '../data/repositories/property_repository.dart';
import 'create_property_state.dart';

/// Pilote le dépôt d'une annonce.
///
/// Séparé de `PropertyCubit` : lister et créer ont des cycles de vie
/// distincts, et un échec de création ne doit pas vider la liste affichée.
class CreatePropertyCubit extends Cubit<CreatePropertyState> {
  CreatePropertyCubit(this._repository) : super(const CreatePropertyIdle());

  final PropertyRepository _repository;

  /// Photos déjà hébergées, conservées d'une tentative à l'autre.
  List<String> _uploadedImages = const [];

  /// Dépose l'annonce, photos comprises.
  ///
  /// [imagePaths] désigne des fichiers de l'appareil. Ils sont envoyés d'abord,
  /// l'API attendant des URLs dans `media.images` — puis l'annonce elle-même.
  Future<void> submit({
    required String title,
    required String description,
    required PropertyType propertyType,
    required PropertyAddress address,
    required PropertyDetails details,
    required Set<Amenity> amenities,
    required List<String> imagePaths,
    required PropertyPricing pricing,
    required DateTime availableFrom,
    bool chargesIncluded = false,
    double? additionalCharges,
  }) async {
    try {
      // Un renvoi après échec ne redépose pas des photos déjà hébergées : le
      // réseau de l'utilisateur est une ressource rare.
      if (_uploadedImages.isEmpty && imagePaths.isNotEmpty) {
        emit(CreatePropertyUploadingImages(total: imagePaths.length));
        _uploadedImages = await _repository.uploadImages(imagePaths);
      }

      emit(const CreatePropertySubmitting());

      final property = await _repository.create(
        CreatePropertyPayload(
          title: title,
          description: description,
          propertyType: propertyType,
          address: address,
          details: details,
          amenities: amenities,
          images: _uploadedImages,
          pricing: pricing,
          availableFrom: availableFrom,
          chargesIncluded: chargesIncluded,
          additionalCharges: additionalCharges,
        ),
      );

      if (!isClosed) emit(CreatePropertySuccess(property));
    } on AppFailure catch (f) {
      if (!isClosed) {
        emit(
          CreatePropertyFailure(
            f.userMessage,
            uploadedImages: _uploadedImages.isEmpty ? null : _uploadedImages,
          ),
        );
      }
    }
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../data/models/property_model.dart';
import '../data/repositories/property_repository.dart';
import 'edit_property_state.dart';

/// Pilote la modification d'une annonce existante.
///
/// Séparé de `CreatePropertyCubit` : les deux parcours partagent le formulaire
/// mais pas leur logique. Créer envoie tout, modifier n'envoie que les écarts,
/// et seul le second doit composer avec des photos déjà hébergées.
class EditPropertyCubit extends Cubit<EditPropertyState> {
  EditPropertyCubit(this._repository) : super(const EditPropertyIdle());

  final PropertyRepository _repository;

  /// Photos nouvellement déposées, indexées par leur chemin local.
  ///
  /// Conservées d'une tentative à l'autre : après un échec d'enregistrement,
  /// les fichiers sont déjà hébergés et les renvoyer gaspillerait le forfait
  /// data du propriétaire.
  final Map<String, String> _uploaded = {};

  /// Enregistre les modifications.
  ///
  /// [images] mêle des URLs déjà hébergées et des chemins de fichiers de
  /// l'appareil — l'étape Photos ne distingue pas les deux à l'écran. Les
  /// seconds sont déposés ici, puis toute la liste est transmise en URLs,
  /// dans l'ordre retenu par le propriétaire.
  Future<void> submit({
    required PropertyModel original,
    required String title,
    required String description,
    required PropertyType propertyType,
    required PropertyAddress address,
    required PropertyDetails details,
    required Set<Amenity> amenities,
    required List<String> images,
    required PropertyPricing pricing,
  }) async {
    try {
      final resolved = await _resolveImages(images);
      if (isClosed) return;

      final payload = UpdatePropertyPayload.diff(
        original: original,
        title: title,
        description: description,
        propertyType: propertyType,
        address: address,
        details: details,
        amenities: amenities,
        images: resolved,
        pricing: pricing,
      );

      // Rien n'a bougé : l'appel serait sans effet, et l'API refuse un corps
      // vide sur certaines validations. On rend la fiche telle quelle.
      if (payload.isEmpty) {
        emit(EditPropertySuccess(original, unchanged: true));
        return;
      }

      emit(const EditPropertySubmitting());
      final updated = await _repository.update(original.id, payload);

      if (!isClosed) emit(EditPropertySuccess(updated));
    } on AppFailure catch (f) {
      _fail(f.userMessage);
    } catch (_) {
      // Filet de sécurité, et non redondance avec le `on AppFailure` : l'écran
      // neutralise toute interaction pendant l'envoi. Une exception imprévue
      // qui s'échapperait d'ici laisserait l'état sur « en cours » et
      // enfermerait le propriétaire dans un formulaire inerte, sans autre
      // issue que de tuer l'application.
      _fail('L’enregistrement a échoué. Veuillez réessayer.');
    }
  }

  /// Émet l'échec en conservant les photos déjà déposées.
  void _fail(String message) {
    if (isClosed) return;

    emit(
      EditPropertyFailure(
        message,
        uploadedImages: _uploaded.isEmpty
            ? null
            : _uploaded.values.toList(growable: false),
      ),
    );
  }

  /// Remplace les chemins locaux par leurs URLs, en préservant l'ordre.
  ///
  /// L'ordre porte du sens : la première photo sert de couverture à l'annonce.
  Future<List<String>> _resolveImages(List<String> images) async {
    final pending = [
      for (final entry in images)
        if (!_isHosted(entry) && !_uploaded.containsKey(entry)) entry,
    ];

    if (pending.isNotEmpty) {
      emit(EditPropertyUploadingImages(total: pending.length));
      final urls = await _repository.uploadImages(pending);

      // Le repository renvoie les URLs dans l'ordre des fichiers envoyés ;
      // une réponse plus courte signalerait un dépôt partiel, qu'on ne peut
      // pas rattacher à coup sûr.
      if (urls.length != pending.length) {
        throw AppFailure.unexpected(
          message:
              'Dépôt partiel des photos : ${urls.length}/${pending.length}',
        );
      }
      for (var i = 0; i < pending.length; i++) {
        _uploaded[pending[i]] = urls[i];
      }
    }

    return [
      for (final entry in images)
        if (_isHosted(entry)) entry else _uploaded[entry]!,
    ];
  }

  /// Une photo déjà en ligne se reconnaît à son schéma : l'étape Photos
  /// mélange URLs Cloudinary et chemins de fichiers de l'appareil.
  static bool _isHosted(String entry) =>
      entry.startsWith('http://') || entry.startsWith('https://');
}

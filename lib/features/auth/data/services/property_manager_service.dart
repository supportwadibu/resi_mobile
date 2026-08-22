import 'package:resi_africa/core/storage/local_storage.dart';

import '../../../../core/error/failures.dart';
import '../models/owner_profile_model.dart';
import '../models/property_manager_model.dart';
import '../repositories/owner_profile_repository.dart';

/// Dossier de validation du propriétaire : coordonnées et pièce d'identité.
///
/// L'API fait autorité — c'est elle qui décide si le dossier est complet, et
/// c'est son verdict qui conditionne la suspension du compte à l'issue de
/// l'essai gratuit. Le stockage local ne sert que de **brouillon** : il
/// conserve une saisie interrompue par un réseau absent, pour que
/// l'utilisateur n'ait pas à tout retaper. Il n'est jamais une preuve de dépôt.
class PropertyManagerService {
  const PropertyManagerService(this._localStorage, this._repository);

  final LocalStorage _localStorage;
  final OwnerProfileRepository _repository;

  /// Dossier enregistré côté serveur.
  Future<OwnerProfileModel> fetchProfile() {
    return _repository.fetch();
  }

  /// Dépose le dossier, puis purge le brouillon local devenu inutile.
  ///
  /// Les erreurs remontent : l'appelant doit savoir que rien n'a été transmis,
  /// et surtout ne pas afficher une confirmation pour une requête échouée.
  Future<OwnerProfileModel> submitProfile({
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
    final profile = await _repository.submit(
      fullName: fullName,
      phone: phone,
      idDocumentType: idDocumentType,
      idDocumentNumber: idDocumentNumber,
      address: address,
      city: city,
      country: country,
      frontImagePath: frontImagePath,
      backImagePath: backImagePath,
    );

    await _localStorage.clearPropertyManager();
    return profile;
  }

  /// Le dossier a-t-il été déposé ?
  ///
  /// Retourne `null` lorsque l'état est indéterminable — hors ligne, session
  /// expirée. L'appelant tranche alors selon ce que coûte son erreur : afficher
  /// un rappel de trop est bénin, détourner la navigation d'un utilisateur en
  /// règle ne l'est pas.
  Future<bool?> isProfileSubmitted() async {
    try {
      final profile = await _repository.fetch();
      return profile.isSubmitted;
    } on AppFailure {
      return null;
    }
  }

  /// Brouillon local d'une saisie non transmise.
  Future<PropertyManagerModel?> getDraft() {
    return _localStorage.getPropertyManager();
  }

  /// Conserve une saisie en cours, sans la transmettre.
  Future<void> saveDraft(PropertyManagerModel manager) {
    return _localStorage.savePropertyManager(manager);
  }

  Future<void> clearPropertyManager() {
    return _localStorage.clearPropertyManager();
  }
}

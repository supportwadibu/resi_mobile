import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../gerant/data/repositories/gerant_repository.dart';
import '../data/models/owner_profile_model.dart';
import '../data/services/property_manager_service.dart';
import 'owner_profile_state.dart';

/// Pilote l'écran de finalisation d'inscription et l'onglet Profil.
///
/// Séparé d'`AuthCubit` : le dossier de validation a son propre cycle de vie,
/// consultable et modifiable bien après l'ouverture de session.
///
/// L'onglet Profil est monté pour les deux rôles, mais `/proprio/profile` est
/// fermée au gérant : l'appeler rendait un 403 et laissait l'écran sur une
/// erreur, sans aucune donnée. Le rôle est donc lu avant tout appel, et chaque
/// branche a sa source, son modèle et son état. Un second cubit ferait le même
/// travail, mais `ProfileView` devrait alors choisir son fournisseur avant de
/// connaître le rôle, et les deux se désynchroniseraient à la première
/// évolution de l'écran.
///
/// `submit` reste propre au propriétaire : le dépôt d'un dossier de validation
/// n'a pas d'équivalent gérant, et `PropertyManagerProfileRoute`, d'où il part,
/// lui est déjà fermée par `OwnerRouteGuard`.
class OwnerProfileCubit extends Cubit<OwnerProfileState> {
  OwnerProfileCubit(this._service, this._gerantRepository, this._roleOf)
    : super(const OwnerProfileInitial());

  final PropertyManagerService _service;
  final GerantRepository _gerantRepository;

  /// Lecture du rôle courant, injectée pour rester testable hors widget —
  /// même forme que dans `DashboardCubit`, `HomeStatsCubit` et
  /// `OwnerRouteGuard`.
  final String Function() _roleOf;

  /// Charge le profil de l'utilisateur connecté, selon son rôle.
  Future<void> load() async {
    emit(const OwnerProfileLoading());

    if (_roleOf() == 'gerant') {
      await _loadManager();
      return;
    }

    await _loadOwner();
  }

  /// Dossier de validation du propriétaire.
  ///
  /// Un échec réseau n'est pas bloquant : le formulaire s'ouvre vide plutôt que
  /// de barrer l'accès à une étape que l'utilisateur doit pouvoir accomplir.
  Future<void> _loadOwner() async {
    try {
      final profile = await _service.fetchProfile();
      if (!isClosed) emit(OwnerProfileReady(profile));
    } on AppFailure {
      if (!isClosed) emit(const OwnerProfileReady(null));
    }
  }

  /// Compte du gérant, sur son propre préfixe.
  ///
  /// L'échec porte ici son message, là où celui du propriétaire se replie sur
  /// un formulaire vide : le gérant n'a rien à déposer, et un écran muet ne lui
  /// laisserait pas même de quoi réessayer.
  Future<void> _loadManager() async {
    try {
      final account = await _gerantRepository.getProfile();
      if (!isClosed) emit(ManagerProfileReady(account));
    } on AppFailure catch (f) {
      if (!isClosed) emit(OwnerProfileError(f.userMessage));
    }
  }

  /// Dépose le dossier.
  Future<void> submit({
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
    // Le dossier déjà chargé est mémorisé avant l'émission : en cas d'échec, il
    // sert à conserver les justificatifs déjà déposés à l'écran.
    final current = switch (state) {
      OwnerProfileReady(:final profile) => profile,
      OwnerProfileError(:final profile) => profile,
      OwnerProfileSubmitted(:final profile) => profile,
      _ => null,
    };

    emit(const OwnerProfileSubmitting());
    try {
      final profile = await _service.submitProfile(
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
      if (!isClosed) emit(OwnerProfileSubmitted(profile));
    } on AppFailure catch (f) {
      if (!isClosed) emit(OwnerProfileError(f.userMessage, profile: current));
    }
  }
}

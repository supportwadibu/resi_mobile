import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../data/models/owner_profile_model.dart';
import '../data/services/property_manager_service.dart';
import 'owner_profile_state.dart';

/// Pilote l'écran de finalisation d'inscription.
///
/// Séparé d'`AuthCubit` : le dossier de validation a son propre cycle de vie,
/// consultable et modifiable bien après l'ouverture de session.
class OwnerProfileCubit extends Cubit<OwnerProfileState> {
  OwnerProfileCubit(this._service) : super(const OwnerProfileInitial());

  final PropertyManagerService _service;

  /// Charge le dossier existant pour prégarnir le formulaire.
  ///
  /// Un échec réseau n'est pas bloquant : le formulaire s'ouvre vide plutôt que
  /// de barrer l'accès à une étape que l'utilisateur doit pouvoir accomplir.
  Future<void> load() async {
    emit(const OwnerProfileLoading());
    try {
      final profile = await _service.fetchProfile();
      if (!isClosed) emit(OwnerProfileReady(profile));
    } on AppFailure {
      if (!isClosed) emit(const OwnerProfileReady(null));
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

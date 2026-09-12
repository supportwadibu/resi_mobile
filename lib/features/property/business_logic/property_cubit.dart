import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../reservation/data/datasources/reservation_local_store.dart';
import '../data/models/property_model.dart';
import '../../residence/data/repositories/residence_repository.dart';
import '../data/repositories/property_repository.dart';
import 'property_state.dart';

class PropertyCubit extends Cubit<PropertyState> {
  PropertyCubit(this._repository, this._store, this._residences)
    : super(const PropertyInitial());

  final PropertyRepository _repository;
  final ReservationLocalStore _store;
  final ResidenceRepository _residences;

  Future<void> load() async {
    emit(const PropertyLoading());
    try {
      final items = await _repository.getPropertyList();

      // Les noms de résidences ne sont lus que si au moins un bien est
      // rattaché : un propriétaire qui n’en a pas ne doit pas payer une
      // requête pour rien.
      final names = items.any((p) => p.belongsToResidence)
          ? await _residenceNames()
          : const <String, String>{};

      // Le cache est refait à chaque lecture réussie : sans lui, le formulaire
      // de réservation hors réseau n'aurait aucun bien à proposer, et il
      // n'y aurait rien à réserver.
      await _store.replaceProperties(items, residenceNames: names);

      if (!isClosed) emit(PropertyLoaded(items));
    } on AppFailure catch (f) {
      // Hors réseau, on repart du cache : le propriétaire doit pouvoir choisir
      // son bien même sans connexion.
      final cached = await _store.getProperties();
      if (isClosed) return;

      emit(
        cached.isEmpty
            ? PropertyError(f.userMessage)
            : PropertyLoaded(cached.map(_toModel).toList(growable: false)),
      );
    }
  }

  /// Noms des résidences, indexés par identifiant.
  ///
  /// Un échec est absorbé : le cache des biens vaut mieux sans les noms que
  /// pas de cache du tout — la saisie hors ligne en dépend.
  Future<Map<String, String>> _residenceNames() async {
    try {
      final residences = await _residences.getAllResidences();
      return {for (final r in residences) r.id: r.name};
    } on AppFailure {
      return const {};
    }
  }

  /// Reconstruit le minimum dont le sélecteur a besoin.
  ///
  /// Le cache ne retient que l'identifiant, le titre, le tarif journalier et
  /// le rattachement : c'est tout ce que la saisie exige, et recopier la fiche
  /// complète obligerait à migrer la base à chaque évolution de l'API.
  static PropertyModel _toModel(CachedProperty cached) {
    return PropertyModel.fromJson({
      'id': cached.id,
      'title': cached.title,
      'pricing': {'daily_price': cached.dailyPrice},
      'residence_id': cached.residenceId,
      'unit_label': cached.unitLabel,
    });
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../reservation/data/datasources/reservation_local_store.dart';
import '../data/models/property_model.dart';
import '../data/repositories/property_repository.dart';
import 'property_state.dart';

class PropertyCubit extends Cubit<PropertyState> {
  PropertyCubit(this._repository, this._store) : super(const PropertyInitial());

  final PropertyRepository _repository;
  final ReservationLocalStore _store;

  Future<void> load() async {
    emit(const PropertyLoading());
    try {
      final items = await _repository.getPropertyList();

      // Le cache est refait à chaque lecture réussie : sans lui, le formulaire
      // de réservation hors réseau n'aurait aucune résidence à proposer, et il
      // n'y aurait rien à réserver.
      await _store.replaceProperties(items);

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

  /// Reconstruit le minimum dont le sélecteur a besoin.
  ///
  /// Le cache ne retient que l'identifiant, le titre et le tarif journalier :
  /// c'est tout ce que la saisie exige, et recopier la fiche complète
  /// obligerait à migrer la base à chaque évolution de l'API.
  static PropertyModel _toModel(CachedProperty cached) {
    return PropertyModel.fromJson({
      'id': cached.id,
      'title': cached.title,
      'pricing': {'daily_price': cached.dailyPrice},
    });
  }
}

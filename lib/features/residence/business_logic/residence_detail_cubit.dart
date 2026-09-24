import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../../property/data/models/property_model.dart';
import '../../property/data/repositories/property_repository.dart';
import '../data/repositories/residence_repository.dart';
import 'residence_detail_state.dart';

/// Fiche d'une résidence : ses informations et les logements qu'elle regroupe.
class ResidenceDetailCubit extends Cubit<ResidenceDetailState> {
  ResidenceDetailCubit(this._residences, this._properties)
    : super(const ResidenceDetailInitial());

  final ResidenceRepository _residences;
  final PropertyRepository _properties;

  Future<void> load(String id) async {
    emit(const ResidenceDetailLoading());

    try {
      // Lancés ensemble : les deux appels sont indépendants, et les enchaîner
      // doublerait l'attente sur les connexions lentes du terrain.
      final residenceFuture = _residences.getResidence(id);
      final unitsFuture = _loadUnits(id);

      final residence = await residenceFuture;
      final units = await unitsFuture;

      if (!isClosed) {
        emit(
          ResidenceDetailLoaded(
            residence: residence,
            units: units ?? const [],
            unitsFailed: units == null,
          ),
        );
      }
    } on AppFailure catch (f) {
      if (!isClosed) emit(ResidenceDetailError(f.userMessage));
    }
  }

  /// Logements de la résidence, `null` si leur chargement échoue.
  ///
  /// L'échec ne condamne pas la fiche : l'adresse et les équipements restent
  /// utiles sans la liste des unités.
  Future<List<PropertyModel>?> _loadUnits(String id) async {
    try {
      return await _properties.getPropertyList(residenceId: id);
    } on AppFailure {
      return null;
    }
  }
}

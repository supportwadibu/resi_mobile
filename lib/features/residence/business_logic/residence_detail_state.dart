import '../../property/data/models/property_model.dart';
import '../data/models/residence_model.dart';

sealed class ResidenceDetailState {
  const ResidenceDetailState();
}

final class ResidenceDetailInitial extends ResidenceDetailState {
  const ResidenceDetailInitial();
}

final class ResidenceDetailLoading extends ResidenceDetailState {
  const ResidenceDetailLoading();
}

final class ResidenceDetailLoaded extends ResidenceDetailState {
  const ResidenceDetailLoaded({
    required this.residence,
    this.units = const [],
    this.unitsFailed = false,
  });

  final ResidenceModel residence;

  /// Logements rattachés, la fiche restant lisible sans eux.
  final List<PropertyModel> units;

  /// Les logements n'ont pas pu être chargés, alors que la fiche l'a été.
  ///
  /// Distinct d'une résidence réellement vide : afficher « aucun logement »
  /// sur un échec réseau inviterait à en rattacher un qui existe déjà.
  final bool unitsFailed;
}

final class ResidenceDetailError extends ResidenceDetailState {
  const ResidenceDetailError(this.message);
  final String message;
}

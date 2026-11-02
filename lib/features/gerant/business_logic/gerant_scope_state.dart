import 'gerant_scope_cubit.dart';

/// Un logement proposé à la sélection.
class PropertyOption {
  const PropertyOption({required this.id, required this.label});

  final String id;
  final String label;
}

/// Une résidence dépliable et ses logements.
class ResidenceGroup {
  const ResidenceGroup({required this.residence, required this.properties});

  final ResidenceSelection residence;
  final List<PropertyOption> properties;
}

/// États de l'écran de périmètre.
sealed class GerantScopeState {
  const GerantScopeState();
}

final class GerantScopeInitial extends GerantScopeState {
  const GerantScopeInitial();
}

final class GerantScopeLoading extends GerantScopeState {
  const GerantScopeLoading();
}

final class GerantScopeLoaded extends GerantScopeState {
  const GerantScopeLoaded({
    required this.groups,
    required this.standalone,
    required this.selection,
    this.isSaving = false,
  });

  final List<ResidenceGroup> groups;

  /// Logements sans résidence : ils se cochent un à un, sans regroupement.
  final List<PropertyOption> standalone;

  final Set<String> selection;
  final bool isSaving;

  /// Nombre total de logements proposés, résidences comprises.
  int get totalCount =>
      standalone.length +
      groups.fold<int>(0, (sum, g) => sum + g.properties.length);

  GerantScopeLoaded copyWith({Set<String>? selection, bool? isSaving}) {
    return GerantScopeLoaded(
      groups: groups,
      standalone: standalone,
      selection: selection ?? this.selection,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

final class GerantScopeError extends GerantScopeState {
  const GerantScopeError(this.message);

  final String message;
}

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../../property/data/repositories/property_repository.dart';
import '../../residence/data/repositories/residence_repository.dart';
import '../data/repositories/gerant_admin_repository.dart';
import 'gerant_scope_state.dart';

export 'gerant_scope_state.dart';

// `scope_payload` vit avec le modèle : c'est de la sérialisation, et le
// repository doit pouvoir l'appeler sans que la couche `data` dépende de
// `business_logic`. Réexportée ici pour que les appelants du cubit — écrans et
// tests — la trouvent là où ils la cherchent.
export '../data/models/gerant_account_model.dart' show scopePayload;

/// Une résidence et les logements qu'elle regroupe, tels que l'écran les plie
/// et les déplie.
///
/// Groupement d'affichage seulement : `id` ne quitte jamais l'application, le
/// serveur n'affectant que des logements.
class ResidenceSelection {
  const ResidenceSelection({
    required this.id,
    required this.name,
    required this.propertyIds,
  });

  final String id;
  final String name;
  final List<String> propertyIds;
}

/// Coche ou décoche une résidence entière.
///
/// Tout ou rien : une résidence partiellement cochée se complète plutôt que de
/// se vider, ce qui est le geste attendu — on coche une résidence pour la
/// confier, pas pour en retirer les logements déjà confiés.
Set<String> toggleResidence(
  Set<String> selection,
  ResidenceSelection residence,
) {
  final all = residence.propertyIds.toSet();
  final complete = all.every(selection.contains);

  return complete
      ? (selection.toSet()..removeAll(all))
      : (selection.toSet()..addAll(all));
}

Set<String> toggleProperty(Set<String> selection, String propertyId) {
  final next = selection.toSet();
  return selection.contains(propertyId)
      ? (next..remove(propertyId))
      : (next..add(propertyId));
}

/// Valeur de la case à cocher d'une résidence : cochée, vide, ou **mixte**.
///
/// Rend `null` sur une résidence partiellement confiée, et non `false` :
/// Flutter ne dessine le tiret de l'état mixte que si `value == null`, même
/// avec `tristate: true`. Rendre un `bool` faisait afficher six logements sur
/// dix comme une case vide, indiscernable de zéro sur dix — soit précisément le
/// cas que le propriétaire rencontre.
///
/// Une résidence sans logement vaut `false` : il n'y a rien à confier, et un
/// tiret y suggérerait une sélection partielle inexistante.
bool? residenceCheckboxValue({
  required int checkedCount,
  required int totalCount,
}) {
  if (totalCount == 0 || checkedCount == 0) return false;
  return checkedCount == totalCount ? true : null;
}

/// Périmètre confié à un gérant : ce qu'il voit, et rien d'autre.
///
/// Le cubit charge le parc du propriétaire — logements groupés par résidence,
/// les isolés à part — puis enregistre la sélection en `PUT`, périmètre complet.
class GerantScopeCubit extends Cubit<GerantScopeState> {
  GerantScopeCubit(this._gerants, this._residences, this._properties)
    : super(const GerantScopeInitial());

  final GerantAdminRepository _gerants;
  final ResidenceRepository _residences;
  final PropertyRepository _properties;

  /// Charge le parc et, si [gerantId] est fourni, le périmètre déjà confié.
  ///
  /// [initialSelection] sert à la création, où aucun gérant n'existe encore
  /// pour porter la sélection : l'écran la conserve entre deux visites.
  Future<void> load({String? gerantId, Set<String>? initialSelection}) async {
    emit(const GerantScopeLoading());

    try {
      // Lancés ensemble : les trois appels sont indépendants, et les enchaîner
      // triplerait l'attente sur les connexions lentes du terrain.
      final residencesFuture = _residences.getAllResidences();
      final propertiesFuture = _properties.getAllProperties();
      final gerantFuture = gerantId == null
          ? Future.value(null)
          : _gerants.get(gerantId);

      final residences = await residencesFuture;
      final properties = await propertiesFuture;
      final gerant = await gerantFuture;

      final byResidence = <String, List<PropertyOption>>{};
      final standalone = <PropertyOption>[];

      for (final property in properties) {
        final option = PropertyOption(
          id: property.id,
          // `unit_label` distingue les unités d'une même résidence — « Studio
          // 3 » —, quand leurs titres d'annonce se ressemblent tous.
          label: property.unitLabel?.trim().isNotEmpty == true
              ? property.unitLabel!.trim()
              : property.title,
        );

        final residenceId = property.residenceId;
        if (residenceId == null || residenceId.isEmpty) {
          standalone.add(option);
        } else {
          byResidence.putIfAbsent(residenceId, () => []).add(option);
        }
      }

      final groups = <ResidenceGroup>[
        for (final residence in residences)
          // Une résidence sans logement est écartée : elle n'offrirait rien à
          // cocher et allongerait la liste pour rien.
          if ((byResidence[residence.id] ?? const []).isNotEmpty)
            ResidenceGroup(
              residence: ResidenceSelection(
                id: residence.id,
                name: residence.name,
                propertyIds: [
                  for (final p in byResidence[residence.id]!) p.id,
                ],
              ),
              properties: byResidence[residence.id]!,
            ),
      ];

      if (isClosed) return;

      emit(
        GerantScopeLoaded(
          groups: groups,
          standalone: standalone,
          selection: gerant != null
              ? gerant.propertyIds.toSet()
              : (initialSelection ?? const <String>{}),
        ),
      );
    } on AppFailure catch (f) {
      if (!isClosed) emit(GerantScopeError(f.userMessage));
    }
  }

  void toggleResidenceSelection(ResidenceSelection residence) {
    final current = state;
    if (current is! GerantScopeLoaded) return;

    emit(
      current.copyWith(
        selection: toggleResidence(current.selection, residence),
      ),
    );
  }

  void togglePropertySelection(String propertyId) {
    final current = state;
    if (current is! GerantScopeLoaded) return;

    emit(
      current.copyWith(
        selection: toggleProperty(current.selection, propertyId),
      ),
    );
  }

  /// Enregistre le périmètre. Rend `null` en cas de succès, le message sinon.
  ///
  /// L'échec ne bascule pas l'écran en erreur : la sélection en cours doit
  /// rester à l'écran pour être corrigée plutôt que refaite.
  Future<String?> save(String gerantId) async {
    final current = state;
    if (current is! GerantScopeLoaded) return null;

    emit(current.copyWith(isSaving: true));

    try {
      // La sélection part telle quelle : c'est `scopePayload`, dans le
      // repository, qui l'ordonne et la nomme.
      await _gerants.replaceProperties(gerantId, current.selection);
      if (!isClosed) emit(current.copyWith(isSaving: false));
      return null;
    } on AppFailure catch (f) {
      if (!isClosed) emit(current.copyWith(isSaving: false));
      return f.userMessage;
    }
  }
}

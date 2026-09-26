import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/plan_signals.dart';
import '../../../core/error/failures.dart';
import '../../../core/session/session_role.dart';
import '../../../core/storage/local_storage.dart';
import '../../auth/data/services/auth_service.dart';
import '../data/models/plan_access.dart';
import 'plan_state.dart';

/// Palier d'abonnement de la session, partagé par toute l'application.
///
/// Singleton et non cubit d'écran : les verrous sont posés partout — accueil,
/// fiche de séjour, menu de création — et doivent tous lire le même état.
///
/// Trois sources, de la plus fraîche à la plus ancienne : les refus de l'API
/// ([PlanSignals]), `GET /proprio/subscription`, et la dernière valeur mise en
/// cache, lue au démarrage pour que le mode hors ligne sache quoi verrouiller.
class PlanCubit extends Cubit<PlanState> {
  PlanCubit(this._auth, this._storage, this._role, PlanSignals signals)
    : super(const PlanUnknown()) {
    _signals = signals.stream.listen(_onSignal);
    final cached = PlanAccess.fromCache(_storage.getPlanAccess());
    if (cached != null) emit(PlanKnown(cached));
  }

  final AuthService _auth;
  final LocalStorage _storage;
  final SessionRole _role;
  late final StreamSubscription<PlanAccess> _signals;

  PlanAccess get access => state.access;

  /// Relit l'accès auprès de l'API.
  ///
  /// Sans effet pour un gérant : `GET /proprio/subscription` lui est fermé.
  /// Son accès — celui du propriétaire pour qui il agit — ne se découvre que
  /// par les refus de l'API.
  Future<void> refresh() async {
    if (_role.value == 'gerant') return;
    // Hors session, l'appel échouerait en 401 et l'intercepteur
    // d'authentification y lirait une session perdue.
    if (!await _auth.isLoggedIn()) return;

    try {
      final status = await _auth.subscriptionStatus();
      if (isClosed) return;

      await _apply(
        PlanKnown(
          PlanAccess.fromApi(status.planAccess),
          daysRemaining: status.daysRemaining,
          isTrial: status.isTrial,
          endDate: status.endDate,
        ),
      );
    } on AppFailure {
      // Hors réseau, l'état connu reste valable : l'API tranchera au retour.
    }
  }

  Future<void> clear() async {
    await _storage.clearPlanAccess();
    if (!isClosed) emit(const PlanUnknown());
  }

  /// Un refus de l'API fait foi sur tout ce que l'application croyait savoir.
  Future<void> _onSignal(PlanAccess access) async {
    if (isClosed || state.access == access) return;
    await _apply(PlanKnown(access));
  }

  Future<void> _apply(PlanKnown next) async {
    await _storage.savePlanAccess(next.access.code);
    if (!isClosed) emit(next);
  }

  @override
  Future<void> close() {
    _signals.cancel();
    return super.close();
  }
}

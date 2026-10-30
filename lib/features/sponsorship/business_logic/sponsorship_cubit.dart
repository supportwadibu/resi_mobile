import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../data/models/sponsorship_model.dart';
import '../data/repositories/sponsorship_repository.dart';
import 'sponsorship_state.dart';

/// Code, gains, filleuls et dernières demandes.
class SponsorshipCubit extends Cubit<SponsorshipState> {
  SponsorshipCubit(this._repository) : super(const SponsorshipInitial());

  final SponsorshipRepository _repository;

  Future<void> load() async {
    // Au rechargement, l'écran garde ses chiffres, comme le portefeuille.
    if (state is! SponsorshipLoaded) emit(const SponsorshipLoading());

    try {
      // La vue d'ensemble d'abord : elle crée le code à la première visite
      // et libère les gains échus, que les deux listes doivent refléter.
      final overview = await _repository.getOverview();
      final results = await Future.wait<Object>([
        _repository.getSponsored(),
        _repository.getRedemptions(),
      ]);
      if (!isClosed) {
        emit(
          SponsorshipLoaded(
            overview: overview,
            sponsored: results[0] as List<SponsoredUser>,
            redemptions: results[1] as List<RedemptionModel>,
          ),
        );
      }
    } on AppFailure catch (f) {
      if (!isClosed) emit(SponsorshipError(f.userMessage));
    }
  }
}

/// Retrait Wave ou conversion des gains, depuis sa feuille.
class RedemptionRequestCubit extends Cubit<SponsorshipActionState> {
  RedemptionRequestCubit(this._repository)
    : super(const SponsorshipActionIdle());

  final SponsorshipRepository _repository;

  Future<void> submit({
    required RedemptionType type,
    required int amount,
    String? payoutPhone,
    String? payoutName,
  }) async {
    emit(const SponsorshipActionSubmitting());
    try {
      await _repository.requestRedemption(
        type: type,
        amount: amount,
        payoutPhone: payoutPhone,
        payoutName: payoutName,
      );
      if (!isClosed) emit(const SponsorshipActionDone());
    } on AppFailure catch (f) {
      if (!isClosed) emit(SponsorshipActionFailure(f.userMessage));
    }
  }
}

/// Saisie après coup du code d'un parrain, depuis sa feuille.
class ApplySponsorshipCodeCubit extends Cubit<SponsorshipActionState> {
  ApplySponsorshipCodeCubit(this._repository)
    : super(const SponsorshipActionIdle());

  final SponsorshipRepository _repository;

  Future<void> submit(String code) async {
    emit(const SponsorshipActionSubmitting());
    try {
      await _repository.applyCode(code);
      if (!isClosed) emit(const SponsorshipActionDone());
    } on AppFailure catch (f) {
      if (!isClosed) emit(SponsorshipActionFailure(f.userMessage));
    }
  }
}

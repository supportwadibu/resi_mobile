import '../data/models/sponsorship_model.dart';

/// États de l'écran Parrainage.
sealed class SponsorshipState {
  const SponsorshipState();
}

final class SponsorshipInitial extends SponsorshipState {
  const SponsorshipInitial();
}

final class SponsorshipLoading extends SponsorshipState {
  const SponsorshipLoading();
}

final class SponsorshipLoaded extends SponsorshipState {
  const SponsorshipLoaded({
    required this.overview,
    required this.sponsored,
    required this.redemptions,
  });

  final SponsorshipOverview overview;
  final List<SponsoredUser> sponsored;
  final List<RedemptionModel> redemptions;
}

final class SponsorshipError extends SponsorshipState {
  const SponsorshipError(this.message);

  final String message;
}

/// États d'un envoi depuis une feuille — demande sur les gains, saisie d'un
/// code. L'échec s'affiche dans la feuille, qui reste ouverte pour corriger.
sealed class SponsorshipActionState {
  const SponsorshipActionState();
}

final class SponsorshipActionIdle extends SponsorshipActionState {
  const SponsorshipActionIdle();
}

final class SponsorshipActionSubmitting extends SponsorshipActionState {
  const SponsorshipActionSubmitting();
}

final class SponsorshipActionDone extends SponsorshipActionState {
  const SponsorshipActionDone();
}

final class SponsorshipActionFailure extends SponsorshipActionState {
  const SponsorshipActionFailure(this.message);

  final String message;
}

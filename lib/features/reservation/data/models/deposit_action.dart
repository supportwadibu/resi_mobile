/// Sort de l'acompte d'une réservation annulée, miroir de `DEPOSIT_ACTIONS`
/// côté API.
///
/// Le serveur l'exige dès qu'un acompte a été versé
/// (`deposit_action_required`) : un acompte gardé reste un revenu, un acompte
/// rendu n'en est plus un.
enum DepositAction {
  keep('keep'),
  refund('refund');

  const DepositAction(this.code);

  final String code;
}

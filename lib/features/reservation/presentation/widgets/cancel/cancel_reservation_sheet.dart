import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_callout.dart';
import 'package:resi_africa/shared/widgets/app_option_tile.dart';
import 'package:resi_africa/shared/widgets/app_sheet.dart';

import '../../../../../core/di/service_locator.dart';
import '../../../../home/presentation/widgets/reservations/reservation_item.dart';
import '../../../business_logic/stay_cancel_cubit.dart';
import '../../../business_logic/stay_cancel_state.dart';
import '../../../data/models/deposit_action.dart';
import '../../../data/models/reservation_model.dart';

/// Feuille d'annulation : motif facultatif et, si un acompte a été versé, son
/// sort — gardé ou rendu.
///
/// Rend la réservation annulée, ou `null` si le propriétaire renonce.
class CancelReservationSheet extends StatelessWidget {
  const CancelReservationSheet({required this.reservation, super.key});

  final ReservationModel reservation;

  static Future<ReservationModel?> show(
    BuildContext context,
    ReservationModel reservation,
  ) {
    return showAppSheet<ReservationModel>(
      context: context,
      builder: (_) => CancelReservationSheet(reservation: reservation),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StayCancelCubit>(),
      child: _CancelForm(reservation: reservation),
    );
  }
}

class _CancelForm extends StatefulWidget {
  const _CancelForm({required this.reservation});

  final ReservationModel reservation;

  @override
  State<_CancelForm> createState() => _CancelFormState();
}

class _CancelFormState extends State<_CancelForm> {
  final _reason = TextEditingController();

  /// Aucun choix par défaut : garder ou rendre l'acompte engage le
  /// propriétaire, il doit le décider lui-même.
  DepositAction? _depositAction;

  bool get _hasDeposit => widget.reservation.depositAmount > 0;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StayCancelCubit, StayCancelState>(
      listener: (context, state) {
        if (state case StayCancelSuccess(:final reservation)) {
          Navigator.of(context).pop(reservation);
        }
      },
      builder: (context, state) {
        final isSubmitting = state is StayCancelSubmitting;
        final canSubmit =
            !isSubmitting && (!_hasDeposit || _depositAction != null);
        final deposit = formatAmount(widget.reservation.depositAmount);

        return AppSheet(
          title: 'stay_cancel.title'.tr(),
          description: 'stay_cancel.body'.tr(),
          footer: AppButton(
            label: 'stay_cancel.confirm'.tr(),
            variant: AppButtonVariant.danger,
            icon: LucideIcons.ban,
            expand: true,
            isLoading: isSubmitting,
            onPressed: canSubmit
                ? () => context.read<StayCancelCubit>().submit(
                    widget.reservation.id,
                    reason: _reason.text,
                    depositAction: _hasDeposit ? _depositAction : null,
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_hasDeposit) ...[
                Text(
                  'stay_cancel.deposit_question'.tr(
                    namedArgs: {'amount': deposit},
                  ),
                  style: context.text.titleSmall,
                ),
                const SizedBox(height: 8),
                AppOptionTile(
                  title: 'stay_cancel.deposit_keep'.tr(),
                  description: 'stay_cancel.deposit_keep_hint'.tr(),
                  icon: LucideIcons.wallet,
                  selected: _depositAction == DepositAction.keep,
                  onTap: isSubmitting
                      ? null
                      : () =>
                            setState(() => _depositAction = DepositAction.keep),
                ),
                const SizedBox(height: 8),
                AppOptionTile(
                  title: 'stay_cancel.deposit_refund'.tr(),
                  description: 'stay_cancel.deposit_refund_hint'.tr(
                    namedArgs: {'amount': deposit},
                  ),
                  icon: LucideIcons.undo2,
                  selected: _depositAction == DepositAction.refund,
                  onTap: isSubmitting
                      ? null
                      : () => setState(
                          () => _depositAction = DepositAction.refund,
                        ),
                ),
                const SizedBox(height: 20),
              ],
              Text('stay_cancel.reason'.tr(), style: context.text.titleSmall),
              const SizedBox(height: 8),
              TextField(
                controller: _reason,
                enabled: !isSubmitting,
                maxLength: 500,
                maxLines: 3,
                minLines: 2,
                style: context.text.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'stay_cancel.reason_hint'.tr(),
                ),
              ),
              if (state case StayCancelFailure(:final message)) ...[
                const SizedBox(height: 12),
                AppCallout(
                  icon: LucideIcons.circleAlert,
                  tone: AppAccent.red,
                  message: message,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

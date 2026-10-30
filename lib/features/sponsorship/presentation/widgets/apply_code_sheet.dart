import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_callout.dart';
import 'package:resi_africa/shared/widgets/app_sheet.dart';
import 'package:resi_africa/shared/widgets/app_text_field.dart';

import '../../../../core/di/service_locator.dart';
import '../../business_logic/sponsorship_cubit.dart';
import '../../business_logic/sponsorship_state.dart';

/// Feuille de saisie du code d'un parrain, pour qui ne l'a pas donné à
/// l'inscription. Rend `true` une fois le parrain rattaché.
class ApplyCodeSheet extends StatelessWidget {
  const ApplyCodeSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showAppSheet<bool>(
      context: context,
      builder: (_) => const ApplyCodeSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ApplySponsorshipCodeCubit>(),
      child: const _ApplyCodeForm(),
    );
  }
}

class _ApplyCodeForm extends StatefulWidget {
  const _ApplyCodeForm();

  @override
  State<_ApplyCodeForm> createState() => _ApplyCodeFormState();
}

class _ApplyCodeFormState extends State<_ApplyCodeForm> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ApplySponsorshipCodeCubit, SponsorshipActionState>(
      listener: (context, state) {
        if (state is SponsorshipActionDone) Navigator.of(context).pop(true);
      },
      builder: (context, state) {
        final isSubmitting = state is SponsorshipActionSubmitting;
        final code = _code.text.trim();

        return AppSheet(
          title: 'sponsorship.apply_title'.tr(),
          description: 'sponsorship.apply_body'.tr(),
          footer: AppButton(
            label: 'sponsorship.apply_confirm'.tr(),
            icon: LucideIcons.check,
            expand: true,
            isLoading: isSubmitting,
            onPressed: !isSubmitting && code.length >= 4
                ? () => context.read<ApplySponsorshipCodeCubit>().submit(code)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'sponsorship.code_label'.tr(),
                controller: _code,
                enabled: !isSubmitting,
                onChanged: (_) => setState(() {}),
              ),
              if (state case SponsorshipActionFailure(:final message)) ...[
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

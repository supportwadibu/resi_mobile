import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_callout.dart';
import 'package:resi_africa/shared/widgets/app_text_field.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';

import '../../../../core/di/service_locator.dart';
import '../../business_logic/password_reset_cubit.dart';
import '../widgets/auth_layout.dart';
import '../widgets/password_field.dart';

/// Mot de passe oublié : le numéro, puis le code reçu sur WhatsApp et le
/// nouveau mot de passe. La session s'ouvre à la fin, comme après une
/// connexion.
///
/// [identifier] reprend ce que la connexion avait déjà saisi.
@RoutePage()
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({this.identifier, super.key});

  final String? identifier;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PasswordResetCubit>(),
      child: BlocConsumer<PasswordResetCubit, PasswordResetState>(
        listenWhen: (_, state) => state is PasswordResetDone,
        listener: (context, _) {
          AppToast.success('auth.password_reset_done'.tr(), context: context);
          context.router.replaceAll([const HomeRoute()]);
        },
        builder: (context, state) => AuthLayout(
          title: 'auth.forgot_title'.tr(),
          description: 'auth.forgot_description'.tr(),
          onBack: () => context.router.maybePop(),
          child: switch (state) {
            PasswordResetAskCode() => _CodeStep(state: state),
            PasswordResetAskIdentifier() => _IdentifierStep(
              state: state,
              initial: identifier,
            ),
            // La navigation part du listener ; l'étape du code reste
            // affichée le temps de la transition.
            PasswordResetDone() => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }
}

class _IdentifierStep extends StatefulWidget {
  const _IdentifierStep({required this.state, this.initial});

  final PasswordResetAskIdentifier state;
  final String? initial;

  @override
  State<_IdentifierStep> createState() => _IdentifierStepState();
}

class _IdentifierStepState extends State<_IdentifierStep> {
  final _formKey = GlobalKey<FormState>();
  late final _identifier = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _identifier.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<PasswordResetCubit>().requestCode(_identifier.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'auth.phone'.tr(),
            hint: '07 00 00 00 00',
            controller: _identifier,
            keyboardType: TextInputType.phone,
            enabled: !widget.state.sending,
            prefixIcon: const Icon(LucideIcons.phone, size: 16),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'common.field_required'.tr()
                : null,
          ),
          if (widget.state.error case final error?) ...[
            const SizedBox(height: 16),
            AppCallout(
              icon: LucideIcons.circleAlert,
              message: error,
              tone: AppAccent.red,
            ),
          ],
          const SizedBox(height: 24),
          AppButton(
            label: 'auth.send_code'.tr(),
            icon: LucideIcons.messageCircle,
            isLoading: widget.state.sending,
            expand: true,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _CodeStep extends StatefulWidget {
  const _CodeStep({required this.state});

  final PasswordResetAskCode state;

  @override
  State<_CodeStep> createState() => _CodeStepState();
}

class _CodeStepState extends State<_CodeStep> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Hors production, l'API rend le code : il se préremplit pour tester sans
    // téléphone.
    _code.text = widget.state.request.devOtpCode ?? '';
  }

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<PasswordResetCubit>().reset(
      code: _code.text.trim(),
      password: _password.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final busy = state.submitting || state.resending;
    final sentKey = state.request.channel == 'email'
        ? 'auth.code_sent_email'
        : 'auth.code_sent_whatsapp';

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCallout(
            icon: state.request.channel == 'email'
                ? LucideIcons.mail
                : LucideIcons.messageCircle,
            message: sentKey.tr(args: [state.request.identifier]),
            tone: AppAccent.green,
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'auth.code'.tr(),
            hint: '000000',
            controller: _code,
            keyboardType: TextInputType.number,
            enabled: !busy,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            prefixIcon: const Icon(LucideIcons.keyRound, size: 16),
            validator: (v) => v == null || v.trim().length != 6
                ? 'auth.code_invalid'.tr()
                : null,
          ),
          const SizedBox(height: 16),
          PasswordField(
            label: 'auth.new_password'.tr(),
            controller: _password,
            enabled: !busy,
            validator: PasswordRules.newPassword,
          ),
          const SizedBox(height: 16),
          PasswordField(
            label: 'auth.confirm_password'.tr(),
            controller: _confirmation,
            enabled: !busy,
            validator: PasswordRules.confirmation(_password),
          ),
          if (state.error case final error?) ...[
            const SizedBox(height: 16),
            AppCallout(
              icon: LucideIcons.circleAlert,
              message: error,
              tone: AppAccent.red,
            ),
          ],
          const SizedBox(height: 24),
          AppButton(
            label: 'auth.reset_submit'.tr(),
            isLoading: state.submitting,
            expand: true,
            onPressed: busy ? null : _submit,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: busy
                    ? null
                    : () =>
                          context.read<PasswordResetCubit>().changeIdentifier(),
                child: Text('auth.change_number'.tr()),
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () => context.read<PasswordResetCubit>().resendCode(),
                child: Text(
                  state.resending
                      ? 'common.loading'.tr()
                      : 'auth.resend_code'.tr(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'auth.code_expiry'.tr(),
            textAlign: TextAlign.center,
            style: context.mutedText,
          ),
        ],
      ),
    );
  }
}

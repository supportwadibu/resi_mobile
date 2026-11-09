import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_callout.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';

import '../../../../core/di/service_locator.dart';
import '../../../auth/presentation/widgets/password_field.dart';
import '../../business_logic/change_password_cubit.dart';

/// Le gérant remplace le mot de passe que le propriétaire lui a donné.
///
/// L'ancien mot de passe est exigé : sans lui, un téléphone resté ouvert
/// suffirait à s'approprier le compte. Oublié, il se remplace par un code
/// WhatsApp — le lien mène au parcours « mot de passe oublié ».
@RoutePage()
class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({this.phone, super.key});

  /// Numéro du gérant, repris par « mot de passe oublié ».
  final String? phone;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ChangePasswordCubit>(),
      child: BlocConsumer<ChangePasswordCubit, ChangePasswordState>(
        listenWhen: (_, state) => state is ChangePasswordDone,
        listener: (context, _) {
          AppToast.success('auth.password_changed'.tr(), context: context);
          context.router.maybePop();
        },
        builder: (context, state) => Scaffold(
          appBar: AppTopBar(title: 'auth.change_password_title'.tr()),
          body: _ChangePasswordForm(state: state, phone: phone),
        ),
      ),
    );
  }
}

class _ChangePasswordForm extends StatefulWidget {
  const _ChangePasswordForm({required this.state, this.phone});

  final ChangePasswordState state;
  final String? phone;

  @override
  State<_ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<_ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<ChangePasswordCubit>().submit(
      currentPassword: _current.text,
      newPassword: _password.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final submitting = widget.state is ChangePasswordSubmitting;
    final error = switch (widget.state) {
      ChangePasswordIdle(:final error) => error,
      _ => null,
    };

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text('auth.change_password_lead'.tr(), style: context.mutedText),
          const SizedBox(height: 20),
          PasswordField(
            label: 'auth.current_password'.tr(),
            controller: _current,
            enabled: !submitting,
            validator: (v) =>
                v == null || v.isEmpty ? 'common.field_required'.tr() : null,
          ),
          const SizedBox(height: 16),
          PasswordField(
            label: 'auth.new_password'.tr(),
            controller: _password,
            enabled: !submitting,
            validator: (v) =>
                PasswordRules.newPassword(v) ??
                (v == _current.text ? 'auth.password_unchanged'.tr() : null),
          ),
          const SizedBox(height: 16),
          PasswordField(
            label: 'auth.confirm_password'.tr(),
            controller: _confirmation,
            enabled: !submitting,
            validator: PasswordRules.confirmation(_password),
          ),
          if (error != null) ...[
            const SizedBox(height: 16),
            AppCallout(
              icon: LucideIcons.circleAlert,
              message: error,
              tone: AppAccent.red,
            ),
          ],
          const SizedBox(height: 24),
          AppButton(
            label: 'auth.change_password_submit'.tr(),
            icon: LucideIcons.check,
            isLoading: submitting,
            expand: true,
            onPressed: submitting ? null : _submit,
          ),
          const SizedBox(height: 8),
          AppButton(
            label: 'auth.forgot_password'.tr(),
            variant: AppButtonVariant.ghost,
            expand: true,
            onPressed: submitting
                ? null
                : () => context.router.push(
                    ForgotPasswordRoute(identifier: widget.phone),
                  ),
          ),
        ],
      ),
    );
  }
}

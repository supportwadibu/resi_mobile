import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/config/app_config.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/features/auth/data/services/auth_service.dart';
import 'package:resi_africa/features/subscription/business_logic/plan_cubit.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_callout.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';
import 'package:resi_africa/shared/widgets/app_text_field.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';
import 'package:resi_africa/shared/widgets/confirm_dialog.dart';
import 'package:resi_africa/shared/widgets/error_state.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/service_locator.dart';
import '../../business_logic/account_deletion_cubit.dart';
import '../../business_logic/account_deletion_state.dart';
import '../../data/models/account_deletion_model.dart';

/// Suppression du compte par son titulaire, exigée par les stores.
///
/// Le serveur dit ce qui bloque (argent dû, séjours en cours) et ce qui sera
/// perdu ; l'écran ne fait que l'afficher, puis demande une confirmation
/// explicite — case cochée, puis dialogue — avant un acte que seul le
/// support peut défaire.
@RoutePage()
class AccountDeletionScreen extends StatelessWidget {
  const AccountDeletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AccountDeletionCubit>()..load(),
      child: const _AccountDeletionView(),
    );
  }
}

class _AccountDeletionView extends StatelessWidget {
  const _AccountDeletionView();

  /// Compte fermé côté serveur : même purge locale qu'une déconnexion.
  ///
  /// `logout` tente d'abord de révoquer la session, que le serveur a déjà
  /// révoquée : son échec est attendu, la purge locale a lieu quand même.
  Future<void> _signOut(BuildContext context) async {
    try {
      await sl<AuthService>().logout();
    } catch (_) {}
    await sl<PlanCubit>().clear();
    if (!context.mounted) return;

    AppToast.success('account_deletion.done'.tr());
    await context.router.replaceAll([const LoginRoute()]);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AccountDeletionCubit, AccountDeletionState>(
      listenWhen: (_, state) => state is AccountDeletionDone,
      listener: (context, _) => _signOut(context),
      builder: (context, state) => Scaffold(
        appBar: AppTopBar(
          title: 'account_deletion.title'.tr(),
          // Pas de retour pendant l'envoi : l'écran quitté, l'issue ne
          // serait plus visible.
          showBack: !(state is AccountDeletionReady && state.submitting),
        ),
        body: switch (state) {
          AccountDeletionInitial() ||
          AccountDeletionLoading() ||
          AccountDeletionDone() => const Center(child: AppLoader()),
          AccountDeletionError(:final message) => ErrorState(
            message: message,
            onRetry: () => context.read<AccountDeletionCubit>().load(),
          ),
          AccountDeletionReady() => _DeletionForm(state: state),
        },
      ),
    );
  }
}

class _DeletionForm extends StatefulWidget {
  const _DeletionForm({required this.state});

  final AccountDeletionReady state;

  @override
  State<_DeletionForm> createState() => _DeletionFormState();
}

class _DeletionFormState extends State<_DeletionForm> {
  final _reason = TextEditingController();
  bool _understood = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final days = widget.state.preview.gracePeriodDays.toString();
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'account_deletion.confirm_title'.tr(),
      message: 'account_deletion.confirm_message'.tr(args: [days]),
      confirmLabel: 'account_deletion.submit'.tr(),
      danger: true,
    );
    if (!confirmed || !mounted) return;
    await context.read<AccountDeletionCubit>().delete(reason: _reason.text);
  }

  /// Règles de confidentialité du site, dans la langue de l'app.
  Future<void> _openPolicy() async {
    final lang = context.locale.languageCode == 'en' ? 'en' : 'fr';
    final url = Uri.parse(
      '${AppConfig.supportWebsite}/$lang/confidentialite#suppression',
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final preview = widget.state.preview;
    final submitting = widget.state.submitting;
    final days = preview.gracePeriodDays.toString();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(
          'account_deletion.lead'.tr(args: [days]),
          style: context.text.titleMedium,
        ),
        const SizedBox(height: 8),
        Text('account_deletion.grace'.tr(), style: context.mutedText),
        if (preview.blockers.isNotEmpty) ...[
          const SizedBox(height: 24),
          _NoticeList(
            title: 'account_deletion.blockers_title'.tr(),
            notices: preview.blockers,
            tone: AppAccent.red,
            icon: LucideIcons.octagonAlert,
          ),
        ],
        const SizedBox(height: 24),
        _NoticeList(
          title: 'account_deletion.warnings_title'.tr(),
          notices: [
            ...preview.warnings,
            // L'API ne voit pas la file d'envoi de l'appareil, que la
            // déconnexion qui suit la suppression efface.
            AccountDeletionNotice(
              code: 'offline_queue',
              message: 'account_deletion.offline_warning'.tr(),
            ),
          ],
          tone: AppAccent.amber,
          icon: LucideIcons.triangleAlert,
        ),
        if (preview.canDelete) ...[
          const SizedBox(height: 24),
          AppTextField(
            label: 'account_deletion.reason_label'.tr(),
            hint: 'account_deletion.reason_hint'.tr(),
            controller: _reason,
            maxLines: 3,
            enabled: !submitting,
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: submitting
                ? null
                : () => setState(() => _understood = !_understood),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _understood,
                  onChanged: submitting
                      ? null
                      : (value) => setState(() => _understood = value ?? false),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'account_deletion.confirm_check'.tr(),
                      style: context.text.bodyMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
          label: 'account_deletion.submit'.tr(),
          icon: LucideIcons.trash2,
          variant: AppButtonVariant.danger,
          expand: true,
          isLoading: submitting,
          onPressed: preview.canDelete && _understood ? _submit : null,
        ),
        const SizedBox(height: 8),
        AppButton(
          label: 'account_deletion.policy_link'.tr(),
          icon: LucideIcons.shieldCheck,
          variant: AppButtonVariant.ghost,
          expand: true,
          onPressed: _openPolicy,
        ),
      ],
    );
  }
}

class _NoticeList extends StatelessWidget {
  const _NoticeList({
    required this.title,
    required this.notices,
    required this.tone,
    required this.icon,
  });

  final String title;
  final List<AccountDeletionNotice> notices;
  final AppAccent tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: context.text.titleMedium),
        const SizedBox(height: 12),
        for (final notice in notices) ...[
          AppCallout(icon: icon, message: notice.message, tone: tone),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

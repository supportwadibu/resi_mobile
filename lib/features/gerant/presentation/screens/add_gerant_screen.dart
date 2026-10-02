import 'package:easy_localization/easy_localization.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/core/utils/phone_helper.dart';
import 'package:resi_africa/shared/widgets/app_bottom_action_bar.dart';
import 'package:resi_africa/shared/widgets/app_phone_field.dart';
import 'package:resi_africa/shared/widgets/app_text_field.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:resi_africa/shared/widgets/error_state.dart';
import 'package:resi_africa/shared/widgets/skeletons/list_skeleton.dart';

import '../../../../core/di/service_locator.dart';
import '../../business_logic/gerant_list_cubit.dart';
import '../../business_logic/gerant_scope_cubit.dart';
import '../../data/models/gerant_account_model.dart';
import '../widgets/scope_selector.dart';

/// Ouverture d'un compte gérant : identité, coordonnée de connexion, mot de
/// passe initial, puis périmètre.
///
/// Tout part en une seule requête : le serveur crée le compte et pose son
/// périmètre ensemble. Les séparer laisserait, en cas de coupure entre les
/// deux, un compte sans affectation dont le propriétaire ignorerait
/// l'existence.
///
/// La saisie tient sur une page, comme celle d'une résidence : quatre champs et
/// une liste de cases à cocher ne justifient pas un assistant.
@RoutePage()
class AddGerantScreen extends StatelessWidget {
  const AddGerantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<GerantListCubit>()),
        // Le parc est chargé dès l'ouverture : la sélection est en bas du même
        // formulaire, et l'attendre au moment de faire défiler donnerait un
        // écran qui saute sous le doigt.
        BlocProvider(create: (_) => sl<GerantScopeCubit>()..load()),
      ],
      child: const _AddGerantView(),
    );
  }
}

class _AddGerantView extends StatefulWidget {
  const _AddGerantView();

  @override
  State<_AddGerantView> createState() => _AddGerantViewState();
}

class _AddGerantViewState extends State<_AddGerantView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSubmitting = false;

  /// La plateforme n'opère qu'en Côte d'Ivoire : le formulaire ne présente pas
  /// de champ pays, comme celui d'une résidence.
  static const _countryIso2 = 'CI';
  static const _phoneCode = '225';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: 'gerant.new_title'.tr()),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel('gerant.identity'.tr()),
                    AppTextField(
                      label: 'gerant.full_name'.tr(),
                      controller: _nameController,
                      hint: 'gerant.name_hint'.tr(),
                      validator: (value) =>
                          (value ?? '').trim().length < 2
                          ? 'gerant.name_required'.tr()
                          : null,
                    ),
                    const SizedBox(height: 16),

                    _SectionLabel('gerant.login_details'.tr()),
                    _Hint('gerant.login_details_hint'.tr()),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'gerant.email'.tr(),
                      controller: _emailController,
                      hint: 'gerant.email_hint'.tr(),
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),
                    AppPhoneField(
                      countryIso2: _countryIso2,
                      phoneCode: _phoneCode,
                      controller: _phoneController,
                    ),
                    const SizedBox(height: 16),

                    _SectionLabel('gerant.initial_password'.tr()),
                    // Dit à l'écran, sans quoi le propriétaire ne sait pas
                    // s'il doit le communiquer au gérant ni s'il le fixe pour
                    // de bon.
                    _Hint('gerant.initial_password_hint'.tr()),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'gerant.password'.tr(),
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      hint: 'gerant.password_hint'.tr(),
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'auth.show_password'.tr()
                            : 'auth.hide_password'.tr(),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? LucideIcons.eye
                              : LucideIcons.eyeOff,
                          size: 16,
                        ),
                      ),
                      validator: (value) => (value ?? '').length < 8
                          ? 'gerant.password_too_short'.tr()
                          : null,
                    ),
                    const SizedBox(height: 20),

                    _SectionLabel('gerant.assigned_units'.tr()),
                    _Hint('gerant.assigned_units_hint'.tr()),
                    const SizedBox(height: 12),
                    const _ScopeSection(),
                  ],
                ),
              ),
            ),
          ),
          AppBottomActionBar(
            primaryLabel: 'gerant.create'.tr(),
            primaryIcon: LucideIcons.check,
            isLoading: _isSubmitting,
            onPrimary: _isSubmitting ? null : _submit,
          ),
        ],
      ),
    );
  }

  /// L'e-mail n'est obligatoire que si aucun téléphone n'est saisi.
  ///
  /// Le champ n'est donc pas « requis » au sens habituel : c'est la paire qui
  /// l'est, et le message le dit plutôt que de réclamer un e-mail que le
  /// propriétaire n'a peut-être pas.
  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return null;
    // Contrôle volontairement large : le serveur tranche, et une expression
    // plus stricte ici refuserait des adresses valides qu'il accepte.
    if (!email.contains('@') || !email.contains('.')) {
      return 'gerant.email_invalid'.tr();
    }
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    final phoneInput = _phoneController.text.trim();

    if (email.isEmpty && phoneInput.isEmpty) {
      AppToast.error('gerant.contact_required'.tr());
      return;
    }

    // Recomposée en E.164 à la soumission : le champ ne porte que le numéro
    // national, l'indicatif étant affiché par le préfixe.
    final phone = phoneInput.isEmpty
        ? null
        : PhoneHelper.toE164(phoneInput, _countryIso2);

    if (phoneInput.isNotEmpty && phone == null) {
      AppToast.error('gerant.phone_invalid'.tr());
      return;
    }

    final scopeState = context.read<GerantScopeCubit>().state;
    final selection = scopeState is GerantScopeLoaded
        ? scopeState.selection
        : const <String>{};

    setState(() => _isSubmitting = true);

    final cubit = context.read<GerantListCubit>();
    final created = await cubit.create(
      CreateGerantPayload(
        fullName: _nameController.text,
        password: _passwordController.text,
        email: email.isEmpty ? null : email,
        phone: phone,
        // Transmise telle quelle : `scopePayload` l'ordonne et la nomme au
        // moment de sérialiser.
        propertyIds: selection,
      ),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (created == null) {
      AppToast.error(
        cubit.lastError ?? 'gerant.create_failed'.tr(),
      );
      return;
    }

    AppToast.success('gerant.created'.tr());
    await context.router.maybePop();
  }
}

/// Sélection du périmètre à l'intérieur du formulaire.
///
/// Un échec de chargement du parc n'empêche pas de créer le compte : le
/// périmètre se pose ensuite depuis la fiche du gérant, et bloquer la création
/// entière pour cela serait disproportionné.
class _ScopeSection extends StatelessWidget {
  const _ScopeSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GerantScopeCubit, GerantScopeState>(
      builder: (context, state) {
        final cubit = context.read<GerantScopeCubit>();

        return switch (state) {
          // Squelette de liste et non de formulaire : ce qui se charge ici est
          // la liste des logements, pas des champs de saisie.
          GerantScopeInitial() || GerantScopeLoading() => const SimpleListSkeleton(
            itemCount: 3,
            itemHeight: 64,
          ),
          GerantScopeError(:final message) => ErrorState(
            message: message,
            onRetry: cubit.load,
          ),
          GerantScopeLoaded(:final totalCount) when totalCount == 0 =>
            _Hint('gerant.no_unit_to_assign'.tr()),
          GerantScopeLoaded() => ScopeSelector(
            groups: state.groups,
            standalone: state.standalone,
            selection: state.selection,
            onToggleResidence: cubit.toggleResidenceSelection,
            onToggleProperty: cubit.togglePropertySelection,
          ),
        };
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: context.text.titleMedium,
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.text.bodySmall!.copyWith(height: 1.5),
    );
  }
}

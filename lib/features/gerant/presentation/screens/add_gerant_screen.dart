import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Nouveau gérant',
          style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
        ),
        centerTitle: true,
      ),
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
                    const _SectionLabel('Identité'),
                    AppTextField(
                      label: 'Nom complet',
                      controller: _nameController,
                      hint: 'Awa Koné',
                      validator: (value) =>
                          (value ?? '').trim().length < 2
                          ? 'Indiquez le nom du gérant.'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    const _SectionLabel('Coordonnées de connexion'),
                    const _Hint(
                      'E-mail ou téléphone : c’est par là que le gérant se '
                      'connecte. L’un des deux suffit.',
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'E-mail',
                      controller: _emailController,
                      hint: 'awa@exemple.ci',
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

                    const _SectionLabel('Mot de passe initial'),
                    // Dit à l'écran, sans quoi le propriétaire ne sait pas
                    // s'il doit le communiquer au gérant ni s'il le fixe pour
                    // de bon.
                    const _Hint(
                      'Communiquez-le au gérant : il en aura besoin pour sa '
                      'première connexion, et pourra le changer ensuite depuis '
                      'son profil.',
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Mot de passe',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      hint: '8 caractères minimum',
                      suffixIcon: GestureDetector(
                        onTap: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        child: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      validator: (value) => (value ?? '').length < 8
                          ? 'Le mot de passe doit faire 8 caractères au moins.'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    const _SectionLabel('Logements confiés'),
                    const _Hint(
                      'Le gérant ne verra que ces logements. Vous pourrez en '
                      'ajouter ou en retirer à tout moment.',
                    ),
                    const SizedBox(height: 12),
                    const _ScopeSection(),
                  ],
                ),
              ),
            ),
          ),
          AppBottomActionBar(
            primaryLabel: 'Créer le gérant',
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
      return 'Adresse e-mail invalide.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    final phoneInput = _phoneController.text.trim();

    if (email.isEmpty && phoneInput.isEmpty) {
      AppToast.error('Renseignez un e-mail ou un téléphone.');
      return;
    }

    // Recomposée en E.164 à la soumission : le champ ne porte que le numéro
    // national, l'indicatif étant affiché par le préfixe.
    final phone = phoneInput.isEmpty
        ? null
        : PhoneHelper.toE164(phoneInput, _countryIso2);

    if (phoneInput.isNotEmpty && phone == null) {
      AppToast.error('Numéro de téléphone invalide.');
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
        cubit.lastError ?? 'La création du gérant a échoué. Réessayez.',
      );
      return;
    }

    AppToast.success('Gérant créé');
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
            const _Hint(
              'Vous n’avez aucun logement à confier pour l’instant. Le compte '
              'peut être créé sans périmètre.',
            ),
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
        style: AppTextStyles.sectionTitle.copyWith(fontSize: 14),
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
      style: const TextStyle(
        fontSize: 12,
        color: AppColors.textSecondary,
        height: 1.5,
      ),
    );
  }
}

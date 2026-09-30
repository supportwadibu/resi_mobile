import 'package:auto_route/auto_route.dart';
import 'package:country_picker/country_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import 'package:resi_africa/core/utils/country_helper.dart';
import 'package:resi_africa/core/utils/phone_helper.dart';
import 'package:resi_africa/shared/widgets/app_bottom_action_bar.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_sheet.dart';
import 'package:resi_africa/shared/widgets/app_step_header.dart';
import 'package:resi_africa/shared/widgets/skeletons/form_skeleton.dart';

import '../../../../core/di/service_locator.dart';
import '../../business_logic/owner_profile_cubit.dart';
import '../../business_logic/owner_profile_state.dart';
import '../../../clients/data/models/client_model.dart';
import '../../../clients/data/services/id_scan_service.dart';
import '../../data/models/owner_profile_model.dart';
import '../widgets/owner_profile/steps/step_identity_document_widget.dart';
import '../widgets/owner_profile/steps/step_personal_info_widget.dart';

@RoutePage()
class PropertyManagerProfileScreen extends StatelessWidget {
  const PropertyManagerProfileScreen({super.key, this.isOnboarding = false});

  final bool isOnboarding;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OwnerProfileCubit>()..load(),
      child: _PropertyManagerProfileView(isOnboarding: isOnboarding),
    );
  }
}

class _PropertyManagerProfileView extends StatefulWidget {
  const _PropertyManagerProfileView({required this.isOnboarding});

  final bool isOnboarding;

  @override
  State<_PropertyManagerProfileView> createState() =>
      _PropertyManagerProfileViewState();
}

class _PropertyManagerProfileViewState
    extends State<_PropertyManagerProfileView> {
  /// Une clé par étape : la validation d'un `Form` ne porte que sur les champs
  /// montés, et seule l'étape courante l'est.
  final _personalFormKey = GlobalKey<FormState>();
  final _documentFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _communeController = TextEditingController();
  final _idNumberController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  static const _stepTitles = ['Informations personnelles', 'Pièce d’identité'];

  /// Marché principal de l'application : le pays est présélectionné pour
  /// éviter une manipulation à la très grande majorité des utilisateurs.
  static const _defaultCountryIso2 = 'CI';

  int _currentStep = 0;

  /// Pays de résidence. Détermine la liste des villes et l'indicatif
  /// téléphonique, d'où un état plutôt qu'un simple contrôleur de texte.
  Country _country = Country.parse(_defaultCountryIso2);

  /// Ville retenue, dupliquée hors du contrôleur : le champ commune se
  /// reconstruit sur ce changement, ce qu'un contrôleur seul ne provoque pas.
  String _city = '';

  IdDocumentType? _documentType;

  String? _frontImagePath;
  String? _backImagePath;
  String? _frontRemoteUrl;
  String? _backRemoteUrl;
  bool _prefilled = false;

  /// Dernier dossier connu, conservé entre les états.
  ///
  /// `OwnerProfileSubmitting` ne transporte pas le profil : sans cette
  /// mémoire, l'en-tête d'identité et la pastille de statut disparaîtraient
  /// le temps de l'envoi, puis reviendraient — un clignotement pour rien.
  OwnerProfileModel? _profile;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _communeController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  bool get _isLastStep => _currentStep == _stepTitles.length - 1;

  bool get _isFirstStep => _currentStep == 0;

  bool get _hasFront => _frontImagePath != null || _frontRemoteUrl != null;

  bool get _hasBack => _backImagePath != null || _backRemoteUrl != null;

  bool get _backRequired => _documentType?.requiresBack ?? false;

  /// Sépare la commune de l'adresse dans le champ `address` de l'API, faute
  /// d'un champ dédié côté serveur.
  static const _communeSeparator = ' · ';

  /// Adresse telle qu'envoyée : « Commune · rue, quartier ».
  String get _composedAddress {
    final address = _addressController.text.trim();
    final commune = _communeController.text.trim();

    if (commune.isEmpty) return address;
    if (address.isEmpty) return commune;
    return '$commune$_communeSeparator$address';
  }

  void _prefill(OwnerProfileModel? profile) {
    if (_prefilled || profile == null) return;
    _prefilled = true;

    _nameController.text = profile.fullName;
    _cityController.text = profile.city ?? '';

    // Opération inverse de `_composedAddress` : sans elle, la commune serait
    // reconcaténée à chaque dépôt et s'accumulerait dans l'adresse.
    final storedAddress = profile.address ?? '';
    final separatorAt = storedAddress.indexOf(_communeSeparator);
    if (separatorAt == -1) {
      _addressController.text = storedAddress;
    } else {
      _communeController.text = storedAddress.substring(0, separatorAt).trim();
      _addressController.text = storedAddress
          .substring(separatorAt + _communeSeparator.length)
          .trim();
    }
    _city = _cityController.text;
    _idNumberController.text = profile.idDocumentNumber ?? '';

    // Le pays est stocké en code ISO2, mais les dossiers antérieurs portent
    // son nom anglais : `CountryHelper` accepte les deux. Un libellé inconnu
    // laisse le pays par défaut en place plutôt que de vider le champ.
    final parsed = CountryHelper.resolve(profile.country);
    if (parsed != null) _country = parsed;

    // Le numéro revient en E.164 (`+225...`). Le champ n'affiche que la partie
    // nationale, l'indicatif étant porté par le préfixe.
    _phoneController.text = PhoneHelper.toNational(
      profile.phone,
      _country.countryCode,
    );
    _documentType = profile.idDocumentType;
    _frontRemoteUrl = profile.idDocumentFrontUrl;
    _backRemoteUrl = profile.idDocumentBackUrl;
  }

  /// Dépose une face de la pièce, puis la lit pour préremplir le numéro.
  ///
  /// Deux sources : ML Kit analyse une image sans piloter l'appareil photo,
  /// la prise de vue revient donc à `image_picker` — photo sur le moment ou
  /// image déjà sur le téléphone. Les deux sont lues de la même façon.
  Future<void> _pickImage({required bool isFront}) async {
    final source = await showAppSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => AppSheet(
        title: isFront ? 'Recto de la pièce' : 'Verso de la pièce',
        description: 'ocr.owner_hint'.tr(),
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          children: [
            AppSheetAction(
              icon: LucideIcons.scanText,
              label: 'ocr.source_camera'.tr(),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            AppSheetAction(
              icon: LucideIcons.images,
              label: 'ocr.source_gallery'.tr(),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final image = await _imagePicker.pickImage(
      source: source,
      // Assez fin pour la bande MRZ, assez léger pour l'envoi.
      maxWidth: 2000,
      imageQuality: 80,
    );
    if (image == null || !mounted) return;

    setState(() {
      if (isFront) {
        _frontImagePath = image.path;
      } else {
        _backImagePath = image.path;
      }
    });

    await _readDocument(image.path);
  }

  /// Préremplit numéro et nature de la pièce depuis la photo déposée.
  ///
  /// Ne comble que les champs vides : une seconde face, ou une photo
  /// redéposée, ne défait pas une correction faite à la main. Le numéro reste
  /// modifiable, et c'est au propriétaire de le vérifier — d'où le message.
  Future<void> _readDocument(String path) async {
    final reading = await const IdScanService().scan(path);
    if (reading == null || !mounted) return;

    var filled = false;
    setState(() {
      final number = reading.documentNumber;
      if (number != null && _idNumberController.text.trim().isEmpty) {
        _idNumberController.text = number;
        filled = true;
      }
      final type = _ownerDocumentType(reading.documentType);
      if (type != null && _documentType == null) {
        _documentType = type;
        filled = true;
      }
    });

    if (filled) AppToast.info('ocr.owner_found'.tr(), context: context);
  }

  /// Nature de pièce du carnet → celle du dossier propriétaire : deux
  /// énumérations distinctes côté mobile, pour les mêmes codes serveur.
  static IdDocumentType? _ownerDocumentType(ClientIdDocumentType? type) =>
      switch (type) {
        ClientIdDocumentType.cni => IdDocumentType.cni,
        ClientIdDocumentType.passeport => IdDocumentType.passport,
        ClientIdDocumentType.permis => IdDocumentType.drivingLicence,
        null => null,
      };

  void _next() {
    if (_isFirstStep) {
      if (!_personalFormKey.currentState!.validate()) return;
      setState(() => _currentStep++);
      return;
    }
    _submit();
  }

  void _back() {
    if (_isFirstStep) {
      if (!widget.isOnboarding) context.router.maybePop();
      return;
    }
    setState(() => _currentStep--);
  }

  void _submit() {
    if (!_documentFormKey.currentState!.validate()) return;

    if (_documentType == null) {
      _showMessage('Sélectionnez le type de pièce d’identité.');
      return;
    }
    if (!_hasFront) {
      _showMessage('Ajoutez le recto de votre pièce d’identité.');
      return;
    }
    if (_backRequired && !_hasBack) {
      _showMessage('Ajoutez le verso de votre pièce d’identité.');
      return;
    }

    context.read<OwnerProfileCubit>().submit(
      fullName: _nameController.text.trim(),
      // L'API reçoit la forme E.164, non ambiguë quel que soit le pays. Le
      // repli sur la saisie brute ne devrait pas servir : le champ a déjà été
      // validé par libphonenumber au passage à l'étape 2.
      phone:
          PhoneHelper.toE164(_phoneController.text, _country.countryCode) ??
          _phoneController.text.trim(),
      idDocumentType: _documentType!,
      idDocumentNumber: _idNumberController.text.trim(),
      // L'API ne porte pas de champ `commune` : elle est jointe à l'adresse
      // plutôt que perdue. À déplacer vers un champ dédié si le contrat
      // serveur en gagne un.
      address: _composedAddress,
      city: _cityController.text.trim(),
      // Code ISO2 plutôt que le nom : `country_picker` ne sait relire que le
      // code ou son libellé exact (« Côte d'Ivoire »), jamais la forme
      // anglaise `name` (« Ivory Coast ») — un aller-retour par le nom
      // reviendrait vide et ferait perdre le pays à la relecture.
      country: _country.countryCode,
      frontImagePath: _frontImagePath,
      backImagePath: _backImagePath,
    );
  }

  void _showMessage(String message) {
    AppToast.error(message, context: context);
  }

  void _continue() {
    if (widget.isOnboarding) {
      context.router.replaceAll([const TrialWelcomeRoute()]);
    } else {
      context.router.maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OwnerProfileCubit, OwnerProfileState>(
      listener: (context, state) {
        switch (state) {
          case OwnerProfileReady(:final profile):
            setState(() {
              if (profile != null) _profile = profile;
              _prefill(profile);
            });
          case OwnerProfileSubmitted(:final profile):
            setState(() => _profile = profile);
            AppToast.success(
              'Dossier transmis. Vous serez informé de sa validation.',
              context: context,
            );
            _continue();
          case OwnerProfileError(:final profile, :final message):
            // Un échec de dépôt renvoie le dossier antérieur : il reste la
            // meilleure information disponible sur l'état réel du compte.
            if (profile != null) setState(() => _profile = profile);
            _showMessage(message);
          default:
            break;
        }
      },
      builder: (context, state) {
        if (state is OwnerProfileLoading) {
          // Le squelette reprend la forme de l'étape 1 — en-tête, champs,
          // barre d'action — pour que l'arrivée des données ne redessine pas
          // l'écran.
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  AppStepHeader(
                    title: _stepTitles.first,
                    onBack: widget.isOnboarding ? null : _back,
                    currentStep: 0,
                    totalSteps: _stepTitles.length,
                  ),
                  Expanded(
                    child: OwnerProfileFormSkeleton(
                      showIntro: widget.isOnboarding,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final isSubmitting = state is OwnerProfileSubmitting;
        // `_profile` est tenu à jour par le `listener` : le `builder` se
        // contente de le lire, sans effet de bord pendant la construction.
        final profile = _profile;

        return Scaffold(
          body: SafeArea(
            child: AbsorbPointer(
              absorbing: isSubmitting,
              child: Column(
                children: [
                  AppStepHeader(
                    title: _stepTitles[_currentStep],
                    onBack: widget.isOnboarding && _isFirstStep ? null : _back,
                    currentStep: _currentStep,
                    totalSteps: _stepTitles.length,
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _buildStep(profile),
                    ),
                  ),

                  AppBottomActionBar(
                    primaryLabel: _isLastStep
                        ? (widget.isOnboarding
                              ? 'Envoyer mon dossier'
                              : 'Enregistrer')
                        : 'Suivant',
                    onPrimary: _next,
                    primaryIcon: _isLastStep
                        ? LucideIcons.check
                        : LucideIcons.arrowRight,
                    secondaryLabel: _isFirstStep ? null : 'Retour',
                    onSecondary: _isFirstStep ? null : _back,
                    secondaryIcon: LucideIcons.chevronLeft,
                    isLoading: isSubmitting,
                    footer: widget.isOnboarding
                        ? AppButton(
                            label: 'Plus tard',
                            variant: AppButtonVariant.ghost,
                            onPressed: isSubmitting ? null : _continue,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep(OwnerProfileModel? profile) {
    return switch (_currentStep) {
      0 => StepPersonalInfoWidget(
        formKey: _personalFormKey,
        nameController: _nameController,
        phoneController: _phoneController,
        addressController: _addressController,
        cityController: _cityController,
        communeController: _communeController,
        city: _city,
        onCityChanged: (value) => setState(() => _city = value),
        country: _country,
        onCountryChanged: (value) => setState(() {
          _country = value;
          // Le pays change : ville et commune de l'ancien pays n'ont plus
          // cours. `AppCityField` vide son contrôleur de son côté, mais
          // l'état local doit suivre pour que la commune se remette à jour.
          _city = '';
        }),
        profile: profile,
        showIntro: widget.isOnboarding,
      ),
      1 => StepIdentityDocumentWidget(
        formKey: _documentFormKey,
        idNumberController: _idNumberController,
        documentType: _documentType,
        onDocumentTypeChanged: (v) => setState(() => _documentType = v),
        frontImagePath: _frontImagePath,
        frontRemoteUrl: _frontRemoteUrl,
        onPickFront: () => _pickImage(isFront: true),
        backImagePath: _backImagePath,
        backRemoteUrl: _backRemoteUrl,
        onPickBack: () => _pickImage(isFront: false),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/shared/widgets/app_bottom_action_bar.dart';
import 'package:resi_africa/shared/widgets/app_badge.dart';
import 'package:resi_africa/shared/widgets/app_step_header.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/router/app_router.gr.dart';
import '../../business_logic/create_property_cubit.dart';
import '../../business_logic/create_property_state.dart';
import '../../business_logic/edit_property_cubit.dart';
import '../../business_logic/edit_property_state.dart';
import '../../data/models/property_model.dart';
import '../widgets/add_property/steps/step_amenities_widget.dart';
import '../widgets/add_property/steps/step_details_widget.dart';
import '../widgets/add_property/steps/step_identification_widget.dart';
import '../widgets/add_property/steps/step_images_widget.dart';
import '../widgets/add_property/steps/step_location_widget.dart';
import '../widgets/add_property/steps/step_pricing_widget.dart';
import '../widgets/add_property/steps/step_type_widget.dart';

/// Assistant de dépôt d'une annonce, et de modification d'une annonce déposée.
///
/// Un seul écran pour les deux parcours : les sept étapes et leurs règles de
/// validation sont identiques, et les dupliquer les laisserait diverger — un
/// champ durci à la création resterait permissif à la modification.
@RoutePage()
class AddPropertyScreen extends StatelessWidget {
  const AddPropertyScreen({super.key, this.property});

  /// Annonce à modifier. `null` pour un dépôt.
  final PropertyModel? property;

  @override
  Widget build(BuildContext context) {
    final existing = property;

    if (existing == null) {
      return BlocProvider(
        create: (_) => sl<CreatePropertyCubit>(),
        child: const AddPropertyView(),
      );
    }

    return BlocProvider(
      create: (_) => sl<EditPropertyCubit>(),
      child: AddPropertyView(property: existing),
    );
  }
}

/// Corps de l'assistant, le cubit déjà fourni au-dessus.
///
/// Exposé pour que les tests montent le formulaire avec leur propre cubit,
/// sans passer par le service locator ni le réseau.
@visibleForTesting
class AddPropertyView extends StatefulWidget {
  const AddPropertyView({super.key, this.property});

  final PropertyModel? property;

  @override
  State<AddPropertyView> createState() => _AddPropertyViewState();
}

class _AddPropertyViewState extends State<AddPropertyView> {
  /// Étape affichée, ou [_summaryStep] pour le sommaire.
  ///
  /// La création démarre sur la première étape — il n'y a rien à survoler
  /// d'un dossier vide ; la modification démarre sur le sommaire, où l'on
  /// vient corriger une section précise plutôt que tout reparcourir.
  late int _currentStep = _isEditing ? _summaryStep : 0;

  /// Écran de sommaire, hors de la numérotation des étapes.
  static const int _summaryStep = -1;

  /// Sections retouchées mais pas encore envoyées.
  ///
  /// Sert au repère visuel de la grille : sans lui, rien ne distingue une
  /// section déjà corrigée d'une section intacte, et il faudrait les rouvrir
  /// une à une pour s'en assurer.
  final Set<int> _touched = {};

  bool get _isSummary => _currentStep == _summaryStep;

  /// La sortie est actée : enregistrement réussi, ou abandon confirmé.
  ///
  /// Nécessaire en plus de [_touched] : `canPop` est lu par le `Navigator` au
  /// moment même de la demande de fermeture, alors qu'un `setState` ne prend
  /// effet qu'au frame suivant. Vider [_touched] juste avant `maybePop` laissait
  /// donc le garde encore armé, la fermeture était refusée, et l'écran restait
  /// là — loader éteint, sans issue.
  bool _leaving = false;

  bool get _hasPendingChanges => _touched.isNotEmpty;

  /// Le garde ne s'oppose plus à la fermeture quand celle-ci est déjà arbitrée.
  bool get _blocksPop => _hasPendingChanges && !_leaving;

  /// Annonce d'origine en modification, `null` en création.
  ///
  /// Sert de référence au calcul des écarts : seuls les champs réellement
  /// changés sont transmis.
  PropertyModel? get _original => widget.property;

  bool get _isEditing => _original != null;

  /// Clés de traduction, traduites à l'affichage.
  static const _stepTitles = [
    'property_form.step_type',
    'property_form.step_identification',
    'property_form.step_location',
    'property_form.step_details',
    'property_form.step_amenities',
    'property_form.step_photos',
    'property_form.step_pricing',
  ];

  /// Une icône par section, dans l'ordre de [_stepTitles].
  static const _stepIcons = [
    LucideIcons.house,
    LucideIcons.pencil,
    LucideIcons.mapPin,
    LucideIcons.ruler,
    LucideIcons.listChecks,
    LucideIcons.images,
    LucideIcons.banknote,
  ];

  // ── Étape 1 : type
  PropertyType? _propertyType;

  // ── Étape 2 : identification
  String _title = '';
  String _description = '';

  // ── Étape 3 : localisation
  String _street = '';
  String _city = '';
  double? _latitude;
  double? _longitude;

  // ── Étape 4 : caractéristiques
  double? _surfaceArea;
  int _bedrooms = 1;
  int _bathrooms = 1;
  int _livingRooms = 1;
  int _kitchens = 1;
  int _parkingSpaces = 0;

  // ── Étape 5 : commodités
  Set<Amenity> _amenities = {};

  // ── Étape 6 : photos
  List<String> _images = [];

  // ── Étape 7 : tarification
  double _dailyPrice = 0;
  List<PriceTier> _priceTiers = const [];

  @override
  void initState() {
    super.initState();

    final property = _original;
    if (property == null) return;

    // En modification, l'état part de la fiche enregistrée : chaque étape
    // s'ouvre déjà remplie, et ce qui n'est pas retouché reste identique.
    _propertyType = property.propertyType;
    _title = property.title;
    _description = property.description;
    _street = property.address.street;
    _city = property.address.city;
    _latitude = property.address.latitude;
    _longitude = property.address.longitude;
    _surfaceArea = property.details.surfaceArea;
    _bedrooms = property.details.bedrooms;
    _bathrooms = property.details.bathrooms;
    _livingRooms = property.details.livingRooms;
    _kitchens = property.details.kitchens;
    _parkingSpaces = property.details.parkingSpaces;
    _amenities = {...property.amenities};
    // Copie modifiable : l'étape Photos réordonne et retire en place.
    _images = [...property.images];
    _dailyPrice = property.pricing.dailyPrice;
    _priceTiers = [...property.pricing.priceTiers];
  }

  bool get _isLastStep => _currentStep == _stepTitles.length - 1;
  bool get _isFirstStep => _currentStep == 0;

  /// Le bouton secondaire n'a rien à proposer : sur le sommaire, l'en-tête
  /// porte déjà la sortie ; à la première étape d'un dépôt, il n'y a pas
  /// d'étape précédente.
  bool get _hidesSecondaryAction => _isSummary || (_isFirstStep && !_isEditing);

  String? _validateCurrentStep() => _validateStep(_currentStep);

  /// Première section qui ne tient pas ses règles, ou `null` si tout est bon.
  int? _firstInvalidStep() {
    for (var step = 0; step < _stepTitles.length; step++) {
      if (_validateStep(step) != null) return step;
    }
    return null;
  }

  /// Message bloquant pour [step], ou `null` si la section est complète.
  ///
  /// Les règles reprennent celles du validateur serveur : mieux vaut un refus
  /// immédiat et situé qu'une erreur 422 après huit étapes.
  String? _validateStep(int step) {
    return switch (step) {
      0 when _propertyType == null => 'property_form.choose_type'.tr(),
      1 when _title.trim().length < 3 => 'property_form.name_too_short'.tr(),
      1 when _description.trim().length < 10 =>
        'property_form.description_too_short'.tr(),
      2 when _street.trim().length < 2 =>
        'property_form.address_required'.tr(),
      2 when _city.trim().length < 2 => 'property_form.city_required'.tr(),
      // La surface est facultative ; renseignée, elle doit rester plausible.
      3 when _surfaceArea != null && _surfaceArea! <= 0 =>
        'property_form.surface_positive'.tr(),
      6 when _dailyPrice <= 0 => 'property_form.price_required'.tr(),
      _ => null,
    };
  }

  void _next() {
    if (_isSummary) {
      // Les sections s'ouvrent librement : une fiche peut arriver ici avec une
      // règle non tenue sans qu'aucune étape n'ait été traversée. On vérifie
      // l'ensemble, et on ouvre la section fautive plutôt que d'essuyer un 422
      // qui ne dirait pas où corriger.
      final invalid = _firstInvalidStep();
      if (invalid != null) {
        setState(() => _currentStep = invalid);
        _showMessage(_validateCurrentStep()!);
        return;
      }
      _submit();
      return;
    }

    final error = _validateCurrentStep();
    if (error != null) {
      _showMessage(error);
      return;
    }

    // En modification, valider une section rend la main au sommaire : on est
    // venu corriger un point précis, pas dérouler les six suivants.
    if (_isEditing) {
      setState(() {
        _touched.add(_currentStep);
        _currentStep = _summaryStep;
      });
      return;
    }

    if (_isLastStep) {
      _submit();
      return;
    }
    setState(() => _currentStep++);
  }

  Future<void> _back() async {
    if (_isSummary) {
      if (!await _confirmDiscard() || !mounted) return;

      await _leave();
      return;
    }

    // Quitter une section sans la valider abandonne ce qu'on vient d'y taper :
    // le retour au sommaire passe donc par la même confirmation que la sortie.
    if (_isEditing) {
      setState(() => _currentStep = _summaryStep);
      return;
    }

    if (_isFirstStep) {
      context.router.maybePop();
      return;
    }
    setState(() => _currentStep--);
  }

  /// Ouvre une section depuis le sommaire.
  void _openStep(int step) => setState(() => _currentStep = step);

  /// État de la section, tel qu'il s'affiche sous son titre dans la grille.
  ///
  /// Donne la valeur qui identifie la section d'un coup d'œil, pour repérer
  /// celle à corriger sans avoir à toutes les ouvrir.
  String _stepSummary(int step) {
    return switch (step) {
      0 => _propertyType?.label ?? 'property_form.not_set'.tr(),
      1 =>
        _title.trim().isEmpty ? 'property_form.untitled'.tr() : _title.trim(),
      2 => switch ([
        _city.trim(),
        _street.trim(),
      ].where((p) => p.isNotEmpty).join(' · ')) {
        '' => 'property_form.not_set_f'.tr(),
        final location => location,
      },
      3 => _detailsSummary(),
      4 => switch (_amenities.length) {
        0 => 'property_form.amenities_none'.tr(),
        final count => 'property_form.amenities_count'.plural(count),
      },
      5 => switch (_images.length) {
        0 => 'property_form.photos_none'.tr(),
        final count => 'property_form.photos_count'.plural(count),
      },
      6 => _pricingSummary(),
      _ => '',
    };
  }

  /// « 4 ch · 2 sdb · 180 m² » — seules les valeurs renseignées apparaissent.
  String _detailsSummary() {
    final parts = [
      'property_form.bedrooms_short'.tr(args: ['$_bedrooms']),
      'property_form.bathrooms_short'.tr(args: ['$_bathrooms']),
      if (_surfaceArea != null && _surfaceArea! > 0)
        '${_surfaceArea!.toInt()} m²',
    ];
    return parts.join(' · ');
  }

  String _pricingSummary() {
    if (_dailyPrice <= 0) return 'property_form.price_to_define'.tr();

    final price = CurrencyFormatter.fcfa(_dailyPrice.round());
    if (_priceTiers.isEmpty) {
      return 'property_form.price_per_day'.tr(args: [price]);
    }
    return 'property_form.price_with_tiers'.plural(
      _priceTiers.length,
      namedArgs: {'price': price, 'count': '${_priceTiers.length}'},
    );
  }

  /// Ferme l'assistant, en rendant [result] à l'écran appelant.
  ///
  /// Désarme le garde de [PopScope] avant de demander la fermeture : `canPop`
  /// est lu par le `Navigator` au moment de la demande, quand un `setState`
  /// n'aurait pris effet qu'au frame suivant.
  ///
  /// Le `setState` puis l'attente du frame ne sont pas une précaution de
  /// style : `PopScope.canPop` n'est relu qu'à la reconstruction du widget.
  /// Basculer [_leaving] sans reconstruire laissait le `Navigator` sur la
  /// valeur du frame précédent — il refusait la fermeture, ouvrait la
  /// confirmation d'abandon, et l'écran restait là, son loader éteint.
  ///
  /// L'appelant garantit par ailleurs que plus aucune route n'est empilée
  /// par-dessus l'assistant : `Navigator.maybePop` agit sur le sommet de la
  /// pile, et une confirmation encore présente absorberait la fermeture.
  Future<void> _leave([PropertyModel? result]) async {
    setState(() => _leaving = true);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    await context.router.maybePop(result);
  }

  /// Demande confirmation avant de perdre des sections déjà retouchées.
  ///
  /// Le regroupement des modifications a ce revers : tant qu'on n'a pas
  /// enregistré, tout le travail tient dans l'écran et disparaîtrait sans un
  /// mot.
  /// Rend la main une fois le dialog **sorti de la pile**, et non dès le choix :
  /// l'appelant enchaîne sur une fermeture d'écran, et `Navigator.maybePop`
  /// viserait la confirmation encore en cours d'animation plutôt que
  /// l'assistant.
  Future<bool> _confirmDiscard() async {
    if (!_hasPendingChanges) return true;

    // Résolu au retrait effectif de la route du dialog, une fois son animation
    // de sortie terminée.
    late final Future<void> dismissed;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        dismissed = ModalRoute.of(dialogContext)!.completed;
        return AlertDialog(
          title: Text('property_form.discard_title'.tr()),
          content: Text(
            _touched.length == 1
                ? 'property_form.discard_one'.tr()
                : 'property_form.discard_many'.tr(
                    args: ['${_touched.length}'],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('property_form.keep_editing'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: context.tokens.danger,
              ),
              child: Text('property_form.discard'.tr()),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return false;

    await dismissed;
    return mounted;
  }

  // ── Saisie composée, partagée par les deux parcours

  PropertyAddress get _address => PropertyAddress(
    street: _street.trim(),
    city: _city.trim(),
    // L'adresse enregistrée porte un pays et un code postal que le formulaire
    // ne présente pas : les reprendre évite qu'un enregistrement les efface.
    country: _original?.address.country,
    postalCode: _original?.address.postalCode,
    latitude: _latitude,
    longitude: _longitude,
  );

  PropertyDetails get _details => PropertyDetails(
    surfaceArea: _surfaceArea,
    bedrooms: _bedrooms,
    bathrooms: _bathrooms,
    livingRooms: _livingRooms,
    kitchens: _kitchens,
    parkingSpaces: _parkingSpaces,
    // Mêmes raisons que pour l'adresse : ces trois champs existent côté API
    // mais n'ont pas d'étape dédiée.
    floorNumber: _original?.details.floorNumber,
    totalFloors: _original?.details.totalFloors,
    yearBuilt: _original?.details.yearBuilt,
  );

  PropertyPricing get _pricing => PropertyPricing(
    dailyPrice: _dailyPrice,
    priceTiers: _priceTiers,
    minimumStayDays: _original?.pricing.minimumStayDays,
    maximumStayDays: _original?.pricing.maximumStayDays,
  );

  void _submit() {
    final original = _original;
    if (original != null) {
      context.read<EditPropertyCubit>().submit(
        original: original,
        title: _title.trim(),
        description: _description.trim(),
        propertyType: _propertyType!,
        address: _address,
        details: _details,
        amenities: _amenities,
        images: _images,
        pricing: _pricing,
      );
      return;
    }

    context.read<CreatePropertyCubit>().submit(
      title: _title.trim(),
      description: _description.trim(),
      propertyType: _propertyType!,
      address: _address,
      details: _details,
      amenities: _amenities,
      imagePaths: _images,
      pricing: _pricing,
      // `available_from` reste exigé par l'API. L'étape « Conditions » ayant
      // disparu, le bien est réputé disponible dès son dépôt.
      availableFrom: DateTime.now(),
    );
  }

  void _showMessage(String message) {
    AppToast.error(message, context: context);
  }

  @override
  Widget build(BuildContext context) {
    return _isEditing ? _buildEditing() : _buildCreating();
  }

  Widget _buildCreating() {
    return BlocConsumer<CreatePropertyCubit, CreatePropertyState>(
      listener: (context, state) {
        switch (state) {
          case CreatePropertySuccess():
            // Le routeur est résolu ici, et non dans les rappels : `replace`
            // désactive l'élément de cet écran, si bien qu'un `context.router`
            // évalué plus tard remonterait un ancêtre détruit.
            final router = context.router;

            // `replace` : l'assistant disparaît de la pile, si bien que la
            // fermeture de l'écran de succès rend la main à la liste, qui se
            // recharge alors et fait apparaître l'annonce.
            router.replace(
              SuccessRoute(
                // Sans action explicite, la redirection automatique au bout
                // du décompte n'aurait rien déclenché.
                onPrimaryAction: router.maybePop,
                // Un nouvel assistant, vierge, à la place de l'écran de
                // succès : la pile ne s'allonge pas d'un dépôt à l'autre.
                onSecondaryAction: () => router.replace(AddPropertyRoute()),
              ),
            );
          case CreatePropertyFailure(:final message):
            _showMessage(message);
          default:
            break;
        }
      },
      builder: (context, state) => _scaffold(
        isBusy:
            state is CreatePropertyUploadingImages ||
            state is CreatePropertySubmitting,
        primaryLabel: switch (state) {
          CreatePropertyUploadingImages() =>
            'property_form.uploading_photos'.tr(),
          CreatePropertySubmitting() => 'property_form.saving'.tr(),
          _ =>
            _isLastStep
                ? 'property_form.save_property'.tr()
                : 'owner_profile.next'.tr(),
        },
      ),
    );
  }

  Widget _buildEditing() {
    return BlocConsumer<EditPropertyCubit, EditPropertyState>(
      listener: (context, state) {
        switch (state) {
          case EditPropertySuccess(:final property, :final unchanged):
            // Pas d'écran de succès ici, contrairement au dépôt : la fiche
            // modifiée est déjà derrière, et la renvoyer permet au détail de
            // s'actualiser sans relire l'API.
            _leave(property);
            AppToast.success(
              unchanged
                  ? 'property_form.no_changes'.tr()
                  : 'property_form.changes_saved'.tr(),
              context: context,
            );
          case EditPropertyFailure(:final message):
            _showMessage(message);
          default:
            break;
        }
      },
      builder: (context, state) => _scaffold(
        isBusy:
            state is EditPropertyUploadingImages ||
            state is EditPropertySubmitting,
        primaryLabel: switch (state) {
          EditPropertyUploadingImages() =>
            'property_form.uploading_photos'.tr(),
          EditPropertySubmitting() => 'property_form.saving'.tr(),
          // Depuis une section, l'action valide la section et ramène au
          // sommaire — elle n'enregistre pas encore.
          _ when !_isSummary => 'property_form.validate_section'.tr(),
          _ => 'property_form.save_changes'.tr(),
        },
      ),
    );
  }

  Widget _scaffold({required bool isBusy, required String primaryLabel}) {
    return PopScope(
      // Le geste de retour système contourne la barre d'action : sans ce
      // garde, il emporterait les sections modifiées sans un mot.
      canPop: !_blocksPop,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!await _confirmDiscard() || !mounted) return;

        await _leave();
      },
      child: Scaffold(
        body: SafeArea(
          child: AbsorbPointer(
            absorbing: isBusy,
            child: Column(
              children: [
                AppStepHeader(
                  title: _isSummary
                      ? 'property_form.edit_title'.tr()
                      : _stepTitles[_currentStep].tr(),
                  onBack: _back,
                  // Pas de progression sur le sommaire : les sections s'y
                  // abordent dans l'ordre qu'on veut, il n'y a pas de « 3/7 ».
                  currentStep: _isSummary ? null : _currentStep,
                  totalSteps: _isSummary ? null : _stepTitles.length,
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _isSummary ? _buildSummary() : _buildStep(),
                  ),
                ),

                AppBottomActionBar(
                  primaryLabel: primaryLabel,
                  onPrimary: _next,
                  // En modification, chaque section se conclut par une
                  // validation, jamais par un « suivant » : il n'y a pas de
                  // section d'après.
                  primaryIcon: _isSummary || _isEditing || _isLastStep
                      ? LucideIcons.check
                      : LucideIcons.arrowRight,
                  // Sur le sommaire, la flèche de l'en-tête suffit à sortir :
                  // un second bouton « Retour » au même endroit que
                  // « Enregistrer » invite à l'appui malheureux.
                  secondaryLabel: _hidesSecondaryAction
                      ? null
                      : 'common.back'.tr(),
                  onSecondary: _hidesSecondaryAction ? null : _back,
                  secondaryIcon: LucideIcons.chevronLeft,
                  isLoading: isBusy,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Sommaire des sections, en grille.
  Widget _buildSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'property_form.what_to_edit'.tr(),
          style: context.text.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          _hasPendingChanges
              ? 'property_form.save_to_apply'.tr()
              : 'property_form.tap_section'.tr(),
          style: context.text.bodySmall!.copyWith(
            color: _hasPendingChanges
                ? context.tokens.accentAmber
                : context.tokens.muted,
          ),
        ),
        const SizedBox(height: 16),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            // Les tuiles portent trois lignes de texte : plus hautes que
            // larges, sinon le résumé serait tronqué.
            childAspectRatio: 1.15,
          ),
          itemCount: _stepTitles.length,
          itemBuilder: (_, index) => _SummaryTile(
            icon: _stepIcons[index],
            title: _stepTitles[index].tr(),
            summary: _stepSummary(index),
            isTouched: _touched.contains(index),
            onTap: () => _openStep(index),
          ),
        ),
      ],
    );
  }

  Widget _buildStep() {
    return switch (_currentStep) {
      0 => StepTypeWidget(
        selected: _propertyType,
        onSelected: (v) => setState(() => _propertyType = v),
      ),
      1 => StepIdentificationWidget(
        title: _title,
        description: _description,
        onTitleChanged: (v) => _title = v,
        onDescriptionChanged: (v) => _description = v,
      ),
      2 => StepLocationWidget(
        street: _street,
        city: _city,
        onStreetChanged: (v) => _street = v,
        onCityChanged: (v) => _city = v,
        onCoordinatesChanged: (lat, lng) {
          _latitude = lat;
          _longitude = lng;
        },
      ),
      3 => StepDetailsWidget(
        surfaceArea: _surfaceArea,
        bedrooms: _bedrooms,
        bathrooms: _bathrooms,
        livingRooms: _livingRooms,
        kitchens: _kitchens,
        parkingSpaces: _parkingSpaces,
        onSurfaceChanged: (v) => _surfaceArea = v,
        onBedroomsChanged: (v) => setState(() => _bedrooms = v),
        onBathroomsChanged: (v) => setState(() => _bathrooms = v),
        onLivingRoomsChanged: (v) => setState(() => _livingRooms = v),
        onKitchensChanged: (v) => setState(() => _kitchens = v),
        onParkingChanged: (v) => setState(() => _parkingSpaces = v),
      ),
      4 => StepAmenitiesWidget(
        selected: _amenities,
        onChanged: (v) => setState(() => _amenities = v),
      ),
      5 => StepImagesWidget(
        images: _images,
        onChanged: (v) => setState(() => _images = v),
      ),
      6 => StepPricingWidget(
        dailyPrice: _dailyPrice,
        priceTiers: _priceTiers,
        onDailyChanged: (v) => _dailyPrice = v,
        onTiersChanged: (v) => setState(() => _priceTiers = v),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

/// Tuile du sommaire : une section du formulaire et son état courant.
class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.title,
    required this.summary,
    required this.isTouched,
    required this.onTap,
  });

  final IconData icon;
  final String title;

  /// Valeur actuelle de la section, résumée en une ligne.
  final String summary;

  /// Section retouchée, en attente d'enregistrement.
  final bool isTouched;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // Section retouchée : filet ambre, la couleur de ce qui attend une action
    // — ici, l'enregistrement.
    return Material(
      color: t.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.md,
        side: BorderSide(color: isTouched ? t.accentAmber : t.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconChip(
                    icon: icon,
                    accent: isTouched ? AppAccent.amber : AppAccent.neutral,
                    size: 32,
                  ),
                  const Spacer(),
                  if (isTouched)
                    AppBadge(
                      label: 'property_form.modified'.tr(),
                      tone: AppAccent.amber,
                    )
                  else
                    Icon(LucideIcons.chevronRight, size: 16, color: t.muted),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleSmall!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

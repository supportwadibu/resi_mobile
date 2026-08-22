import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/shared/widgets/app_bottom_action_bar.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_step_header.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/router/app_router.gr.dart';
import '../../../../core/theme/app_colors.dart';
import '../../business_logic/create_property_cubit.dart';
import '../../business_logic/create_property_state.dart';
import '../../data/models/property_model.dart';
import '../widgets/add_property/steps/step_amenities_widget.dart';
import '../widgets/add_property/steps/step_details_widget.dart';
import '../widgets/add_property/steps/step_identification_widget.dart';
import '../widgets/add_property/steps/step_images_widget.dart';
import '../widgets/add_property/steps/step_location_widget.dart';
import '../widgets/add_property/steps/step_pricing_widget.dart';
import '../widgets/add_property/steps/step_type_widget.dart';

@RoutePage()
class AddPropertyScreen extends StatelessWidget {
  const AddPropertyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CreatePropertyCubit>(),
      child: const _AddPropertyView(),
    );
  }
}

class _AddPropertyView extends StatefulWidget {
  const _AddPropertyView();

  @override
  State<_AddPropertyView> createState() => _AddPropertyViewState();
}

class _AddPropertyViewState extends State<_AddPropertyView> {
  int _currentStep = 0;

  static const _stepTitles = [
    'Type de bien',
    'Identification',
    'Localisation',
    'Caractéristiques',
    'Commodités',
    'Photos',
    'Tarification',
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
  Furnishing? _furnishing;

  // ── Étape 5 : commodités
  Set<Amenity> _amenities = {};

  // ── Étape 6 : photos
  List<String> _images = [];

  // ── Étape 7 : tarification
  double _dailyPrice = 0;
  List<PriceTier> _priceTiers = const [];

  bool get _isLastStep => _currentStep == _stepTitles.length - 1;
  bool get _isFirstStep => _currentStep == 0;

  /// Message bloquant pour l'étape courante, ou `null` si elle est complète.
  ///
  /// Les règles reprennent celles du validateur serveur : mieux vaut un refus
  /// immédiat et situé qu'une erreur 422 après huit étapes.
  String? _validateCurrentStep() {
    return switch (_currentStep) {
      0 when _propertyType == null => 'Choisissez un type de bien.',
      1 when _title.trim().length < 3 =>
        'Le nom du bien doit faire au moins 3 caractères.',
      1 when _description.trim().length < 10 =>
        'La description doit faire au moins 10 caractères.',
      2 when _street.trim().length < 2 => 'Renseignez l’adresse du bien.',
      2 when _city.trim().length < 2 => 'Renseignez la ville.',
      // La surface est facultative ; renseignée, elle doit rester plausible.
      3 when _surfaceArea != null && _surfaceArea! <= 0 =>
        'La surface doit être supérieure à zéro.',
      6 when _dailyPrice <= 0 => 'Indiquez le tarif par jour.',
      _ => null,
    };
  }

  void _next() {
    final error = _validateCurrentStep();
    if (error != null) {
      _showMessage(error);
      return;
    }

    if (_isLastStep) {
      _submit();
      return;
    }
    setState(() => _currentStep++);
  }

  void _back() {
    if (_isFirstStep) {
      context.router.maybePop();
      return;
    }
    setState(() => _currentStep--);
  }

  void _submit() {
    context.read<CreatePropertyCubit>().submit(
      title: _title.trim(),
      description: _description.trim(),
      propertyType: _propertyType!,
      address: PropertyAddress(
        street: _street.trim(),
        city: _city.trim(),
        latitude: _latitude,
        longitude: _longitude,
      ),
      details: PropertyDetails(
        surfaceArea: _surfaceArea,
        bedrooms: _bedrooms,
        bathrooms: _bathrooms,
        livingRooms: _livingRooms,
        kitchens: _kitchens,
        parkingSpaces: _parkingSpaces,
        furnishing: _furnishing,
      ),
      amenities: _amenities,
      imagePaths: _images,
      pricing: PropertyPricing(
        dailyPrice: _dailyPrice,
        priceTiers: _priceTiers,
      ),
      // `available_from` reste exigé par l'API. L'étape « Conditions » ayant
      // disparu, le bien est réputé disponible dès son dépôt.
      availableFrom: DateTime.now(),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
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
                onSecondaryAction: () =>
                    router.replace(const AddPropertyRoute()),
              ),
            );
          case CreatePropertyFailure(:final message):
            _showMessage(message);
          default:
            break;
        }
      },
      builder: (context, state) {
        final isBusy =
            state is CreatePropertyUploadingImages ||
            state is CreatePropertySubmitting;

        return Scaffold(
          backgroundColor: AppColors.white,
          body: SafeArea(
            child: AbsorbPointer(
              absorbing: isBusy,
              child: Column(
                children: [
                  AppStepHeader(
                    title: _stepTitles[_currentStep],
                    onBack: _back,
                    currentStep: _currentStep,
                    totalSteps: _stepTitles.length,
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      child: _buildStep(),
                    ),
                  ),

                  AppBottomActionBar(
                    primaryLabel: _primaryLabel(state),
                    onPrimary: _next,
                    primaryIcon: AppButtonIcon.material(
                      _isLastStep
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    secondaryLabel: _isFirstStep ? null : 'Retour',
                    onSecondary: _isFirstStep ? null : _back,
                    secondaryIcon: AppButtonIcon.material(
                      Icons.arrow_back_rounded,
                    ),
                    isLoading: isBusy,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _primaryLabel(CreatePropertyState state) {
    if (state is CreatePropertyUploadingImages) {
      return 'Envoi des photos...';
    }
    if (state is CreatePropertySubmitting) return 'Enregistrement...';
    return _isLastStep ? 'Enregistrer le bien' : 'Suivant';
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
        furnishing: _furnishing,
        onSurfaceChanged: (v) => _surfaceArea = v,
        onBedroomsChanged: (v) => setState(() => _bedrooms = v),
        onBathroomsChanged: (v) => setState(() => _bathrooms = v),
        onLivingRoomsChanged: (v) => setState(() => _livingRooms = v),
        onKitchensChanged: (v) => setState(() => _kitchens = v),
        onParkingChanged: (v) => setState(() => _parkingSpaces = v),
        onFurnishingChanged: (v) => setState(() => _furnishing = v),
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

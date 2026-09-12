import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../business_logic/residence_cubit.dart';
import '../../business_logic/residence_state.dart';
import '../../data/models/residence_model.dart';
import '../../data/repositories/residence_repository.dart';

/// Saisie d'une résidence — création, ou modification si [residenceId] est
/// fourni.
///
/// La fiche est relue au serveur plutôt que passée en argument : l'écran est
/// atteignable depuis plusieurs endroits, et transporter le modèle obligerait
/// chaque appelant à le détenir déjà.
@RoutePage()
class AddResidenceScreen extends StatelessWidget {
  const AddResidenceScreen({super.key, @QueryParam('id') this.residenceId});

  final String? residenceId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ResidenceCubit>(),
      child: _AddResidenceView(residenceId: residenceId),
    );
  }
}

class _AddResidenceView extends StatefulWidget {
  const _AddResidenceView({this.residenceId});

  final String? residenceId;

  @override
  State<_AddResidenceView> createState() => _AddResidenceViewState();
}

class _AddResidenceViewState extends State<_AddResidenceView> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();

  final _amenities = <ResidenceAmenity>{};

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _loadError;

  ResidenceModel? _original;

  bool get _isEditing => widget.residenceId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadExisting();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoading = true);

    try {
      final residence = await sl<ResidenceRepository>().getResidence(
        widget.residenceId!,
      );
      if (!mounted) return;

      setState(() {
        _original = residence;
        _nameController.text = residence.name;
        _descriptionController.text = residence.description;
        _streetController.text = residence.address.street;
        _cityController.text = residence.address.city;
        _amenities
          ..clear()
          ..addAll(residence.amenities);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Message bloquant, ou `null` si la saisie est complète.
  ///
  /// Les règles reprennent celles du validateur serveur : mieux vaut un refus
  /// immédiat et situé qu'une erreur 422 après coup.
  String? _validate() {
    if (_nameController.text.trim().length < 2) {
      return 'Donnez un nom à la résidence.';
    }
    if (_streetController.text.trim().length < 2) {
      return 'Indiquez la rue.';
    }
    if (_cityController.text.trim().length < 2) {
      return 'Indiquez la ville.';
    }
    return null;
  }

  Future<void> _submit() async {
    final error = _validate();
    if (error != null) {
      _showMessage(error);
      return;
    }

    setState(() => _isSubmitting = true);

    final cubit = context.read<ResidenceCubit>();
    final address = ResidenceAddress(
      street: _streetController.text.trim(),
      city: _cityController.text.trim(),
    );

    final result = _isEditing
        ? await cubit.update(
            widget.residenceId!,
            UpdateResidencePayload(
              name: _nameController.text,
              description: _descriptionController.text,
              address: address,
              amenities: _amenities,
            ),
          )
        : await cubit.create(
            CreateResidencePayload(
              name: _nameController.text,
              address: address,
              description: _descriptionController.text,
              amenities: _amenities,
            ),
          );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result != null) {
      context.router.maybePop();
      return;
    }

    // `null` sans changement à envoyer n'est pas un échec : le patch était vide.
    if (_isEditing && _hasNoChange()) {
      context.router.maybePop();
      return;
    }

    final state = cubit.state;
    _showMessage(
      state is ResidenceError ? state.message : 'Enregistrement impossible.',
    );
  }

  /// Rien n'a bougé : inutile d'appeler l'API, mais l'écran doit se fermer
  /// comme après un enregistrement réussi.
  bool _hasNoChange() {
    final original = _original;
    if (original == null) return false;

    return _nameController.text.trim() == original.name &&
        _descriptionController.text.trim() == original.description &&
        _streetController.text.trim() == original.address.street &&
        _cityController.text.trim() == original.address.city &&
        _amenities.length == original.amenities.length &&
        _amenities.containsAll(original.amenities);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier la résidence' : 'Nouvelle résidence'),
      ),
      body: switch ((_isLoading, _loadError)) {
        (true, _) => const Center(child: CircularProgressIndicator()),
        (_, final String error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(error, textAlign: TextAlign.center),
          ),
        ),
        _ => _form(),
      },
    );
  }

  Widget _form() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field(
            controller: _nameController,
            label: 'Nom de la résidence',
            hint: 'Resi Adja',
          ),
          const SizedBox(height: 16),
          _field(
            controller: _streetController,
            label: 'Rue',
            hint: 'Rue des Jardins',
          ),
          const SizedBox(height: 16),
          _field(controller: _cityController, label: 'Ville', hint: 'Abidjan'),
          const SizedBox(height: 16),
          _field(
            controller: _descriptionController,
            label: 'Description (facultatif)',
            hint: 'Trois logements à Cocody',
            maxLines: 3,
          ),

          const SizedBox(height: 24),
          const Text(
            'Parties communes',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Ce qui appartient au lieu, et non à un logement en particulier.',
            style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final amenity in ResidenceAmenity.values)
                FilterChip(
                  label: Text(amenity.label),
                  selected: _amenities.contains(amenity),
                  onSelected: (selected) => setState(() {
                    if (selected) {
                      _amenities.add(amenity);
                    } else {
                      _amenities.remove(amenity);
                    }
                  }),
                ),
            ],
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Enregistrer' : 'Créer la résidence'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
